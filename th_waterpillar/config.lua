---@diagnostic disable: undefined-global, trailing-space
local Config <const> = {}

Config.Projectile = {
    model = "nib_diffindo_prop",
    speed = 28.0,
    maxDistance = 1000.0
}

Config.Pillar = {
    model = 'wizardsV_nib_accio_ray',
    duration = 6000,
    rotation_speed = 90.0,
    spawn_offset = 0.0
}

Config.Animation = {
    dict = 'export@nib@wizardsv_avada_kedrava',
    name = 'nib@wizardsv_avada_kedrava',
    flag = 0,
    duration = 3000,
    speedMultiplier = 3.0,
    projectileDelay = 1800,
    cleanupDelay = 800
}

Config.Effects = {
    wand = {
        dict = 'core',
        name = 'ent_amb_tnl_bubbles_sml',
        alpha = 1.0,
        offset = { x = 0.4, y = 0.0, zstart = 0.0 },
        rot = { x = 0.0, y = 0.0, z = 0.0 }
    },
    pillar = {
        dict = 'core',
        bubble = 'ent_amb_tnl_bubbles_sml',
        splash = 'veh_air_turbulance_water',
        splash2 = 'exp_water',
        fountain = 'ent_amb_fountain_pour'
    }
}

Config.Module = {
    id = 'waterpillar',
    name = 'Water Pillar',
    description = "Fait jaillir une colonne d’eau sous pression au point d’impact choisi.",
    icon = 'water',
    color = 'blue',
    cooldown = 4000,
    type = 'attack',
    image = 'images/power/th_waterpillar.png',
    video = "YOUR_VIDEO_URL_HERE",
    professor = true
}

Config.Damage = {
    perLevel = 50,      -- Damage per spell level (Level 1 = 80, Level 2 = 160, etc.)
    radius = 5.0        -- Damage radius in meters from pillar center
}

Config.Messages = {
    noWand = {
        title = 'Water Pillar',
        description = 'Vous devez équiper une baguette.',
        type = 'error',
        icon = 'water'
    }
}

Config.Debug = false

_ENV.Config = Config
