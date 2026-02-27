---@diagnostic disable: undefined-global, trailing-space
local Config <const> = {}

-- Signal projectile (the fireball that flies from wand to target)
Config.SignalProjectile = {
    speed = 55.0                -- Speed of the signal projectile
}

-- Meteor configuration
Config.Meteor = {
    spawnHeight = 80.0,         -- Height from which meteors spawn above target
    fallSpeed = 45.0,           -- Fall speed of meteors
    impactRadius = 4.0,         -- Radius of each meteor impact
    spreadRadius = 8.0,         -- How spread out meteors are from center
    baseCount = 3,              -- Base number of meteors at level 1
    countPerLevel = 1,          -- Additional meteors per spell level
    delayBetween = 350,         -- Delay (ms) between meteor spawns
    rotationSpeed = 720.0       -- Meteor spin speed (degrees/sec)
}

-- Level scaling configuration
Config.Levels = {
    [1] = { meteorCount = 3, spreadMult = 0.8,  shakeMult = 0.5 },
    [2] = { meteorCount = 4, spreadMult = 0.9,  shakeMult = 0.65 },
    [3] = { meteorCount = 5, spreadMult = 1.0,  shakeMult = 0.8 },
    [4] = { meteorCount = 6, spreadMult = 1.1,  shakeMult = 0.9 },
    [5] = { meteorCount = 8, spreadMult = 1.25, shakeMult = 1.0 }
}

-- Damage configuration (uses th_power damage system)
Config.Damage = {
    perLevel = 120,              -- Damage per spell level per meteor hit
    radius = 4.0                -- Damage radius per meteor impact
}

-- Visual effects
Config.Effects = {
    trail = {
        dict = 'core',
        particle = 'veh_light_red_trail',
        scale = 1.2
    },
    fire = {
        dict = 'core',
        particle = 'ent_ray_heli_aprtmnt_l_fire',
        scale = 0.8
    },
    impact = {
        dict = 'core',
        particle = 'exp_grd_plane_small',
        scale = 1.0
    },
    shake = {
        maxDistance = 25.0,
        intensity = 0.35
    }
}

-- Animation configuration
Config.Animation = {
    dict = 'export@nib@wizardsv_wand_attack_smash',
    name = 'nib@wizardsv_wand_attack_smash',
    flag = 0,
    duration = 2200,
    speedMultiplier = 1.2
}

-- Sound configuration
Config.Sounds = {
    cast = {
        url = 'YOUR_SOUND_URL_HERE',
        volume = 0.7
    },
    impact = {
        url = '',  -- Optional impact sound
        volume = 0.85
    }
}

-- Module registration
Config.Module = {
    id = 'meteora',
    name = 'Meteora',
    description = "Invoque une pluie de météores enflammés s'abattant du ciel sur la zone ciblée.",
    icon = 'meteor',
    color = 'orange',
    cooldown = 12000,
    type = 'attack',
    image = 'images/power/firestorm.png',
    video = '',
    professor = true
}

-- Notification messages
Config.Messages = {
    noWand = {
        title = 'Meteora',
        description = 'Vous devez équiper une baguette.',
        type = 'error',
        icon = 'meteor'
    },
    noTarget = {
        title = 'Meteora',
        description = 'Aucune zone valide ciblée.',
        type = 'warning',
        icon = 'meteor'
    }
}

Config.Debug = false

_ENV.Config = Config

