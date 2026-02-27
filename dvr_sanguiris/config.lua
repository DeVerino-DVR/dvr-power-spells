---@diagnostic disable: undefined-global, trailing-space
local Config <const> = {}

Config.Projectile = {
    speed = 32.0,
    maxDistance = 900.0
}

Config.Animation = {
    duration = 3000,
    propsDelay = 2200,
    speedMultiplier = 2.5
}

Config.Bleed = {
    tickDamage = 10,
    tickInterval = 2000,
    maxDuration = 30000,
    ragdollDuration = 30000,
    fx = {
        impact = { asset = 'scr_solomon3', name = 'scr_trev4_747_blood_impact', scale = 0.3 },
        ground = { asset = 'core', name = 'blood_drip', scale = 0.0, offset = -0.9, lifetime = 1600 },
        loop = { asset = 'core', name = 'trail_splash_blood', scale = 0.0 }
    }
}

Config.Module = {
    id = 'sanguiris',
    name = 'Sanguiris',
    description = "Déchaîne une magie tranchante qui lacère la chair et fait couler le sang sans répit.",
    icon = 'droplet',
    color = 'crimson',
    cooldown = 8000,
    type = 'offense',
    key = nil,
    image = 'images/power/dvr_sanguiris.png',
    video = "YOUR_VIDEO_URL_HERE",
    professor = false
}

Config.Messages = {
    noWand = {
        title = 'Sanguiris',
        description = 'Vous devez équiper une baguette.',
        type = 'error',
        icon = 'droplet'
    }
}

Config.Debug = false

_ENV.Config = Config
