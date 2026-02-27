---@diagnostic disable: undefined-global, trailing-space
local Config <const> = {}

Config.Raycast = {
    maxDistance = 60.0
}

Config.Smoke = {
    dict = "core",
    particle = "ent_amb_fbi_door_smoke",
    scale = 1.6,
    duration = 3000
}

Config.Module = {
    id = 'fumania',
    name = 'Fumania',
    description = "Distord l’espace et échange instantanément la position du lanceur avec celle d’une cible.",
    icon = 'smoke',
    color = 'purple',
    cooldown = 8000,
    type = 'utility',
    key = '5',
    image = 'images/power/th_fumania.png',
    video = "YOUR_VIDEO_URL_HERE",
    professor = true
}

Config.Messages = {
    noWand = {
        title = 'Fumania',
        description = 'Vous devez équiper une baguette.',
        type = 'error',
        icon = 'smoke'
    },
    noTarget = {
        title = 'Fumania',
        description = 'Aucune cible valide.',
        type = 'warning',
        icon = 'smoke'
    }
}

Config.Debug = false

_ENV.Config = Config    
