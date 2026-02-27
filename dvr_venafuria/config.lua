---@diagnostic disable: undefined-global, trailing-space
local Config <const> = {}

Config.Projectile = {
    speed = 50.0,
    maxDistance = 100.0,
    shotTiming = 2100
}

Config.Levitation = {
    height = 3.0,
    riseTime = 400,
    maxHoldTime = 5000,
    dropForce = 30.0,
    -- Timings des 3 smash (ms après le début du sort)
    smashTimings = { 1500, 3000, 5000 },
    -- Temps pour se relever entre les smash
    recoveryTime = 300
}

Config.Ragdoll = {
    baseDuration = 3000,
    perLevel = 500,
    maxDuration = 6000
}

Config.Damage = {
    perLevel = 80,
    radius = 3.0
}

Config.Effects = {
    projectile = {
        model = 'w_pi_flaregun_shell',
        trail = {
            asset = 'core',
            name = 'veh_light_red_trail',
            scale = 0.8
        }
    },
    particle = {
        dict = 'scr_bike_adversary',
        name = 'scr_adversary_gunsmith_weap_smoke',
        alpha = 1.0,
        offset = { x = 0.4, y = 0.0, zstart = 0.0, zend = 0.05 },
        rot = { x = 0.0, y = 0.0, z = 0.0 }
    },
    impact = {
        asset = 'core',
        effects = {
            { name = 'ent_brk_sparking_wires', offset = -0.2, scale = 1.2 },
            { name = 'bul_rubber_dust', offset = -0.3, scale = 1.0 }
        }
    },
    liftAura = {
        asset = 'core',
        effect = 'ent_dst_elec_crackle',
        scale = 1.5,
        color = { r = 255, g = 50, b = 50 }
    },
    shake = {
        maxDistance = 30.0,
        intensity = 0.4
    },
    bloodSplatter = {
        effects = {
            { asset = 'core', name = 'blood_entry', scale = 3.0, count = 12 },
            { asset = 'core', name = 'blood_entry_med', scale = 2.5, count = 10 },
            { asset = 'core', name = 'blood_stab', scale = 2.0, count = 8 }
        },
        spread = true,
        spreadRadius = 2.0
    }
}

Config.Sounds = {
    cast = {
        url = 'YOUR_SOUND_URL_HERE',
        volume = 0.7
    }
}

Config.Module = {
    id = 'venafuria',
    name = 'Vena Furia',
    description = "Projette un eclair rouge qui souleve la cible dans les airs avant de la projeter violemment au sol.",
    icon = 'arrow-up-from-ground-water',
    color = 'red',
    cooldown = 12000,
    type = 'attack',
    image = 'images/power/dvr_venafuria.png',
    video = '',
    professor = false,
    animation = {
        dict = "export@nib@wizardsv_wand_attack_smash",
        name = "nib@wizardsv_wand_attack_smash",
        flag = 0,
        duration = 6000,
        speedMultiplier = 1.0
    }
}

Config.Messages = {
    noWand = {
        title = 'Vena Furia',
        description = 'Vous devez equiper une baguette.',
        type = 'error',
        icon = 'arrow-up-from-ground-water'
    },
    noTarget = {
        title = 'Vena Furia',
        description = 'Aucune cible visee.',
        type = 'error',
        icon = 'arrow-up-from-ground-water'
    },
    outOfRange = {
        title = 'Vena Furia',
        description = 'Cible hors de portee.',
        type = 'error',
        icon = 'arrow-up-from-ground-water'
    }
}

Config.Debug = false

_ENV.Config = Config
