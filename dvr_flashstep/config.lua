---@diagnostic disable: undefined-global, trailing-space
local Config <const> = {}

Config.Dash = {
    maxDistance = 28.0,
    cooldown = 6000,
    duration = 350,       -- ms of travel (visual only)
    shakeDistance = 25.0,
    shakeIntensity = 0.6
}

Config.FX = {
    trail = {
        dict = 'core',
        particle = 'veh_exhaust_spacecraft',
        scale = 0.6
    },
    arrival = {
        dict = 'core',
        particle = 'exp_water',
        scale = 1.2
    },
    electric = {
        dict = 'core',
        particle = 'ent_brk_sparking_wires',
        scale = 1.0
    },
    wand = {
        dict = 'core',
        particle = 'ent_amb_tnl_bubbles_sml',
        scale = 0.9
    },
    sound = ''
}

Config.Module = {
    id = 'flashstep',
    name = 'Flashstep',
    description = "Condense la magie en une impulsion fulgurante projetant le lanceur vers un point choisi.",
    icon = 'bolt',
    color = 'blue',
    cooldown = 6000,
    type = 'utility',
    image = 'images/power/dvr_flashstep.png',
    video = "YOUR_VIDEO_URL_HERE",
    professor = true
}

Config.Messages = {
    noWand = {
        title = 'Flashstep',
        description = 'Vous devez équiper une baguette.',
        type = 'error',
        icon = 'bolt'
    },
    noTarget = {
        title = 'Flashstep',
        description = 'Destination invalide.',
        type = 'warning',
        icon = 'bolt'
    }
}

Config.Debug = false

_ENV.Config = Config
