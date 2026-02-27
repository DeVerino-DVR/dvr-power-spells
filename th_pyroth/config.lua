---@diagnostic disable: undefined-global, trailing-space
local Config <const> = {}

-- Configuration du projectile (orbe rouge)
Config.Projectile = {
    model = 'nib_magic_ray_basic',
    speed = 45.0,
    maxDistance = 1000.0,
    handBone = 28422,
    trailParticle = 'veh_light_red_trail',
    trailScale = 0.55
}

-- Configuration de l'animation de lancement
Config.Animation = {
    dict = 'export@nib@wizardsv_avada_kedrava',
    name = 'nib@wizardsv_avada_kedrava',
    flag = 0,
    duration = 3000,
    speedMultiplier = 3.0,
    propsDelay = 2100
}

-- Configuration du module de sort
Config.Module = {
    id = 'pyroth',
    name = 'Pyroth',
    description = "Sortilège interdit qui fait jaillir des flammes brutales du sol à l'impact, brûlant la zone et enflammant les cibles.",
    icon = 'fire',
    color = 'red',
    cooldown = 4000,
    type = 'attack',
    key = nil,
    image = 'images/power/infshock.png',
    video = '',
    professor = false
}

-- Configuration des flammes au sol par niveau
-- Niveau 1-5 avec progression des dégâts, durée et rayon
Config.FlameSettings = {
    -- Niveau 1: Rayon réduit, dégâts légers, durée courte (PAS de flammes extérieures)
    [1] = {
        radius = 2.0,
        duration = 3000,
        burnDuration = 2000,
        flameScale = 0.8,
        innerFlames = 4,
        outerFlames = 0  -- Pas de flammes autour
    },
    -- Niveau 2: Modéré (PAS de flammes extérieures)
    [2] = {
        radius = 2.8,
        duration = 4000,
        burnDuration = 3000,
        flameScale = 1.0,
        innerFlames = 6,
        outerFlames = 0  -- Pas de flammes autour
    },
    -- Niveau 3: Modéré avancé (PAS de flammes extérieures)
    [3] = {
        radius = 3.5,
        duration = 5000,
        burnDuration = 4000,
        flameScale = 1.2,
        innerFlames = 8,
        outerFlames = 0  -- Pas de flammes autour
    },
    -- Niveau 4: Avancé (flammes extérieures activées)
    [4] = {
        radius = 4.2,
        duration = 6000,
        burnDuration = 5000,
        flameScale = 1.4,
        innerFlames = 10,
        outerFlames = 20
    },
    -- Niveau 5: Maximal (flammes extérieures activées)
    [5] = {
        radius = 5.0,
        duration = 8000,
        burnDuration = 6000,
        flameScale = 1.6,
        innerFlames = 12,
        outerFlames = 24
    }
}

-- Configuration des particules de flammes
Config.FlameParticles = {
    -- Particule principale: flammes jaillissant du sol
    primary = {
        asset = 'core',
        name = 'ent_sht_flame',
        offsetZ = 0.0
    },
    -- Particule secondaire: faisceau de feu
    secondary = {
        asset = 'core',
        name = 'ent_amb_fbi_fire_beam',
        offsetZ = 0.2
    },
    -- Particule de fumée
    smoke = {
        asset = 'core',
        name = 'exp_grd_bzgas_smoke',
        scale = 0.6,
        offsetZ = 0.5
    }
}

-- Configuration des dégâts (utilise ApplySpellDamage de th_power)
Config.Damage = {
    perLevel = 30,             -- Dégâts par niveau pour ApplySpellDamage
    protectionDuration = 500,  -- Durée de protection en ms
    damageInterval = 3000      -- Intervalle de dégâts continus (3 secondes)
}

-- Son d'impact (lourd et brûlant, pas aigu)
Config.ImpactSound = {
    url = 'YOUR_SOUND_URL_HERE',
    volume = 0.8
}

-- Messages de notification
Config.Messages = {
    noWand = {
        title = 'Pyroth',
        description = 'Vous avez besoin d\'une baguette pour utiliser ce sort.',
        type = 'error',
        icon = 'fire'
    },
    noTarget = {
        title = 'Pyroth',
        description = 'Aucune surface valide détectée.',
        type = 'warning',
        icon = 'fire'
    }
}

Config.Debug = false

_ENV.Config = Config
