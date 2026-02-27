---@diagnostic disable: undefined-global, trailing-space
local Config <const> = {}

Config.Spell = {
    id = 'oublitix',
    name = 'Oublitix',
    description = "Altère l’esprit de la cible, effaçant ses souvenirs récents et brouillant le fil du temps.",
    icon = 'brain',
    color = 'purple',
    cooldown = 30000,
    type = 'control',
    key = nil,
    image = "images/power/tport.png",
    video = "YOUR_VIDEO_URL_HERE",
    soundType = "3d",
    castTime = 1200,
    animation = {
        -- Animation basée sur dvr_animarion
        dict = 'gestures@m@standing@casual',
        name = 'gesture_bring_it_on',
        flag = 48,
        duration = 2000,
        propsDelay = 800
    }
}

-- Minutes de rollback par niveau (1-5 minutes)
Config.RollbackMinutesByLevel = {
    [1] = 1,   -- Niveau 1 : 1 minute
    [2] = 2,   -- Niveau 2 : 2 minutes
    [3] = 3,   -- Niveau 3 : 3 minutes
    [4] = 4,   -- Niveau 4 : 4 minutes
    [5] = 5    -- Niveau 5 : 5 minutes
}

-- Durée de l'écran noir en secondes
Config.BlackScreenDuration = 15

-- Intervalle de sauvegarde de position (en millisecondes)
Config.PositionSaveInterval = 60000 -- 1 minute = 60000ms

-- Nombre maximum de positions sauvegardées (5 minutes)
Config.MaxPositionHistory = 5

Config.Projectile = {
    model = 'wizardsV_nib_avadakedavra_ray',
    speed = 120.0,
    duration = 600,
    handBone = 28422
}

Config.Messages = {
    noWand = {
        title = 'Oublitix',
        description = 'Vous devez équiper votre baguette pour lancer ce sort.',
        type = 'error',
        icon = 'wand-magic-sparkles'
    },
    success = {
        title = 'Oublitix',
        description = 'Sort lancé avec succès.',
        type = 'success',
        icon = 'brain'
    },
    targetAffected = {
        title = 'Oublitix',
        description = 'Vous avez été affecté par Oublitix.',
        type = 'warning',
        icon = 'brain'
    },
    forgetMessage = 'Vous avez subi l\'effet Oublitix. Vous devez oublier les %d dernière(s) minute(s), vous avez été téléporté à votre position passée et vous ressentez des douleurs...'
}

Config.Effects = {
    wandParticles = {
        asset = 'core',
        name = 'veh_light_clear',
        scale = 0.5,
        color = {r = 0.4, g = 0.0, b = 0.8} -- Violet pour l'effet d'oubli
    },
    
    projectileTrail = {
        asset = 'core',
        name = 'proj_flare_trail',
        scale = 1.0,
        color = {r = 0.6, g = 0.0, b = 1.0} -- Violet foncé
    },
    
    teleportEffect = {
        asset = 'scr_rcbarry1',
        name = 'scr_alien_teleport',
        scale = 1.5,
        duration = 2000
    }
}

Config.SleepEmote = {
    dict = 'timetable@tracy@sleep@',
    name = 'base',
    flag = 1 -- Loop
}

Config.Debug = false

_ENV.Config = Config

return Config

