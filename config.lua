Config = {}

Config.CallCooldown = 300
Config.MaxCallRadius = 5000
Config.MaxActiveCalls = 50
Config.AutoRemoveCallTime = 1800

Config.Permissions = {
    Police = {
        "police",
        "sheriff",
        "state",
        "admin"
    },
    EMS = {
        "ems",
        "paramedic",
        "doctor",
        "admin"
    },
    Fire = {
        "fire",
        "firefighter",
        "admin"
    },
    Admin = {
        "admin",
        "moderator",
        "staff"
    }
}

Config.CallTypes = {
    police = {
        name = "Police",
        blipColor = 3,
        blipSprite = 60,
        sound = "TIMER_STOP",
        priority = 2
    },
    ems = {
        name = "EMS",
        blipColor = 1,
        blipSprite = 61,
        sound = "CHECKPOINT_PERFECT",
        priority = 3
    },
    fire = {
        name = "Fire",
        blipColor = 17,
        blipSprite = 436,
        sound = "RACE_PLACED",
        priority = 3
    },
    civilian = {
        name = "Civilian",
        blipColor = 2,
        blipSprite = 280,
        sound = "WAYPOINT_SET",
        priority = 1
    }
}

Config.PriorityLevels = {
    [1] = {name = "Low", color = "~g~", multiplier = 1.0},
    [2] = {name = "Medium", color = "~y~", multiplier = 1.5},
    [3] = {name = "High", color = "~r~", multiplier = 2.0}
}

Config.Features = {
    EnableBlips = true,
    EnableNotifications = true,
    EnableSounds = true,
    EnableLogging = true,
    EnableDistanceFilter = true,
    EnableETACalculation = true,
    EnableVoiceAlerts = true,
    EnableAntiSpam = true
}

Config.UI = {
    NotificationTime = 8000,
    BlipScale = 1.0,
    BlipAlpha = 255,
    ShowCallerName = true,
    ShowDistance = true,
    ShowETA = true
}

Config.Sounds = {
    NewCall = "TIMER_STOP",
    CallClaimed = "CHECKPOINT_PERFECT",
    CallCancelled = "WAYPOINT_SET"
}

Config.Messages = {
    CallSent = "Emergency call sent to responders",
    CallCancelled = "Emergency call cancelled",
    CallClaimed = "Call has been claimed by a responder",
    OnCooldown = "You must wait before making another emergency call",
    NoActiveCalls = "No active emergency calls",
    InvalidCallID = "Invalid call ID",
    NotAuthorized = "You are not authorized to use this command",
    CallNotFound = "Call not found or already resolved"
}

Config.Commands = {
    Emergency = "911",
    Cancel = "cancel911",
    Respond = "respond",
    ClearCall = "clearcall"
}