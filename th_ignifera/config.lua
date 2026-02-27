---@diagnostic disable: undefined-global, trailing-space
local Config <const> = {}

Config.Projectile = {
    speed = 65.0,
    maxDistance = 1000.0
}

Config.Animation = {
    dict = 'export@nib@wizardsv_avada_kedrava',
    name = 'nib@wizardsv_avada_kedrava',
    flag = 0,
    duration = 3000,
    speedMultiplier = 3.5
}

Config.Module = {
    id = 'ignifera',
    name = 'Ignifera',
    description = "Condense le feu en une orbe incandescente explosant avec fureur à l’impact.",
    icon = 'explosion',
    color = 'orange',
    cooldown = 15000,
    type = 'attack',
    key = nil,
    image = 'images/power/firebreath.png',
    sound = '',
    video = 'YOUR_VIDEO_URL_HERE',
    professor = true
}

Config.Damage = {
    perLevel = 90,      -- Damage per spell level (Level 1 = 50, Level 2 = 100, etc.)
    radius = 5.0        -- Damage radius in meters from explosion center
}

Config.Messages = {
    noWand = {
        title = 'Ignifera',
        description = 'Vous n\'avez pas de baguette équipée',
        type = 'error',
        icon = 'explosion'
    },
    noTarget = {
        title = 'Ignifera',
        description = 'Aucune cible détectée',
        type = 'warning',
        icon = 'explosion'
    }
}

Config.Debug = false

_ENV.Config = Config
