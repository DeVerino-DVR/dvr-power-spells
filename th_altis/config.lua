---@diagnostic disable: trailing-space
local Config <const> = {}

-- Base duration in milliseconds (10 seconds)
Config.Buff = {
    baseDuration = 10000
}

-- Duration by spell level (in milliseconds)
Config.DurationByLevel = {
    [0] = 10000,  -- Level 0: 10 seconds
    [1] = 12000,  -- Level 1: 12 seconds
    [2] = 15000,  -- Level 2: 15 seconds
    [3] = 18000,  -- Level 3: 18 seconds
    [4] = 22000,  -- Level 4: 22 seconds
    [5] = 25000   -- Level 5: 25 seconds
}

Config.Raycast = {
    maxDistance = 90.0
}

Config.Module = {
    id = 'altis',
    name = 'Altis',
    description = "Insuffle une énergie ascensionnelle permettant des bonds prodigieux, défiant la gravité.",
    icon = 'up-down',
    color = 'cyan',
    cooldown = 10000,
    type = 'utility',
    key = '5',
    image = 'images/power/wjump.png',
    video = "YOUR_VIDEO_URL_HERE",
    professor = true
}

Config.Messages = {
    noWand = {
        title = 'Altis',
        description = 'Vous devez équiper une baguette.',
        type = 'error',
        icon = 'up-down'
    },
    noTarget = {
        title = 'Altis',
        description = 'Aucune cible valide.',
        type = 'warning',
        icon = 'up-down'
    }
}

-- Particle effect configuration for air wave under feet
Config.Particles = {
    dict = 'core',
    name = 'veh_air_turbulance_water',
    scale = 1.2,
    offset = { x = 0.0, y = 0.0, z = -0.5 } -- Under feet
}

Config.Debug = false

_ENV.Config = Config

