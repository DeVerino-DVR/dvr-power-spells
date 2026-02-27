---@diagnostic disable: undefined-global, trailing-space
local Config <const> = {}

-- Projectile configuration
Config.Projectile = {
    speed = 60.0,                  -- Vitesse du projectile (plus lent pour effet dramatique)
    maxDistance = 150.0,           -- Distance maximale
    size = 1.5,                    -- Taille de l'orbe
}

-- Damage & Impact
Config.Impact = {
    damageRadius = 12.0,           -- Rayon des dégâts
    knockbackRadius = 15.0,        -- Rayon de projection
    knockbackForceUp = 25.0,       -- Force verticale ÉNORME
    knockbackForceHorizontal = 20.0, -- Force horizontale MASSIVE
    ragdollTime = 4000,            -- Durée du ragdoll (ms)
    shakeIntensity = 1.2,          -- Secousse de caméra INTENSE
    shakeDistance = 50.0,          -- Distance de la secousse
    damagePerLevel = 25            -- Dégâts par niveau
}

-- Effets visuels (ULTRA SPECTACULAIRES - VERSION MASSIVE!)
Config.FX = {
    -- PHASE 1: Charge du lanceur (aura noire)
    casterAura = {
        dict = 'scr_rcbarry1',
        particle = 'scr_alien_disintegrate',
        scale = 3.0
    },
    casterDarkness = {
        dict = 'core',
        particle = 'exp_grd_bzgas_smoke',
        scale = 2.5
    },
    wandPower = {
        dict = 'scr_reconstructionaccident',
        particle = 'scr_sparking_generator',
        scale = 2.0
    },

    -- PHASE 2: Projectile (orbe de ténèbres MASSIVE)
    orbCore = {
        dict = 'scr_reconstructionaccident',
        particle = 'scr_sparking_generator',
        scale = 4.0  -- DOUBLE!
    },
    orbTrail = {
        dict = 'scr_rcbarry1',
        particle = 'scr_alien_disintegrate',
        scale = 3.0  -- DOUBLE!
    },
    orbSmoke = {
        dict = 'core',
        particle = 'exp_grd_bzgas_smoke',
        scale = 2.5  -- DOUBLE!
    },

    -- PHASE 3: EXPLOSIONS MULTIPLES MASSIVES
    -- Explosion nucléaire centrale
    nuclearBlast = {
        dict = 'scr_xm_orbital',
        particle = 'scr_xm_orbital_blast',
        scale = 10.0  -- GIGANTESQUE!
    },
    -- Onde de choc
    shockwave = {
        dict = 'scr_rcbarry1',
        particle = 'scr_alien_impact_bul',
        scale = 12.0  -- ENCORE PLUS ÉNORME!
    },
    -- Implosion de ténèbres (remplace le flash)
    darkImplosion = {
        dict = 'scr_rcbarry1',
        particle = 'scr_alien_teleport',
        scale = 10.0
    },
    -- Énergie noire
    darkEnergy = {
        dict = 'scr_rcbarry1',
        particle = 'scr_alien_disintegrate',
        scale = 8.0
    },

    -- PHASE 4: Flammes apocalyptiques
    darkFire1 = {
        dict = 'core',
        particle = 'fire_wrecked_plane_cockpit',
        scale = 6.0  -- TRIPLE!
    },
    darkFire2 = {
        dict = 'core',
        particle = 'fire_wrecked_bike',
        scale = 5.0
    },
    infernoRing = {
        dict = 'core',
        particle = 'exp_air_molotov',
        scale = 8.0
    },

    -- PHASE 5: Explosion principale avec variantes
    mainExplosion = {
        dict = 'scr_reconstructionaccident',
        particle = 'scr_reconstruct_pipefall',
        scale = 10.0  -- MASSIF!
    },
    secondaryExplosion = {
        dict = 'des_vaultdoor',
        particle = 'ent_ray_pro1_sparking_wires',
        scale = 6.0
    },

    -- PHASE 6: Éclairs apocalyptiques
    lightning1 = {
        dict = 'scr_agencyheistb',
        particle = 'scr_agency3b_elec_box',
        scale = 5.0  -- DOUBLE!
    },
    lightning2 = {
        dict = 'scr_reconstructionaccident',
        particle = 'scr_sparking_generator',
        scale = 4.0
    },
    electricStorm = {
        dict = 'scr_agencyheistb',
        particle = 'scr_agency3b_door_hatch_sparks',
        scale = 6.0
    },

    -- PHASE 7: Fumée apocalyptique
    persistentSmoke = {
        dict = 'core',
        particle = 'exp_grd_bzgas_smoke',
        scale = 8.0  -- ÉNORME!
    },
    toxicCloud = {
        dict = 'core',
        particle = 'exp_grd_bzgas',
        scale = 7.0
    },

    -- PHASE 8: Débris massifs
    debris = {
        dict = 'core',
        particle = 'ent_dst_rocks',
        scale = 4.0  -- DOUBLE!
    },
    dustCloud = {
        dict = 'core',
        particle = 'ent_dst_gen_gobstop',
        scale = 8.0
    },

    -- PHASE 9: Aura résiduelle persistante
    residualAura = {
        dict = 'scr_rcbarry1',
        particle = 'scr_alien_teleport',
        scale = 6.0  -- DOUBLE!
    },
    vortex = {
        dict = 'scr_rcbarry1',
        particle = 'scr_alien_disintegrate',
        scale = 5.0
    },

    -- PHASE 10: Particules MODÉES (feu noir custom!)
    darkFireMod = {
        asset = 'ns_ptfx',  -- Particule MODÉE!
        name = 'fire',
        count = 12,  -- Beaucoup de flammes!
        radius = 2.5,
        scale = 15.0,  -- ÉNORME!
        duration = 4000  -- 4 secondes
    }
}

-- Lumières dynamiques (couleur violette/noire)
Config.Lights = {
    -- Lumière du trail du projectile
    trail = {
        r = 80,   -- Violet foncé
        g = 0,
        b = 120,
        radius = 8.0,
        intensity = 15.0
    },
    -- Lumière d'impact (explosion)
    impact = {
        r = 100,  -- Violet intense
        g = 0,
        b = 150,
        radius = 15.0,
        intensity = 25.0,
        duration = 800  -- Durée du pulse
    }
}

-- Animation
Config.Animation = {
    dict = 'export@nib@wizardsv_avada_kedrava',
    name = 'nib@wizardsv_avada_kedrava',
    flag = 0,
    duration = 3000,
    speedMultiplier = 2.5,
    castDelay = 800  -- Délai avant le tir
}

-- Séquence d'effets (timings en ms)
Config.EffectSequence = {
    -- Charge du lanceur
    auraStart = 0,
    darknessStart = 100,
    wandPowerStart = 300,

    -- Impact
    shockwaveStart = 0,
    mainExplosionStart = 50,
    darkFireStart = 100,
    lightningStart = 150,
    debrisStart = 200,
    persistentSmokeStart = 300,
    residualAuraStart = 500,

    -- Durées
    residualAuraDuration = 8000,  -- 8 secondes d'aura résiduelle
    persistentSmokeDuration = 10000  -- 10 secondes de fumée
}

-- Module registration
Config.Module = {
    id = 'tenebris',
    name = 'Tenebris',
    description = "Invoque les ténèbres primordiales dans une orbe de destruction apocalyptique qui anéantit tout sur son passage dans un brasier de flammes noires et d'éclairs violets.",
    icon = 'skull',
    color = 'purple',
    cooldown = 15000,  -- 15 secondes - c'est un sort ULTIME
    type = 'attack',
    image = 'images/power/dvr_tenebris.png',
    video = '',
    professor = false,
    hidden = true,
}

-- Messages
Config.Messages = {
    noWand = {
        title = 'Tenebris',
        description = 'Vous devez équiper une baguette.',
        type = 'error',
        icon = 'skull'
    },
    notDarkMage = {
        title = 'Tenebris',
        description = 'Seuls les mages noirs peuvent invoquer les ténèbres.',
        type = 'error',
        icon = 'skull'
    }
}

Config.Debug = false

_ENV.Config = Config
