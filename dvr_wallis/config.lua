---@diagnostic disable: undefined-global, trailing-space
local Config <const> = {}

-- Wall configuration
Config.Wall = {
    baseLength = 5.0,              -- Base length in meters (level 1)
    lengthPerLevel = 1.0,          -- Additional length per level
    baseHeight = 3.0,              -- Base height in meters
    heightPerLevel = 0.3,          -- Additional height per level
    thickness = 0.5,               -- Wall thickness
    riseDuration = 800,            -- Time for wall to rise from ground (ms)
    baseDuration = 2000            -- Base duration in ms (5 seconds per level)
}

-- Level scaling configuration
Config.Levels = {
    [1] = {
        length = 2.0,               -- 5 meters
        height = 3.0,               -- 3 meters
        duration = 4000             -- 2 seconds
    },
    [2] = {
        length = 4.0,               -- 6 meters
        height = 3.3,               -- 3.3 meters
        duration = 6000             -- 4 seconds
    },
    [3] = {
        length = 6.0,               -- 7 meters
        height = 3.6,               -- 3.6 meters
        duration = 8000             -- 6 seconds
    },
    [4] = {
        length = 8.0,               -- 8 meters
        height = 3.9,               -- 3.9 meters
        duration = 10000             -- 8 seconds
    },
    [5] = {
        length = 10.0,              -- 10 meters
        height = 5.0,               -- 4.5 meters
        duration = 12000            -- 10 seconds
    }
}

-- Visual effects
Config.Effects = {
    wallModel = 'prop_rock_4_big2',  -- Rock prop
    collisionModel = 'prop_container_01a', -- Heavy container for collision (invisible)
    fenceWidth = 2.0,                    -- Horizontal spacing between rocks
    fenceHeight = 1.2,                   -- Height of each rock prop
    rockRows = 3,                        -- Number of rows (stacked vertically)
    useVisibleFence = true,              -- Use visible fence props
    useCollisionProps = true,            -- Add invisible collision props
    particles = {
        -- Energy effect on the fence
        main = {
            dict = 'core',
            name = 'exp_grd_bzgas_smoke',  -- Smoke for magical effect
            scale = 1.5,
            color = { r = 0.2, g = 0.6, b = 1.0 }  -- Blue energy color
        },
        energy = {
            dict = 'core',
            name = 'ent_amb_elec_crackle_sp',  -- Electric crackle effect
            scale = 1.5
        },
        glow = {
            dict = 'core',
            name = 'veh_light_clear',  -- Glow effect
            scale = 1.0
        }
    },
    rise = {
        dict = 'core',
        name = 'ent_amb_elec_fire_sp',  -- Energy burst on rise
        scale = 2.0
    },
    spawn = {
        dict = 'scr_rcbarry2',
        name = 'scr_clown_appears',  -- Pop effect when wall appears
        scale = 2.5
    }
}

-- Animation configuration
Config.Animation = {
    dict = 'export@nib@wizardsv_wand_attack_smash',
    name = 'nib@wizardsv_wand_attack_smash',
    flag = 0,
    duration = 2000,
    speedMultiplier = 1.5
}

-- Sound configuration
Config.Sounds = {
    cast = {
        url = '',  -- Optional cast sound
        volume = 0.7
    },
    rise = {
        url = 'YOUR_SOUND_URL_HERE',
        volume = 0.8
    },
    descend = {
        url = 'YOUR_SOUND_URL_HERE',
        volume = 0.8
    }
}

-- Module registration
Config.Module = {
    id = 'wallis',
    name = 'Wallis',
    description = 'Invoque un mur magique infranchissable qui sort du sol à l\'endroit visé.',
    icon = 'shield',
    color = 'blue',
    cooldown = 15000,
    type = 'defense',
    image = 'images/power/dvr_wallis.png',
    video = '',
    professor = true
}

-- Notification messages
Config.Messages = {
    noWand = {
        title = 'Wallis',
        description = 'Vous devez équiper une baguette.',
        type = 'error',
        icon = 'shield'
    },
    noTarget = {
        title = 'Wallis',
        description = 'Aucune zone valide ciblée.',
        type = 'warning',
        icon = 'shield'
    }
}

Config.Debug = false

_ENV.Config = Config

