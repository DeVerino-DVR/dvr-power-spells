---@diagnostic disable: trailing-space
local Config <const> = {}

Config.Animation = {
    dict = 'export@nib@broomstick_summon_in',
    name = 'nib@broomstick_summon_in',
    flag = 0,
    duration = 2000
}

Config.Transplanner = {
    duration = 1000 * 300,           -- Durée max du transplanage (15 secondes)
    speed = 0.55,                -- Vitesse de déplacement normale
    maxHeight = 300.0,          -- Hauteur maximale
    noclipSpeed = {
        normal = 0.55,           -- Vitesse de base (utilisée en permanence)
        fast = 0.55,             -- Vitesse rapide (maintenir Shift)
        slow = 0.55             -- Vitesse lente (maintenir Alt)
    },
    collisionProbe = {
        radius = 0.35,          -- Rayon de détection des collisions
        verticalOffset = 0.2,   -- Offset vertical pour mieux suivre le relief
        pushback = 0.28,        -- Recul appliqué lorsqu'on rencontre une collision
        minClearance = 0.25     -- Hauteur minimale au-dessus du sol
    }
}

Config.Effects = {
    wandParticles = {
        asset = 'core',
        name = 'veh_light_clear',
        scale = 0.0,
        color = {r = 0.3, g = 0.0, b = 0.3} 
    },
    
    blackSmoke = {
        asset = 'scr_bike_adversary',
        name = 'scr_adversary_weap_smoke',
        scale = 0.0,
        color = {r = 0.8, g = 0.8, b = 0.8},
        alpha = 0.9
    },

    additionalSmoke = {
        asset = 'scr_bike_adversary',
        name = 'scr_adversary_weap_smoke',
        scale = 0.0,
        color = {r = 0.7, g = 0.7, b = 0.7},
        alpha = 0.75
    },

    trail = {
        asset = 'scr_bike_adversary',
        effect = 'scr_adversary_weap_smoke',
        scale = 0.0,
        color = { r = 0.7, g = 0.7, b = 0.7 },
        alpha = 0.8,
        interval = 100,
        lifetime = 1500,
        offset = -0.55
    },


    aura = {
        asset = 'core',
        effect = 'ent_amb_elec_crackle',
        offset = { x = 0.0, y = 0.0, z = 0.5 },
        scale = 0.85,
        color = { r = 0.35, g = 0.7, b = 1.0 },
        alpha = 110
    },

    pulseLight = {
        color = { r = 140, g = 200, b = 255 },
        radius = 7.0,
        intensity = 12.0,
        period = 1800
    },

    release = {
        asset = 'core',
        effect = 'ent_sht_elec_fire_sp',
        count = 2,
        scale = 1.6,
        offset = { x = 0.0, y = 0.0, z = 0.4 },
        light = {
            color = { r = 160, g = 210, b = 255 },
            radius = 7.0,
            intensity = 12.0,
            duration = 420
        }
    },

    shadowBurst = {
        asset = 'core',
        effect = 'ent_amb_smoke_black',
        count = 3,
        scale = 2.2,
        offset = { x = 0.0, y = 0.0, z = 0.3 },
        light = {
            color = { r = 80, g = 110, b = 140 },
            radius = 6.0,
            intensity = 10.0,
            duration = 480
        }
    },
    
    teleportStart = {
        asset = 'scr_sr_adversary',
        name = 'scr_sr_lg_weapon_highlight',
        scale = 2.0,
        duration = 1000
    },
    
    teleportEnd = {
        asset = 'scr_sr_adversary',
        name = 'scr_sr_lg_weapon_highlight',
        scale = 2.5,
        duration = 1500
    },

    jobTrail = {
        asset = 'scr_ba_bb',
        effect = 'scr_ba_bb_plane_smoke_trail',
        scale = 0.3,
        bone = 24818,
        default_color = { r = 255, g = 255, b = 255 }
    },

    -- Traînée de mouvement synchronisée (pour les autres joueurs)
    motionTrail = {
        asset = 'scr_ba_bb',
        effect = 'scr_ba_bb_plane_smoke_trail',
        scale = 0.25,
        spacing = 0.8,
        maxSegments = 8,
        lifetime = 1200,
        offset = 0.0,
        randomness = 0.1,
        color = { r = 255, g = 255, b = 255 },
        alpha = 0.9
    }
}

Config.JobTrailColors = {
    wand_professeur = { r = 255, g = 0, b = 0 },        -- rouge
    professeur = { r = 60, g = 140, b = 255 },          -- bleu
    potion = { r = 170, g = 80, b = 200 },              -- violet
    herbomagie = { r = 0, g = 255, b = 0 },             -- vert
    employe = { r = 255, g = 255, b = 255 },            -- blanc
    direction = { r = 255, g = 200, b = 60 },           -- or
    baguette = { r = 125, g = 90, b = 55 },             -- marron
    sennara = { r = 255, g = 255, b = 255 },            -- blanc
    dahrion = { r = 255, g = 255, b = 255 },            -- blanc
    veylaryn = { r = 255, g = 255, b = 255 },           -- blanc
    thaelora = { r = 255, g = 255, b = 255 },           -- blanc
    magenoir = { r = 0, g = 0, b = 0 },                 -- noir
    default = { r = 255, g = 255, b = 255 }             -- blanc / défaut
}

Config.Controls = {
    forward = 32,   -- W
    backward = 33,  -- S
    left = 34,      -- A
    right = 35,     -- D
    up = 22,        -- Space
    down = 36,      -- Ctrl
    speedUp = 21,   -- Shift
    slowDown = 19,  -- Alt
    cancel = 73     -- X
}

Config.SpellConfig = {
    -- Configuration par défaut pour le sort transvalis
    default = {
        -- Options de bring player
        bringPlayers = false,        -- Téléporter les joueurs autour de soi
        bringRadius = 5.0,           -- Rayon en mètres pour le bring player
        -- Positions sauvegardées (sera géré dynamiquement selon le niveau)
        savedPositions = {},         -- Table des positions sauvegardées
        -- Couleur personnalisée (niveau 5 uniquement)
        customColor = nil            -- nil = couleur du job, sinon nom de la couleur personnalisée
    },

    -- Limites selon le niveau du sort
    levelLimits = {
        [1] = { maxPositions = 2 },
        [2] = { maxPositions = 5 },
        [3] = { maxPositions = 8 },
        [4] = { maxPositions = 12 },
        [5] = { maxPositions = 15 }
    },

    -- Couleurs personnalisées disponibles (niveau 5 uniquement)
    customColors = {
        { name = 'Rouge', value = 'rouge', color = { r = 255, g = 0, b = 0 } },
        { name = 'Bleu', value = 'bleu', color = { r = 60, g = 140, b = 255 } },
        { name = 'Violet', value = 'violet', color = { r = 170, g = 80, b = 200 } },
        { name = 'Vert', value = 'vert', color = { r = 0, g = 255, b = 0 } },
        { name = 'Blanc', value = 'blanc', color = { r = 255, g = 255, b = 255 } },
        { name = 'Or', value = 'or', color = { r = 255, g = 200, b = 60 } },
        { name = 'Noir', value = 'noir', color = { r = 0, g = 0, b = 0 } },
        { name = 'Rose', value = 'rose', color = { r = 255, g = 192, b = 203 } },
        { name = 'Cyan', value = 'cyan', color = { r = 0, g = 255, b = 255 } },
        { name = 'Orange', value = 'orange', color = { r = 255, g = 165, b = 0 } }
    },

    -- Menu de configuration
    menu = {
        title = 'Configuration Transvalis',
        subtitle = 'Configurez les options de votre sort Transvalis'
    }
}

_ENV.Config = Config
