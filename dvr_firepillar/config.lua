---@diagnostic disable: undefined-global, trailing-space
local Config <const> = {}

Config.Pillar = {
    model = 'nib_fire_tornado',
    duration = 8000,
    rotation_speed = 160.0,
    spawn_offset = 0.0
}

Config.Projectile = {
    speed = 30.0,
    maxDistance = 1000.0
}

Config.Animation = {
    duration = 3000,
    propsDelay = 2200,
    speedMultiplier = 3.0,
}

Config.Module = {
    id = 'firepillar',
    name = 'Fire Pillar',
    description = "Invoque une tornade ardente s’élevant du sol et consumant la zone ciblée.",
    icon = 'fire',
    color = 'red',
    cooldown = 3000,
    type = 'attack',
    image = 'images/power/dvr_firepillar.png',
    video = "YOUR_VIDEO_URL_HERE",
    professor = false
}

Config.Damage = {
    perLevel = 50,      -- Damage per spell level (Level 1 = 50, Level 2 = 100, etc.)
    radius = 5.0        -- Damage radius in meters from pillar center
}

Config.Messages = {
    noWand = {
        title = 'Fire Pillar',
        description = 'Vous avez besoin d\'une baguette pour utiliser ce sort.',
        type = 'error',
        icon = 'fire'
    },
    noTarget = {
        title = 'Fire Pillar',
        description = 'Aucune cible valide devant vous.',
        type = 'warning',
        icon = 'fire'
    }
}

Config.Debug = false

_ENV.Config = Config    
