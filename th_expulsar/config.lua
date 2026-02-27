local Config <const> = {}

Config.expulsar = {
    radius = 35.0,
    force = 5.0,
    upwardForce = 5.0,
    duration = 1000
}

Config.Animation = {
    dict = "export@nib@wizardsv_wand_attack_2",
    name = "nib@wizardsv_wand_attack_2",
    flag = 0,
    duration = 1500,
    speedMultiplier = 6.5,
}

Config.Effects = {
    shockwaveParticles = {
        asset = 'core',
        name = 'veh_sub_crush',
        count = 1,
        radius = 0.0,
        scale = 3.5,
        duration = 800
    },
    
    explosion = {
        type = 13,
        damage = 0.0,
        isAudible = true,
        isInvisible = true,
        cameraShake = 1.5
    },
    
    cameraShake = {
        name = 'SMALL_EXPLOSION_SHAKE',
        intensity = 0.3,
        maxDistance = 20.0
    }
}

_ENV.Config = Config
