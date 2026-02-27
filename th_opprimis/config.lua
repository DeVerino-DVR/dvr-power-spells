---@diagnostic disable: undefined-global, trailing-space
local Config <const> = {}

Config.Spell = {
    id = 'opprimis',
    name = 'Opprimis',
    description = "Entrave magiquement la cible, l'immobilisant avec des liens magiques.",
    icon = 'link',
    color = 'gray',
    cooldown = 20000,
    type = 'control',
    key = nil,
    image = "images/power/th_opprimis.png",
    soundType = "3d",
    castTime = 1500,
    animation = {
        dict = 'export@nib@wizardsv_wand_attack_b2',
        name = 'nib@wizardsv_wand_attack_b2',
        flag = 0,
        duration = 1500
    }
}

-- Duree des menottes par niveau (en secondes)
Config.DurationByLevel = {
    [0] = 30,   -- Niveau 0 : 30 secondes
    [1] = 45,   -- Niveau 1 : 45 secondes
    [2] = 60,   -- Niveau 2 : 60 secondes
    [3] = 90,   -- Niveau 3 : 90 secondes
    [4] = 120,  -- Niveau 4 : 120 secondes
    [5] = 180   -- Niveau 5 : 180 secondes (3 minutes)
}

-- Distance maximum pour lancer le sort
Config.MaxDistance = 10.0

-- Configuration des animations de menottage
Config.Animations = {
    cuffed = {
        dict = 'anim@move_m@prisoner_cuffed',
        name = 'idle',
        flag = 49
    }
}

Config.Messages = {
    noWand = {
        title = 'Opprimis',
        description = 'Vous devez equiper votre baguette pour lancer ce sort.',
        type = 'error',
        icon = 'wand-magic-sparkles'
    },
    noTarget = {
        title = 'Opprimis',
        description = 'Aucun joueur cible.',
        type = 'error',
        icon = 'link'
    },
    tooFar = {
        title = 'Opprimis',
        description = 'La cible est trop loin.',
        type = 'error',
        icon = 'link'
    },
    success = {
        title = 'Opprimis',
        description = 'Vous avez entravé votre cible.',
        type = 'success',
        icon = 'link'
    },
    handcuffed = {
        title = 'Opprimis',
        description = 'Vous avez été entravé par un sort.',
        type = 'warning',
        icon = 'link'
    },
    released = {
        title = 'Opprimis',
        description = 'Vos liens magiques se sont dissipés.',
        type = 'info',
        icon = 'link-slash'
    },
    releaseSuccess = {
        title = 'Opprimis',
        description = 'Vous avez libéré votre cible.',
        type = 'success',
        icon = 'link-slash'
    }
}

_ENV.Config = Config
