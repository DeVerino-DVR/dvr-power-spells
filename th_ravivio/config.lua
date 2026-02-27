---@diagnostic disable: undefined-global, trailing-space
local Config <const> = {}

Config.Projectile = {
    model = 'wizardsV_nib_avadakedavra_ray',
    speed = 100.0,
    duration = 800,
    maxDistance = 1000.0,
    handBone = 28422
}

Config.Animation = {
    dict = "export@nib@wizardsv_wand_attack_2",
    name = "nib@wizardsv_wand_attack_2",
    flag = 0,
    duration = 2000,
    speedMultiplier = 4.0,
    propsDelay = 1500
}

Config.ReviveSettings = {
    maxDistance = 100.0,
    requireMagicPowder = false
}

Config.Module = {
    id = 'ravivio',
    name = 'Ravivio',
    description = "Rétablit le lien entre l’âme et le corps, ramenant une cible à la vie.",
    icon = 'heart-pulse',
    color = 'cyan',
    cooldown = 10000,
    type = 'support',
    image = 'images/power/healexp.png',
    video = "YOUR_VIDEO_URL_HERE",
    professor = false
}

Config.Effects = {
    wandParticles = {
        asset = 'core',
        name = 'veh_light_clear',
        scale = 0.5,
        color = {r = 0.0, g = 1.0, b = 1.0}
    },

    reviveParticles = {
        asset = 'scr_rcbarry2',
        name = 'scr_rcbarry2_vine_green',
        scale = 2.0,
        duration = 3000,
        color = {r = 0.0, g = 1.0, b = 1.0}
    }
}

Config.Messages = {
    noWand = {
        title = 'Ravivio',
        description = 'Vous devez équiper une baguette.',
        type = 'error',
        icon = 'heart-pulse'
    },
    noMagicPowder = {
        title = 'Ravivio',
        description = 'Vous n\'avez pas de poudre magique.',
        type = 'error',
        icon = 'flask'
    },
    noDeadPlayer = {
        title = 'Ravivio',
        description = 'Aucun joueur mort à proximité.',
        type = 'error',
        icon = 'skull'
    },
    success = {
        title = 'Ravivio',
        description = 'Vous avez réanimé {target}.',
        type = 'success',
        icon = 'heart-pulse'
    },
    revived = {
        title = 'Ravivio',
        description = 'Vous avez été réanimé par {caster}.',
        type = 'success',
        icon = 'heart-pulse'
    }
}

Config.Debug = false

_ENV.Config = Config
