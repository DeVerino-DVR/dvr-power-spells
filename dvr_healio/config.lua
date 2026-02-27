---@diagnostic disable: trailing-space
local Config <const> = {}

Config.Projectile = {
    model = 'wizardsV_nib_avadakedavra_ray',
    speed = 80.0,
    duration = 1000,
    handBone = 28422
}

Config.Timing = {
    propsDelay = 350,
    wandFxDuration = 550
}

Config.HealZone = {
    radius = 8.0,
    healAmount = 20,
    tickInterval = 2000,
    duration = 8000,
    maxPlayersHealed = 10
}

Config.Effects = {
    wandParticles = {
        asset = 'core',
        name = 'veh_light_clear',
        scale = 0.5,
        color = {r = 0.0, g = 1.0, b = 0.0}
    },

    greenCloud = {
        asset = 'core',
        name = 'exp_grd_bzgas_smoke',
        count = 3,
        scale = 3.5,
        duration = 8000,
        color = {r = 0.0, g = 1.0, b = 0.0}
    },

    healingParticles = {
        asset = 'scr_rcbarry2',
        name = 'scr_rcbarry2_vine_green',
        count = 1,
        radius = 0.0,
        scale = 2.5,
        duration = 8000
    },

    smokeRing = {
        asset = 'core',
        name = 'exp_extinguisher',
        count = 1,
        radius = 0.0,
        scale = 4.0,
        duration = 8000
    }
}

_ENV.Config = Config
