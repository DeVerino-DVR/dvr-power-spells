---@diagnostic disable: undefined-global, trailing-space
local Config <const> = {}

Config.Projectile = {
    model = 'wizardsV_nib_avadakedavra_ray',
    speed = 80.0,
    maxDistance = 1000.0,
    handBone = 28422
}

Config.Animation = {
    propsDelay = 1500
}

Config.Module = {
    id = 'coagulis',
    name = 'Coagulis',
    description = "Stabilise le Flux sanguin et referme les plaies causées par Sanguiris.",
    icon = 'bandage',
    color = 'green',
    cooldown = 6000,
    type = 'support',
    key = nil,
    image = 'images/power/cloud.png',
    professor = true
}

Config.Messages = {
    noWand = {
        title = 'Coagulis',
        description = 'Vous devez équiper une baguette.',
        type = 'error',
        icon = 'bandage'
    }
}

Config.Debug = false

_ENV.Config = Config
