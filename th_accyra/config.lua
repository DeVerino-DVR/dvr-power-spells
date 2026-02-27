local Config <const> = {}

Config.Projectile = {
    model = 'nib_accio_ray',
    speed = 100.0,
    duration = 800,
    handBone = 28422
}

Config.Animation = {
    dict = 'export@nib@wizardsv_avada_kedrava',
    name = 'nib@wizardsv_avada_kedrava',
    flag = 0,
    duration = 3000,
    propsDelay = 2100,
    speedMultiplier = 2.5,
}

Config.Accio = {
    objectRadius = 5.0,          
    pullSpeed = 12.0,            
    pullDuration = 5000,         
    maxDistance = 100.0,         
}

Config.Effects = {
    wandParticles = {
        asset = 'core',
        name = 'veh_light_clear',
        scale = 0.55,
        color = {r = 0.25, g = 0.6, b = 1.0},
        alpha = 220
    },

    wandAura = {
        asset = 'core',
        name = 'ent_amb_elec_crackle_sp',
        scale = 0.7,
        color = {r = 0.3, g = 0.65, b = 1.0},
        alpha = 180
    },

    projectileTrail = {
        asset = 'core',
        name = 'ent_amb_elec_crackle_sp',
        scale = 0.8,
        color = {r = 0.35, g = 0.7, b = 1.0},
        alpha = 200
    },
    
    impactParticles = {
        asset = 'core',
        name = 'exp_grd_bzgas_smoke',
        count = 4,
        scale = 1.6,
        duration = 2200,
        color = {r = 0.25, g = 0.6, b = 1.0}
    },

    impactShockwave = {
        asset = 'core',
        name = 'ent_amb_elec_crackle_sp',
        scale = 2.4,
        color = {r = 0.35, g = 0.7, b = 1.0},
        alpha = 200
    },

    light = {
        color = {r = 60, g = 140, b = 255},
        range = 10.0,
        intensity = 1.8
    },

}

_ENV.Config = Config
