---@diagnostic disable: trailing-space
local Config <const> = {}

Config.Buff = {
    duration = 30000,
    speedMultiplier = 1.49,
    sprintMultiplier = 1.49
}

Config.Raycast = {
    maxDistance = 60.0
}

Config.Module = {
    id = 'speedom',
    name = 'Speedom',
    description = "Accélère le Flux corporel, permettant au lanceur ou à une cible de se mouvoir avec vélocité.",
    icon = 'person-running',
    color = 'blue',
    cooldown = 10000,
    type = 'utility',
    key = '5',
    image = 'images/power/th_speedom.png',
    video = "YOUR_VIDEO_URL_HERE",
    professor = true
}

Config.Messages = {
    noWand = {
        title = 'Speedom',
        description = 'Vous devez équiper une baguette.',
        type = 'error',
        icon = 'person-running'
    },
    noTarget = {
        title = 'Speedom',
        description = 'Aucune cible valide.',
        type = 'warning',
        icon = 'person-running'
    }
}

Config.Debug = false

_ENV.Config = Config    
