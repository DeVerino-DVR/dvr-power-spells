---@diagnostic disable: undefined-global, trailing-space
local Config <const> = {}

Config.Animation = {
    dict = 'export@nib@wizardsv_wand_attack_3',
    name = 'nib@wizardsv_wand_attack_3',
    flag = 0,
    duration = 3000,
    speedMultiplier = 4.6
}

Config.Module = {
    id = 'abyrion',
    name = 'Abyrion',
    description = "Sortilège interdit qui éveille autour du lanceur un anneau de feu impur, mêlant braises noires et lueurs verdâtres, érigeant une barrière vivante qui châtie les intrus.",
    icon = 'fire',
    color = 'green',
    cooldown = 20000,
    type = 'defense',
    image = 'images/power/th_abyrion.png',
    video = "YOUR_VIDEO_URL_HERE",
    professor = false,
    noWandTrail = true,
}

Config.Sounds = {
    cast = 'YOUR_SOUND_URL_HERE',
    fire = ''
}

Config.FlameColors = {
    primary = { r = 0.0, g = 0.8, b = 0.2 },
    secondary = { r = 0.0, g = 0.0, b = 0.0 }
}

Config.Levels = {
    [1] = {
        radius = 3.5,
        flameHeight = 1.0,
        flameScale = 0.9,
        flameCount = 20,
        damage = 4,
        burnDamage = 12,
        burnDuration = 3000,
        duration = 8000,
        tickRate = 800
    },
    [2] = {
        radius = 4.0,
        flameHeight = 1.3,
        flameScale = 1.0,
        flameCount = 24,
        damage = 6,
        burnDamage = 16,
        burnDuration = 4000,
        duration = 10000,
        tickRate = 800
    },
    [3] = {
        radius = 4.5,
        flameHeight = 1.8,
        flameScale = 1.2,
        flameCount = 28,
        damage = 8,
        burnDamage = 20,
        burnDuration = 5000,
        duration = 12000,
        tickRate = 700
    },
    [4] = {
        radius = 5.0,
        flameHeight = 2.2,
        flameScale = 1.4,
        flameCount = 32,
        damage = 10,
        burnDamage = 25,
        burnDuration = 6000,
        duration = 15000,
        tickRate = 700
    },
    [5] = {
        radius = 6.0,
        flameHeight = 3.5,
        flameScale = 2.2,
        flameCount = 40,
        damage = 12,
        burnDamage = 32,
        burnDuration = 8000,
        duration = 20000,
        tickRate = 600
    }
}

Config.Effects = {
    flame = {
        asset = 'ns_ptfx',
        name = 'fire',
        baseScale = 1.0
    },
    smoke = {
        asset = 'core',
        name = 'exp_grd_bzgas_smoke',
        scale = 0.6
    },
    glow = {
        asset = 'core',
        name = 'veh_light_clear',
        scale = 0.4
    },
    sparks = {
        asset = 'core',
        name = 'ent_brk_sparking_wires',
        scale = 0.5
    }
}

Config.Light = {
    color = { r = 0, g = 180, b = 50 },
    radius = 8.0,
    intensity = 3.0
}

Config.Barrier = {
    damageThickness = 0.8,
    collisionHeight = 3.0
}

Config.Messages = {
    noWand = {
        title = 'Abyrion',
        description = 'Vous devez equiper une baguette.',
        type = 'error',
        icon = 'fire'
    },
    cast = {
        title = 'Abyrion',
        description = 'Le cercle de flammes vous entoure.',
        type = 'success',
        icon = 'fire'
    }
}

Config.Debug = false

_ENV.Config = Config
