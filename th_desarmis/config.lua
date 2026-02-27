---@diagnostic disable: undefined-global, trailing-space
local Config <const> = {}

Config.Spell = {
    id = 'desarmis',
    name = 'Desarmis',
    description = "Arrache l'objet tenu par la cible à son emprise par une impulsion magique précise.",
    icon = 'hand-sparkles',
    color = 'red',
    cooldown = 8000,
    type = 'attack',
    key = nil,
    image = "images/power/th_desarmis.png",
    video = "YOUR_VIDEO_URL_HERE",
    soundType = "3d",
    castTime = 1200,
    animation = {
        dict = "export@nib@wizardsv_wand_attack_3_2",
        name = "nib@wizardsv_wand_attack_3_2",
        flag = 0,
        duration = 1200,
        speedMultiplier = 15.0,
        disarmExtraDelay = 350 -- Délai supplémentaire (ms) après l'animation avant de désarmer la cible
    }
}

Config.MaxDistance = 15.0

Config.Messages = {
    noWand = {
        title = 'Desarmis',
        description = 'Vous devez équiper votre baguette pour lancer ce sort.',
        type = 'error',
        icon = 'wand-magic-sparkles'
    },
    noTarget = {
        title = 'Desarmis',
        description = 'Aucun joueur ciblé.',
        type = 'error',
        icon = 'hand-sparkles'
    },
    targetNoWand = {
        title = 'Desarmis',
        description = 'La cible n\'a pas de baguette équipée.',
        type = 'warning',
        icon = 'hand-sparkles'
    },
    success = {
        title = 'Desarmis',
        description = 'Vous avez désarmé votre cible.',
        type = 'success',
        icon = 'hand-sparkles'
    },
    disarmed = {
        title = 'Desarmis',
        description = 'Vous avez été désarmé ! Votre baguette a été rangée.',
        type = 'error',
        icon = 'hand-sparkles'
    },
    failed = {
        title = 'Desarmis',
        description = 'Le sort a échoué.',
        type = 'error',
        icon = 'hand-sparkles'
    }
}

Config.Effect = {
    projectile = {
        asset = 'core',
        name = 'veh_light_red_trail',
        scale = 2.0,
        speed = 15.0
    },
    impact = {
        asset = 'core',
        name = 'exp_grd_grenade_lods',
        scale = 1.0,
        duration = 1000
    },
    light = {
        color = { r = 255, g = 50, b = 50 },
        distance = 5.0,
        brightness = 2.5,
        duration = 800
    },
    camera = {
        shake = 'SMALL_EXPLOSION_SHAKE',
        amplitude = 0.15
    }
}

Config.Debug = false

_ENV.Config = Config
