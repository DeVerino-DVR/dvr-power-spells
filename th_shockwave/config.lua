---@diagnostic disable: undefined-global, trailing-space
local Config <const> = {}

Config.Shockwave = {
    radius = 15.0,
    ragdollTime = 2000,
    shakeIntensity = 0.45,
    shakeDistance = 30.0
}

Config.FX = {
    ring = { dict = 'core', particle = 'veh_air_turbulance_water', scale = 2.0 },
    sparks = { dict = 'core', particle = 'ent_brk_sparking_wires', scale = 1.0 },
    smoke = { dict = 'core', particle = 'exp_water', scale = 1.4 }
}

Config.Module = {
    id = 'shockwave',
    name = 'Shockwave',
    description = "Libère une onde sismique magique faisant chanceler et tomber les cibles proches.",
    icon = 'burst',
    color = 'red',
    cooldown = 7000,
    type = 'attack',
    image = 'images/power/th_shockwave.png',
    video = "YOUR_VIDEO_URL_HERE",
    professor = true
}

Config.Messages = {
    noWand = {
        title = 'Shockwave',
        description = 'Vous devez équiper une baguette.',
        type = 'error',
        icon = 'burst'
    }
}

Config.Debug = false

_ENV.Config = Config
