local Config = {}

Config.Projectile = {
    model = 'wizardsV_nib_avadakedavra_ray',
    speed = 130.0,
    duration = 500,
    handBone = 28422
}

Config.Animation = {
    dict = 'export@nib@wizardsv_wand_attack_b2',
    name = 'nib@wizardsv_wand_attack_b2',
    flag = 0,
    duration = 2200,
    speedMultiplier = 1.5,
    propsDelay = 600
}

Config.Petrificus = {
    duration = 15000,
    cooldown = 20000,
}

Config.Effects = {
    wandParticles = {
        asset = 'core',
        name = 'veh_light_clear',
        scale = 0.5,
        color = {r = 0.4, g = 0.6, b = 1.0}
    },
    
    projectileTrail = {
        asset = 'core',
        name = 'proj_flare_trail',
        scale = 2.0,
        color = {r = 0.3, g = 0.5, b = 1.0}
    },
    
    petrifyEffect = {
        asset = 'scr_rcbarry1',
        name = 'scr_alien_freeze_ray',
        scale = 1.0,
        duration = 2000
    },
    
    frozenAura = {
        asset = 'core',
        name = 'ent_amb_elec_crackle_sp',
        scale = 0.5,
        color = {r = 0.6, g = 0.8, b = 1.0}
    }
}

_ENV.Config = Config