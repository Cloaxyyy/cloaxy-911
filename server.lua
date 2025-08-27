local activeCalls = {}
local playerCooldowns = {}
local callIdCounter = 1
local claimedCalls = {}

local function hasPermission(source, role)
    if not Config.Permissions[role] then return false end
    
    for _, permission in ipairs(Config.Permissions[role]) do
        if IsPlayerAceAllowed(source, "911." .. permission) then
            return true
        end
    end
    
    return false
end

local function isResponder(source)
    for role, permissions in pairs(Config.Permissions) do
        if role ~= "Admin" then
            for _, permission in ipairs(permissions) do
                if IsPlayerAceAllowed(source, "911." .. permission) then
                    return true
                end
            end
        end
    end
    
    return hasPermission(source, "Admin")
end

local function getPlayerCoords(source)
    local ped = GetPlayerPed(source)
    return GetEntityCoords(ped)
end

local function calculateDistance(coords1, coords2)
    return math.sqrt((coords1.x - coords2.x)^2 + (coords1.y - coords2.y)^2 + (coords1.z - coords2.z)^2)
end

local function calculateETA(distance)
    local avgSpeed = 25.0
    return math.ceil(distance / avgSpeed)
end

local function determineCallType(reason)
    local lowerReason = string.lower(reason)
    if string.find(lowerReason, "fire") or string.find(lowerReason, "explosion") or string.find(lowerReason, "burn") then
        return "fire"
    elseif string.find(lowerReason, "medical") or string.find(lowerReason, "injured") or string.find(lowerReason, "ambulance") or string.find(lowerReason, "hurt") then
        return "ems"
    elseif string.find(lowerReason, "robbery") or string.find(lowerReason, "shooting") or string.find(lowerReason, "crime") or string.find(lowerReason, "police") then
        return "police"
    else
        return "civilian"
    end
end

local function determinePriority(reason, callType)
    local lowerReason = string.lower(reason)
    local urgentKeywords = {"shooting", "explosion", "fire", "robbery", "emergency", "urgent", "help"}
    
    for _, keyword in ipairs(urgentKeywords) do
        if string.find(lowerReason, keyword) then
            return 3
        end
    end
    
    return Config.CallTypes[callType].priority or 1
end

local function logCall(callData, action)
    if not Config.Features.EnableLogging then return end
    
    local logEntry = {
        timestamp = os.date("%Y-%m-%d %H:%M:%S"),
        action = action,
        callId = callData.id,
        callerId = callData.source,
        callerName = GetPlayerName(callData.source),
        reason = callData.reason,
        callType = callData.callType,
        priority = callData.priority,
        coords = callData.coords,
        responder = callData.responder
    }
    
    local logFile = io.open("logs/911_calls.json", "a")
    if logFile then
        logFile:write(json.encode(logEntry) .. "\n")
        logFile:close()
    end
end

local function notifyResponders(callData)
    local players = GetPlayers()
    
    for _, playerId in ipairs(players) do
        local source = tonumber(playerId)
        if isResponder(source) then
            local responderCoords = getPlayerCoords(source)
            local distance = calculateDistance(callData.coords, responderCoords)
            
            if not Config.Features.EnableDistanceFilter or distance <= Config.MaxCallRadius then
                local eta = calculateETA(distance)
                
                TriggerClientEvent('911:newCall', source, {
                    id = callData.id,
                    reason = callData.reason,
                    coords = callData.coords,
                    callType = callData.callType,
                    priority = callData.priority,
                    callerName = callData.callerName,
                    distance = math.floor(distance),
                    eta = eta,
                    timestamp = callData.timestamp
                })
            end
        end
    end
end

local function removeCall(callId)
    if activeCalls[callId] then
        local callData = activeCalls[callId]
        activeCalls[callId] = nil
        claimedCalls[callId] = nil
        
        TriggerClientEvent('911:removeCall', -1, callId)
        logCall(callData, "removed")
    end
end

RegisterCommand(Config.Commands.Emergency, function(source, args)
    if #args == 0 then
        TriggerClientEvent('chat:addMessage', source, {
            color = {255, 0, 0},
            multiline = true,
            args = {"911 System", "Usage: /" .. Config.Commands.Emergency .. " [reason]"}
        })
        return
    end
    
    local identifier = GetPlayerIdentifiers(source)[1]
    if playerCooldowns[identifier] and (os.time() - playerCooldowns[identifier]) < Config.CallCooldown then
        local remaining = Config.CallCooldown - (os.time() - playerCooldowns[identifier])
        TriggerClientEvent('chat:addMessage', source, {
            color = {255, 0, 0},
            multiline = true,
            args = {"911 System", Config.Messages.OnCooldown .. " (" .. remaining .. "s)"}
        })
        return
    end
    
    local reason = table.concat(args, " ")
    local coords = getPlayerCoords(source)
    local callType = determineCallType(reason)
    local priority = determinePriority(reason, callType)
    
    local callData = {
        id = callIdCounter,
        source = source,
        reason = reason,
        coords = coords,
        callType = callType,
        priority = priority,
        callerName = GetPlayerName(source),
        timestamp = os.time(),
        responder = nil
    }
    
    activeCalls[callIdCounter] = callData
    playerCooldowns[identifier] = os.time()
    
    TriggerClientEvent('chat:addMessage', source, {
        color = {0, 255, 0},
        multiline = true,
        args = {"911 System", Config.Messages.CallSent}
    })
    
    notifyResponders(callData)
    logCall(callData, "created")
    
    callIdCounter = callIdCounter + 1
end)

RegisterCommand(Config.Commands.Cancel, function(source)
    local playerCalls = {}
    for id, call in pairs(activeCalls) do
        if call.source == source then
            table.insert(playerCalls, id)
        end
    end
    
    if #playerCalls == 0 then
        TriggerClientEvent('chat:addMessage', source, {
            color = {255, 0, 0},
            multiline = true,
            args = {"911 System", "You have no active emergency calls"}
        })
        return
    end
    
    for _, callId in ipairs(playerCalls) do
        removeCall(callId)
    end
    
    TriggerClientEvent('chat:addMessage', source, {
        color = {0, 255, 0},
        multiline = true,
        args = {"911 System", Config.Messages.CallCancelled}
    })
end)

RegisterCommand(Config.Commands.Respond, function(source, args)
    if not isResponder(source) then
        TriggerClientEvent('chat:addMessage', source, {
            color = {255, 0, 0},
            multiline = true,
            args = {"911 System", Config.Messages.NotAuthorized}
        })
        return
    end
    
    if #args == 0 then
        TriggerClientEvent('chat:addMessage', source, {
            color = {255, 0, 0},
            multiline = true,
            args = {"911 System", "Usage: /" .. Config.Commands.Respond .. " [call_id]"}
        })
        return
    end
    
    local callId = tonumber(args[1])
    if not callId or not activeCalls[callId] then
        TriggerClientEvent('chat:addMessage', source, {
            color = {255, 0, 0},
            multiline = true,
            args = {"911 System", Config.Messages.CallNotFound}
        })
        return
    end
    
    if claimedCalls[callId] then
        TriggerClientEvent('chat:addMessage', source, {
            color = {255, 0, 0},
            multiline = true,
            args = {"911 System", "Call already claimed by another responder"}
        })
        return
    end
    
    claimedCalls[callId] = source
    activeCalls[callId].responder = GetPlayerName(source)
    
    TriggerClientEvent('chat:addMessage', source, {
        color = {0, 255, 0},
        multiline = true,
        args = {"911 System", "You have claimed call #" .. callId}
    })
    
    TriggerClientEvent('chat:addMessage', activeCalls[callId].source, {
        color = {0, 255, 0},
        multiline = true,
        args = {"911 System", "A responder is on the way!"}
    })
    
    TriggerClientEvent('911:callClaimed', -1, callId, GetPlayerName(source))
    logCall(activeCalls[callId], "claimed")
end)



RegisterCommand(Config.Commands.ClearCall, function(source, args)
    if not hasPermission(source, "Admin") then
        TriggerClientEvent('chat:addMessage', source, {
            color = {255, 0, 0},
            multiline = true,
            args = {"911 System", Config.Messages.NotAuthorized}
        })
        return
    end
    
    if #args == 0 then
        TriggerClientEvent('chat:addMessage', source, {
            color = {255, 0, 0},
            multiline = true,
            args = {"911 System", "Usage: /" .. Config.Commands.ClearCall .. " [call_id]"}
        })
        return
    end
    
    local callId = tonumber(args[1])
    if not callId or not activeCalls[callId] then
        TriggerClientEvent('chat:addMessage', source, {
            color = {255, 0, 0},
            multiline = true,
            args = {"911 System", Config.Messages.CallNotFound}
        })
        return
    end
    
    removeCall(callId)
    
    TriggerClientEvent('chat:addMessage', source, {
        color = {0, 255, 0},
        multiline = true,
        args = {"911 System", "Call #" .. callId .. " has been cleared"}
    })
end)

RegisterNetEvent('911:updateCallerPosition')
AddEventHandler('911:updateCallerPosition', function(coords)
    local source = source
    for id, call in pairs(activeCalls) do
        if call.source == source then
            call.coords = coords
            TriggerClientEvent('911:updateCallPosition', -1, id, coords)
        end
    end
end)

CreateThread(function()
    while true do
        Wait(60000)
        local currentTime = os.time()
        
        for id, call in pairs(activeCalls) do
            if (currentTime - call.timestamp) > Config.AutoRemoveCallTime then
                removeCall(id)
            end
        end
    end
end)

AddEventHandler('playerDropped', function()
    local source = source
    for id, call in pairs(activeCalls) do
        if call.source == source then
            removeCall(id)
        end
    end
end)