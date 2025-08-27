local activeBlips = {}
local lastPosition = nil
local positionUpdateTimer = 0

local function playSound(soundName)
    if Config.Features.EnableSounds then
        PlaySoundFrontend(-1, soundName, "HUD_FRONTEND_DEFAULT_SOUNDSET", true)
    end
end

local function showNotification(message, type)
    if Config.Features.EnableNotifications then
        SetNotificationTextEntry("STRING")
        AddTextComponentString(message)
        DrawNotification(false, false)
    end
end

local function showAdvancedNotification(title, message, icon, iconType)
    if Config.Features.EnableNotifications then
        SetNotificationTextEntry("STRING")
        AddTextComponentString(message)
        SetNotificationMessage(icon, icon, false, iconType, title, "")
        DrawNotification(false, false)
    end
end

local function createBlip(callData)
    if not Config.Features.EnableBlips then return end
    
    local blip = AddBlipForCoord(callData.coords.x, callData.coords.y, callData.coords.z)
    local callType = Config.CallTypes[callData.callType]
    
    SetBlipSprite(blip, callType.blipSprite)
    SetBlipColour(blip, callType.blipColor)
    SetBlipScale(blip, Config.UI.BlipScale)
    SetBlipAlpha(blip, Config.UI.BlipAlpha)
    SetBlipAsShortRange(blip, false)
    
    local priorityInfo = Config.PriorityLevels[callData.priority]
    local blipName = string.format("911 Call #%d - %s Priority", callData.id, priorityInfo.name)
    
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString(blipName)
    EndTextCommandSetBlipName(blip)
    
    activeBlips[callData.id] = blip
end

local function removeBlip(callId)
    if activeBlips[callId] then
        RemoveBlip(activeBlips[callId])
        activeBlips[callId] = nil
    end
end

local function updateBlipPosition(callId, coords)
    if activeBlips[callId] then
        SetBlipCoords(activeBlips[callId], coords.x, coords.y, coords.z)
    end
end

local function formatDistance(distance)
    if distance < 1000 then
        return string.format("%.0fm", distance)
    else
        return string.format("%.1fkm", distance / 1000)
    end
end

local function formatETA(eta)
    if eta < 60 then
        return string.format("%ds", eta)
    else
        return string.format("%dm %ds", math.floor(eta / 60), eta % 60)
    end
end

local function displayOnScreenText(text, duration)
    CreateThread(function()
        local startTime = GetGameTimer()
        
        while GetGameTimer() - startTime < duration do
            SetTextFont(4)
            SetTextProportional(1)
            SetTextScale(0.8, 0.8)
            SetTextColour(255, 255, 255, 255)
            SetTextDropshadow(0, 0, 0, 0, 255)
            SetTextEdge(1, 0, 0, 0, 255)
            SetTextDropShadow()
            SetTextOutline()
            SetTextEntry("STRING")
            AddTextComponentString(text)
            DrawText(0.5, 0.1)
            Wait(0)
        end
    end)
end

RegisterNetEvent('911:newCall')
AddEventHandler('911:newCall', function(callData)
    local callType = Config.CallTypes[callData.callType]
    local priorityInfo = Config.PriorityLevels[callData.priority]
    
    createBlip(callData)
    playSound(callType.sound)
    
    local notificationTitle = string.format("New %s Call", callType.name)
    local distanceText = Config.UI.ShowDistance and formatDistance(callData.distance) or ""
    local etaText = Config.UI.ShowETA and formatETA(callData.eta) or ""
    local callerText = Config.UI.ShowCallerName and callData.callerName or "Anonymous"
    
    local notificationMessage = string.format(
        "%s%s Priority\nCaller: %s\nReason: %s\nDistance: %s\nETA: %s\nCall ID: #%d",
        priorityInfo.color,
        priorityInfo.name,
        callerText,
        callData.reason,
        distanceText,
        etaText,
        callData.id
    )
    
    showAdvancedNotification(notificationTitle, notificationMessage, "CHAR_CALL911", 1)
    
    local onScreenText = string.format("New 911 Call - %s%s Priority", priorityInfo.color, priorityInfo.name)
    displayOnScreenText(onScreenText, Config.UI.NotificationTime)
end)

RegisterNetEvent('911:removeCall')
AddEventHandler('911:removeCall', function(callId)
    removeBlip(callId)
end)

RegisterNetEvent('911:updateCallPosition')
AddEventHandler('911:updateCallPosition', function(callId, coords)
    updateBlipPosition(callId, coords)
end)

RegisterNetEvent('911:callClaimed')
AddEventHandler('911:callClaimed', function(callId, responderName)
    removeBlip(callId)
    playSound(Config.Sounds.CallClaimed)
    
    local message = string.format("Call #%d claimed by %s", callId, responderName)
    showNotification(message, "success")
end)





CreateThread(function()
    while true do
        Wait(5000)
        
        local playerPed = PlayerPedId()
        local currentPos = GetEntityCoords(playerPed)
        
        if lastPosition then
            local distance = #(currentPos - lastPosition)
            if distance > 50.0 then
                TriggerServerEvent('911:updateCallerPosition', currentPos)
                lastPosition = currentPos
            end
        else
            lastPosition = currentPos
        end
    end
end)





AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        for callId, blip in pairs(activeBlips) do
            RemoveBlip(blip)
        end
    end
end)