local Config = {}

Config.Projectile = {
    model = 'nib_magic_ray_basic',
    speed = 80.0,
    handBone = 28422
}

Config.Animation = {
    dict = 'export@nib@wizardsv_wand_attack_lightning',
    name = 'nib@wizardsv_wand_attack_lightning',
    flag = 0,
    duration = 2000,
    speedMultiplier = 1.5,
    effectPercent = 0.40,
    projectilePercent = 0.70
}

Config.Animation2 = {
    dict = 'export@nib@wizardsv_wand_attack_3_2',
    name = 'nib@wizardsv_wand_attack_3_2',
    flag = 0,
    duration = 1200,
    speedMultiplier = 12.0,
    projectilePercent = 2.5
}

Config.Cruorax = {
    duration = 20000,
    cooldown = 25000,
    emoteCommand = 'surrender5'
}

Config.Effects = {
    wandParticles = {
        asset = 'core',
        name = 'veh_light_clear',
        scale = 0.55,
        color = {r = 1.0, g = 0.2, b = 0.1}
    },

    projectileTrail = {
        asset = 'core',
        name = 'veh_light_red_trail',
        scale = 0.55,
        color = {r = 1.0, g = 0.2, b = 0.0}
    },

    impactExplosion = {
        asset = 'core',
        name = 'blood_stab',
        scale = 5.0,
        count = 40,
        radius = 3.0,
        waves = 6,
        waveDelay = 120
    },

    bloodCircle = {
        asset = 'core',
        name = 'blood_stab',
        radius = 2.5,
        pointCount = 24,
        scale = 3.5,
        duration = 20000,
        spawnDelay = 60,
        waves = 13,
        waveDelay = 0
    }
}

_ENV.Config = Config
