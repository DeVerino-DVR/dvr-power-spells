---@diagnostic disable: undefined-global, trailing-space
local Config <const> = {}

Config.Teleport = {
    maxDistance = 60.0,
    verticalOffset = 0.0
}

Config.Fx = {
    path = {
        dict = "core",
        particlesMain = "veh_air_turbulance_water",
        particlesSecondary = "ent_amb_tnl_bubbles_sml",
        steps = 24,
        radius = 0.4,
        scaleMain = 0.35,
        scaleSecondary = 0.2
    },
    arrival = {
        dict = "core",
        splash = "exp_water",
        bubble = "ent_amb_tnl_bubbles_sml",
        fountain = "ent_amb_fountain_pour",
        scale = 1.4
    },
    wand = {
        dict = "core",
        particle = "ent_amb_tnl_bubbles_sml",
        scale = 0.8,
        alpha = 1.0
    }
}

Config.Module = {
    id = 'aquamens',
    name = 'Aquamens',
    description = "Invoque une vague mouvante d’eau pure sur laquelle le lanceur glisse brièvement.",
    icon = 'water',
    color = 'blue',
    cooldown = 6000,
    type = 'utility',
    key = '5',
    image = 'images/power/th_aquamens.png',
    video = "YOUR_VIDEO_URL_HERE",
    professor = true
}

Config.Messages = {
    noWand = {
        title = 'Aquamens',
        description = 'Vous devez équiper une baguette.',
        type = 'error',
        icon = 'water'
    },
    noTarget = {
        title = 'Aquamens',
        description = 'Destination invalide.',
        type = 'warning',
        icon = 'water'
    }
}

Config.Debug = false

_ENV.Config = Config    
