local Config <const> = {}

Config.Module = {
    id = 'rivilus',
    name = 'Rivilus',
    description = "Fait vibrer le Flux et révèle toute entité imprégnée de magie à proximité.",
    icon = 'eye',
    color = 'blue',
    cooldown = 12000,
    type = 'utility',
    image = 'images/power/nvision.png',
    video = "YOUR_VIDEO_URL_HERE",
    professor = true
}

Config.Scan = {
    baseRadius = 30.0,
    perLevel = 3.0,
    maxRadius = 55.0,
    duration = 8000,
    maxEntities = 50
}

Config.Outline = {
    players = { r = 90, g = 180, b = 255, a = 230 },
    peds = { r = 90, g = 180, b = 255, a = 230 },
    objects = { r = 220, g = 200, b = 120, a = 230 },
    vehicles = { r = 255, g = 180, b = 120, a = 230 }
}

Config.Messages = {
    noWand = {
        title = 'Rivilus',
        description = 'Vous devez équiper une baguette.',
        type = 'error',
        icon = 'eye'
    },
    nothingFound = {
        title = 'Rivilus',
        description = 'Aucune entité détectée à proximité.',
        type = 'info',
        icon = 'eye'
    }
}

Config.Debug = false

_ENV.Config = Config