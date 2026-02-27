local Config <const> = {}

Config.Module = {
    id = 'hiddenis',
    name = 'Hiddenis',
    description = "Enveloppe le corps d’un voile illusoire rendant invisible le lanceur ou une cible vivante.",
    icon = 'user-ninja',
    color = 'purple',
    cooldown = 20000,
    type = 'utility',
    image = 'images/power/shadowform.png',
    video = "YOUR_VIDEO_URL_HERE",
    professor = true
}

Config.Animation = {
    dict = 'export@nib@wizardsv_wand_attack_b2',
    name = 'nib@wizardsv_wand_attack_b2',
    flag = 0,
    duration = 2200,
    speedMultiplier = 1.5,
    effectDelay = 700
}

Config.Effect = {
    duration = 15000,
    alpha = 51 -- 20% visible localement
}

Config.Levels = {
    [1] = { duration = 12000, alpha = 200, broadcast = 'self' },
    [2] = { duration = 13500, alpha = 155, broadcast = 'self' },
    [3] = { duration = 15000, alpha = 100, broadcast = 'self' },
    [4] = { duration = 16500, alpha = 100, broadcast = 'flicker', flickerInterval = 1500, flickerChance = 0.55 },
    [5] = { duration = 0, alpha = 51, broadcast = 'full', infinite = true }
}

Config.Messages = {
    noWand = {
        title = 'Hiddenis',
        description = 'Vous devez équiper une baguette.',
        type = 'error',
        icon = 'user-ninja'
    }
}

_ENV.Config = Config
