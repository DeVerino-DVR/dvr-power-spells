---@diagnostic disable: undefined-global, trailing-space
local Config <const> = {}

-- Projectile configuration  
Config.Projectile = {
    speed = 85.0,              -- Rock projectile speed
    maxDistance = 1000.0,
    rotationSpeed = 480.0,     -- Fast spin
    -- Rock props with full geometry (visible from all angles)
    rockModels = {
        'prop_rock_4_c',       -- Medium rock with full geometry
        'prop_rock_4_a',       -- Medium rock with full geometry
        'rock_4_cl_2_2',       -- Medium rock with full geometry
        'prop_rock_4_big',     -- Big rock with full geometry
        'prop_rock_4_big2'     -- Big rock with full geometry
    },
    -- Number of rocks per level
    rocksPerLevel = {
        [1] = 1,   -- Level 1: 1 rock
        [2] = 1,   -- Level 2: 1 rock
        [3] = 2,   -- Level 3: 2 rocks
        [4] = 2,   -- Level 4: 2 rocks
        [5] = 3    -- Level 5: 3 rocks (barrage!)
    },
    spreadAngle = 3.0          -- Angle spread between rocks (degrees) - tight grouping on target
}

-- Impact effects configuration
Config.Impact = {
    -- Main debris effect (rock explosion)
    debris = {
        dict = 'des_fibstairs',
        particle = 'ent_ray_fbi5a_stairs_silt_fall',
        scale = 1.5
    },
    -- Secondary rock debris
    rocks = {
        dict = 'core',
        particle = 'ent_dst_rocks',
        scale = 1.8
    },
    -- Dust cloud
    dust = {
        dict = 'core',
        particle = 'exp_grd_bzgas_smoke',
        scale = 2.0
    }
}

-- Damage configuration (uses th_power damage system)
Config.Damage = {
    perLevel = 80,             -- Damage per spell level (heavy rock hit)
    radius = 3.5               -- Impact radius
}

-- Animation configuration
Config.Animation = {
    dict = 'export@nib@wizardsv_wand_attack_b5',
    name = 'nib@wizardsv_wand_attack_b5',
    flag = 0,
    duration = 2000,
    speedMultiplier = 10.5,
    projectileDelay = 500  -- Delay in ms before firing projectiles (adjust to match animation timing)
}

-- Visual effects
Config.Effects = {
    wand = {
        dict = 'core',
        name = 'veh_light_clear',
        color = { r = 0.6, g = 0.4, b = 0.2 }  -- Brown/earth color
    },
    trail = {
        dict = 'core',
        name = 'exp_grd_bzgas_smoke',  -- Dust trail
        scale = 0.8,
        color = { r = 0.6, g = 0.5, b = 0.4 }
    },
    impact = {
        dict = 'core',
        name = 'ent_amb_foundry_rocks',  -- Rock impact
        scale = 1.2
    }
}

-- Sound configuration
Config.Sounds = {
    cast = {
        url = '',  -- Optional cast sound
        volume = 0.7
    }
}

-- Module registration
Config.Module = {
    id = 'petrosa',
    name = 'Petrosa',
    description = 'Lance un rocher magique qui percute violemment la cible avec une force tellurique.',
    icon = 'mountain',
    color = 'brown',
    cooldown = 5000,
    type = 'attack',
    image = 'images/power/rocks.png',
    video = '',
    professor = true
}

-- Notification messages
Config.Messages = {
    noWand = {
        title = 'Petrosa',
        description = 'Vous devez équiper une baguette.',
        type = 'error',
        icon = 'mountain'
    }
}

Config.Debug = false

_ENV.Config = Config

