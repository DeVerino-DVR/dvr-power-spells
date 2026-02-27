---@diagnostic disable: undefined-global, trailing-space
local Config <const> = {}

Config.Cyclone = {
    radius = 8.0,                   
    forceScale = 1.2,               
    topSpeed = 35.0,                
    maxEntityDist = 35.0,           
    horizontalForce = 0.8,          
    verticalForce = 0.45,           
    tangentForce = 2.5,             
    rotationSpeed = 3.5,            
    duration = 6000,
    cooldown = 9000,
    shakeDistance = 25.0,
    shakeIntensity = 0.25
}

Config.Levels = {
    [1] = { 
        radiusMult = 0.8,           
        forceMult = 0.7,            
        duration = 5000,            
        affectPlayers = true, 
        affectPeds = true, 
        affectObjects = false, 
        affectVehicles = false, 
        shakeMult = 0.4 
    },
    [2] = { 
        radiusMult = 0.9, 
        forceMult = 0.85, 
        duration = 8000,            
        affectPlayers = true, 
        affectPeds = true, 
        affectObjects = true, 
        affectVehicles = false, 
        shakeMult = 0.6 
    },
    [3] = { 
        radiusMult = 1.0, 
        forceMult = 1.0, 
        duration = 12000,           
        affectPlayers = true, 
        affectPeds = true, 
        affectObjects = true, 
        affectVehicles = false, 
        shakeMult = 0.75 
    },
    [4] = { 
        radiusMult = 1.1, 
        forceMult = 1.15, 
        duration = 18000,           
        affectPlayers = true, 
        affectPeds = true, 
        affectObjects = true, 
        affectVehicles = true, 
        shakeMult = 0.9 
    },
    [5] = { 
        radiusMult = 1.25, 
        forceMult = 1.35, 
        duration = 25000,           
        affectPlayers = true, 
        affectPeds = true, 
        affectObjects = true, 
        affectVehicles = true, 
        shakeMult = 1.0 
    }
}

Config.Module = {
    id = 'cyclone',
    name = 'Cyclone',
    description = 'Génère une tornade qui aspire et fait tournoyer les entités en spirale.',
    icon = 'wind',
    color = 'blue',
    cooldown = 9000,
    type = 'attack',
    image = 'images/power/dvr_cyclone.png',
    video = "YOUR_VIDEO_URL_HERE",
    professor = false,
    isWand = true
}

Config.Messages = {
    noWand = {
        title = 'Cyclone',
        description = 'Vous devez équiper une baguette.',
        type = 'error',
        icon = 'wind'
    }
}

Config.Debug = false

_ENV.Config = Config
