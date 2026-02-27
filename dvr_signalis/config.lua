---@diagnostic disable: undefined-global, trailing-space
local Config <const> = {}

Config.Projectile = {
    speed = 40.0,
    maxDistance = 250.0,
    maxHeightAboveGround = 250.0,
    gravity = 0.0
}

Config.Module = {
    id = 'signalis',
    name = 'Signalis',
    description = "Projette un marqueur magique visible à distance pour signaler un danger ou une présence.",
    icon = 'wand-magic-sparkles',
    color = 'red',
    cooldown = 5000,
    type = 'utility',
    key = nil,
    image = 'images/power/flipendo.png',
    video = 'YOUR_VIDEO_URL_HERE',
    professor = true
}

Config.Messages = {
    noWand = {
        title = 'Signalis',
        description = 'Vous n\'avez pas de baguette équipée',
        type = 'error',
        icon = 'wand-magic-sparkles'
    }
}

Config.Effects = {
    projectileTrail = {
        asset = 'core',
        name = 'proj_flare_trail',
        scale = 1.0
    },
    flare = {
        asset = 'core',
        name = 'exp_grd_flare',
        scale = 3.0,
        duration = 21000
    },
    smoke = {
        asset = 'core',
        name = 'exp_grd_flare',
        scale = 4.0,
        duration = 23000,
        heightOffset = 2.0
    }
}

Config.Debug = false

_ENV.Config = Config
