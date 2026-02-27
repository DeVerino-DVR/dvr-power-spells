---@diagnostic disable: undefined-global, trailing-space
local Config <const> = {}

Config.Spell = {
    id = 'silencis',
    name = 'Silencis',
    description = "Scelle la voix de la cible, l’empêchant de prononcer le moindre son.",
    icon = 'volume-xmark',
    color = 'purple',
    cooldown = 15000,
    type = 'control',
    key = nil,
    image = "images/power/strangle.png",
    soundType = "3d",
    castTime = 1200,
    animation = {
        dict = 'export@nib@wizardsv_wand_attack_b2',
        name = 'nib@wizardsv_wand_attack_b2',
        flag = 48,
        duration = 1200
    }
}

Config.DurationByLevel = {
    [1] = 10,   -- Niveau 1 : 10 secondes
    [2] = 15,   -- Niveau 2 : 15 secondes
    [3] = 20,   -- Niveau 3 : 20 secondes
    [4] = 25,   -- Niveau 4 : 25 secondes
    [5] = 30    -- Niveau 5 : 30 secondes
}

Config.MaxDistance = 15.0

Config.Messages = {
    noWand = {
        title = 'Silencis',
        description = 'Vous devez équiper votre baguette pour lancer ce sort.',
        type = 'error',
        icon = 'wand-magic-sparkles'
    },
    noTarget = {
        title = 'Silencis',
        description = 'Aucun joueur ciblé.',
        type = 'error',
        icon = 'volume-xmark'
    },
    success = {
        title = 'Silencis',
        description = 'Vous avez coupé la voix de votre cible.',
        type = 'success',
        icon = 'volume-xmark'
    },
    muted = {
        title = 'Silencis',
        description = 'Votre voix a été coupée par un sort.',
        type = 'warning',
        icon = 'volume-xmark'
    },
    unmuted = {
        title = 'Silencis',
        description = 'Votre voix a été restaurée.',
        type = 'info',
        icon = 'volume-high'
    }
}

_ENV.Config = Config

