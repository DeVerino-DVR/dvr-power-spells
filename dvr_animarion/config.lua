local Config = {}

Config.Projectile = {
    model = 'wizardsV_nib_avadakedavra_ray',
    speed = 120.0,
    duration = 600,
    handBone = 28422
}

Config.Animation = {
    dict = "export@nib@wizardsv_wand_attack_2",
    name = "nib@wizardsv_wand_attack_2",
    flag = 0,
    duration = 2000,
    speedMultiplier = 6.0,
    propsDelay = 200
}

Config.Animagus = {
    duration = 30000,
    cooldown = 45000,
    animals = {
        'a_c_cat_01',
        'a_c_deer',
        'a_c_boar',
        'a_c_rabbit_01',
        'a_c_hen',
        'a_c_pig',
        'a_c_coyote'
    }
}

Config.Effects = {
    wandParticles = {
        asset = 'core',
        name = 'veh_light_clear',
        scale = 0.5,
        color = {r = 0.8, g = 0.4, b = 0.0}
    },
    
    projectileTrail = {
        asset = 'core',
        name = 'proj_flare_trail',
        scale = 1.0,
        color = {r = 1.0, g = 0.6, b = 0.0}
    },
    
    transformEffect = {
        asset = 'scr_rcbarry1',
        name = 'scr_alien_teleport',
        scale = 1.5,
        duration = 2000
    },
    
    smokeEffect = {
        asset = 'core',
        name = 'exp_grd_bzgas_smoke',
        scale = 2.0,
        color = {r = 1.0, g = 0.6, b = 0.0}
    }
}

return Config
