---@diagnostic disable: trailing-space
local Config <const> = {}

-- Coordonnées de téléportation de la cible
Config.TeleportCoords = vector4(-7459.72, -55.85, 19.12, 198.37)

Config.Projectile = {
    model = 'wizardsV_nib_avadakedavra_ray',
    speed = 100.0,
    duration = 800,
    handBone = 28422
}

Config.Animation = {
    dict = 'export@nib@wizardsv_wand_attack_b5',
    name = 'nib@wizardsv_wand_attack_b5',
    flag = 0,
    duration = 3000,
    propsDelay = 2100,
    speedMultiplier = 8.5
}

Config.ImpactSound = {
    url = 'YOUR_SOUND_URL_HERE',
    volume = 0.1,
    radius = 3.0
}

Config.Effects = {
    explosion = {
        type = 1,
        damage = 0.05,
        isAudible = true,
        isInvisible = false,
        cameraShake = 3.0
    },

    fireParticles = {
        asset = 'ns_ptfx',
        name = 'fire',
        count = 8,
        radius = 1.0,
        scale = 10.0,
        duration = 2000
    },

    smokeParticles = {
        asset = 'core',
        name = 'exp_grd_bzgas_smoke',
        count = 3,
        scale = 2.0,
        duration = 2000
    },

    cameraShake = {
        name = 'SMALL_EXPLOSION_SHAKE',
        intensity = 1.0,
        maxDistance = 15.0
    }
}

_ENV.Config = Config
