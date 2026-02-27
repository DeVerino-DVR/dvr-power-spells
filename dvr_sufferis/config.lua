---@diagnostic disable: undefined-global, trailing-space
local Config <const> = {}

Config.Projectile = {
    speed = 45.0,
    maxDistance = 10000.0
}

Config.Animation = {
    projectileDelay = 2200,
    speedMultiplier = 16.5
}

Config.Ragdoll = {
    baseDuration = 20000,
    perLevel = 0,
    maxDuration = 20000
}

Config.BloodEffect = {
    duration = 20000,
    intensity = 0.8,
    fadeInTime = 500,
    fadeOutTime = 2000     
}

Config.Lightning = {
    props = {
        boltSmall = 'wizardsV_nib_wizards_lightning_boltSmall',
        sub = 'wizardsV_nib_wizards_lightning_sub2',
        main = 'wizardsV_nib_wizards_lightning_main'
    },
    shake = {
        intensity = 0.6
    }
}

Config.Module = {
    id = 'sufferis',
    name = 'Sufferis',
    description = "Sortilège interdit invoquant une torture électrique infligeant une douleur extrême.",
    icon = 'skull-crossbones',
    color = 'red',
    cooldown = 8000,
    type = 'attack',
    image = 'images/power/shadowstep.png',
    video = 'YOUR_VIDEO_URL_HERE',
    professor = false
}

Config.Messages = {
    noWand = {
        title = 'Sufferis',
        description = 'Vous devez équiper une baguette.',
        type = 'error',
        icon = 'skull-crossbones'
    }
}

Config.Debug = true

_ENV.Config = Config
