---@diagnostic disable: undefined-global, trailing-space
local Config <const> = {}

Config.Duration = 30000 -- Durée par défaut (ms) utilisée pour certains niveaux

Config.Module = {
    id = 'obscura',
    name = 'Obscura',
    description = "Étouffe la lumière ambiante et plonge la zone dans une obscurité surnaturelle.",
    icon = 'moon',
    color = 'black',
    cooldown = 10000,
    type = 'utility',
    image = 'images/power/dvr_obscura.png',
    video = "YOUR_VIDEO_URL_HERE",
    professor = true
}

Config.Messages = {
    noWand = {
        title = 'Obscura',
        description = 'Vous devez équiper une baguette.',
        type = 'error',
        icon = 'moon'
    }
}

Config.Debug = false

_ENV.Config = Config
