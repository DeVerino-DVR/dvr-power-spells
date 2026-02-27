local Config <const> = {}

Config.Module = {
    id = 'exposare',
    name = 'Exposare',
    description = "Révèle les silhouettes dissimulées et arrache les êtres invisibles au voile qui les cache.",
    icon = 'eye',
    color = 'yellow',
    cooldown = 15000,
    type = 'utility',
    image = 'images/power/tvision.png',
    video = "YOUR_VIDEO_URL_HERE",
    professor = true
}

Config.Animation = {
    dict = 'export@nib@wizardsv_wand_attack_b2',
    name = 'nib@wizardsv_wand_attack_b2',
    flag = 48,
    duration = 2000,
    speedMultiplier = 1.5,
    effectDelay = 1000
}

Config.Reveal = {
    particleDuration = 3000,
    particleScale = 1.0,
    -- Distance de révélation par niveau (en mètres)
    radiusByLevel = {
        [1] = 1.0,
        [2] = 2.0,
        [3] = 3.0,
        [4] = 4.0,
        [5] = 5.0
    }
}

Config.Effects = {
    revealParticles = {
        asset = 'scr_bike_adversary',
        name = 'scr_adversary_weap_smoke',
        scale = 1.2,
        color = {r = 255, g = 255, b = 100},
        alpha = 200
    }
}

Config.Messages = {
    noWand = {
        title = 'Exposare',
        description = 'Vous devez équiper une baguette.',
        type = 'error',
        icon = 'eye'
    }, 
    noHiddenFound = {
        title = 'Exposare',
        description = 'Aucun joueur caché détecté dans la zone.',
        type = 'info',
        icon = 'eye'
    },
    revealSuccess = {
        title = 'Exposare',
        description = 'Joueurs révélés avec succès.',
        type = 'success',
        icon = 'eye'
    },
    revealed = {
        title = 'Exposare',
        description = 'Vous avez été révélé !',
        type = 'warning',
        icon = 'eye'
    }
}

_ENV.Config = Config

