---@diagnostic disable: undefined-global, trailing-space
local Config <const> = {}

Config.Projectile = {
    speed = 80.0,
    maxDistance = 1000.0
}

Config.Ragdoll = {
    baseDuration = 3000,
    perLevel = 400,
    maxDuration = 6000
}

Config.Module = {
    id = 'juliusis',
    name = 'Juliusis',
    description = 'Lance un sort qui fait tomber la cible au sol.',
    icon = 'hand-point-down',
    color = 'blue',
    cooldown = 5000,
    type = 'control',
    image = 'images/power/dominio.png',
    professor = false,
    hidden = true   
}

Config.Messages = {
    noWand = {
        title = 'Juliusis',
        description = 'Vous devez équiper une baguette.',
        type = 'error',
        icon = 'hand-point-down'
    }
}

Config.Debug = false

_ENV.Config = Config
