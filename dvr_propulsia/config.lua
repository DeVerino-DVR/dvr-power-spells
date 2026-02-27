---@diagnostic disable: undefined-global, trailing-space
local Config <const> = {}

-- Propulsion configuration
Config.Propulsion = {
    selfLiftHeight = 0.4,           -- Hauteur de levitation du lanceur (mètres) - juste au-dessus du sol
    selfLiftForce = 3.0,            -- Force légère pour se soulever légèrement
    selfHoverDuration = 5000,       -- Durée totale de la lévitation (ms) - 5 secondes!
    hoverForceInterval = 50,        -- Intervalle d'application de la force de sustentation (ms)
    hoverForce = 2.5,               -- Force douce appliquée pour rester légèrement au-dessus du sol
    knockbackRadius = 8.0,          -- Rayon d'effet pour propulser les autres
    knockbackForceUp = 18.0,        -- Force verticale pour les cibles
    knockbackForceHorizontal = 15.0,-- Force horizontale pour les cibles
    ragdollTime = 3000,             -- Durée du ragdoll (ms)
    shakeIntensity = 0.5,           -- Intensité de la secousse de caméra
    shakeDistance = 25.0            -- Distance max de la secousse
}

-- Effets visuels (explosion d'eau spectaculaire)
Config.FX = {
    -- Montée d'eau progressive (avant explosion)
    waterRise = {
        dict = 'core',
        particle = 'ent_amb_tnl_bubbles_sml',
        scale = 2.5
    },
    -- Explosion principale massive
    waterExplosion = {
        dict = 'core',
        particle = 'exp_water',
        scale = 5.0  -- Plus grand!
    },
    -- Geyser vertical
    geyser = {
        dict = 'core',
        particle = 'water_splash_ped_out',
        scale = 4.0
    },
    -- Vagues qui se propagent
    waves = {
        dict = 'core',
        particle = 'veh_air_turbulance_water',
        scale = 3.5
    },
    -- Éclaboussures massives
    splash = {
        dict = 'core',
        particle = 'water_splash_ped_bubbles',
        scale = 3.0
    },
    -- Brouillard d'eau
    mist = {
        dict = 'core',
        particle = 'exp_water_mist',
        scale = 3.0
    },
    -- Particules qui suivent le joueur
    followPlayer = {
        dict = 'core',
        particle = 'water_splash_ped_out',
        scale = 2.0
    },
    -- Aura de baguette (intense)
    wand = {
        dict = 'core',
        particle = 'ent_amb_tnl_bubbles_sml',
        scale = 1.5
    }
}

-- Animation
Config.Animation = {
    dict = 'export@nib@wizardsv_wand_attack_lightning',
    name = 'nib@wizardsv_wand_attack_lightning',
    flag = 48,
    duration = 1800,
    speedMultiplier = 1.8,
    castDelay = 600  -- Délai avant l'activation du sort (ms)
}

-- Séquence d'effets (timings en ms)
Config.EffectSequence = {
    waterRiseStart = 0,      -- Début de la montée d'eau
    geyserStart = 300,       -- Geyser commence à jaillir
    explosionStart = 500,    -- BOOM! Explosion massive
    wavesStart = 520,        -- Vagues se propagent
    splashStart = 540,       -- Éclaboussures
    mistStart = 600,         -- Brouillard d'eau
    playerLiftStart = 500,   -- Le joueur se soulève
    playerEffectDuration = 5000,  -- Durée des effets sur le joueur - 5 SECONDES!
    continuousSplashInterval = 400,  -- Intervalle entre les éclaboussures continues (ms)
    continuousMistInterval = 600     -- Intervalle entre les brouillards continus (ms)
}

-- Module registration
Config.Module = {
    id = 'propulsia',
    name = 'Propulsia',
    description = "Déclenche une explosion d'eau massive sous vos pieds qui vous soulève légèrement et repousse violemment tous ceux qui vous entourent.",
    icon = 'water',
    color = 'blue',
    cooldown = 9000,
    type = 'attack',
    image = 'images/power/dvr_propulsia.png',
    video = '',
    professor = true
}

-- Messages
Config.Messages = {
    noWand = {
        title = 'Propulsia',
        description = 'Vous devez équiper une baguette.',
        type = 'error',
        icon = 'water'
    }
}

Config.Debug = false

_ENV.Config = Config
