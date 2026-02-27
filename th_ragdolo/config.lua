---@diagnostic disable: undefined-global, trailing-space
local Config <const> = {}

Config.Projectile = {
    speed = 30.0,
    maxDistance = 1000.0
}

Config.Ragdoll = {
    baseDuration = 2000,
    perLevel = 350,
    maxDuration = 5000
}

Config.Animation = {
    dict = 'export@nib@wizardsv_avada_kedrava',
    name = 'nib@wizardsv_avada_kedrava',
    flag = 0,
    duration = 3000,
    speedMultiplier = 3.5,
    projectileDelay = 2200,
    cleanupDelay = 800
}

Config.Module = {
    id = 'ragdolo',
    name = 'Ragdolo',
    description = "Brise l’équilibre de la cible, laissant son corps sans appui ni contrôle.",
    icon = 'person-falling',
    color = 'purple',
    cooldown = 4000,
    type = 'control',
    key = '5',
    image = 'images/power/th_ragdolo.png',
    video = "YOUR_VIDEO_URL_HERE",
    professor = true
}

Config.Messages = {
    noWand = {
        title = 'Ragdolo',
        description = 'Vous devez équiper une baguette.',
        type = 'error',
        icon = 'person-falling'
    }
}

Config.Debug = false

_ENV.Config = Config    
