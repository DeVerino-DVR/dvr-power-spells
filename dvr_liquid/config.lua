local Config <const> = {}

Config.Module = {
    id = 'liquid',
    name = 'Liquid',
    description = 'Prend une forme liquide pour traverser les menaces et frapper soudainement.',
    icon = 'water',
    color = 'blue',
    cooldown = 15000,
    type = 'utility',
    selfCast = true,
    image = 'images/power/dvr_liquid.png',
    professor = false,
    hidden = true,
    isWand = false
}

Config.Effect = {
    duration = 20000,
    glideSpeed = 6.0,
    burstRange = 35.0,
    burstForce = 45.0,
    burstCooldown = 1200,
    alpha = 120,
    remoteAlpha = 160,
    invincible = true
}

Config.Levels = {
    [1] = { duration = 30000 },
    [2] = { duration = 60000 },
    [3] = { duration = 300000 },
    [4] = { duration = 600000 },
    [5] = { duration = 0 } -- 0 or less = infinite
}

Config.Messages = {
    noWand = {
        title = 'Liquid',
        description = 'Vous devez équiper une baguette.',
        type = 'error',
        icon = 'water'
    }
}

_ENV.Config = Config