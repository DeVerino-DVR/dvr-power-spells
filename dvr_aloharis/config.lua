---@diagnostic disable: undefined-global, trailing-space
local Config <const> = {}

Config.Spell = {
    id = 'aloharis',
    name = 'Aloharis',
    description = "Contraint une serrure à céder sous la pression d’une impulsion arcanique brute.",
    icon = 'key',
    color = 'yellow',
    cooldown = 7000,
    type = 'utility',
    key = nil,
    image = "images/power/kamebig.png",
    video = "YOUR_VIDEO_URL_HERE",
    sound = 'YOUR_SOUND_URL_HERE',
    soundType = "3d",
    castTime = 2200,
    animation = {
        dict = 'export@nib@wizardsv_wand_attack_1',
        name = 'nib@wizardsv_wand_attack_1',
        flag = 0,
        duration = 2200,
        speedMultiplier = 3.0,
    }
}

Config.MaxDistance = 10.0

Config.Blacklist = {
    ids = {},
    names = {}
}

Config.Messages = {
    noWand = {
        title = 'Aloharis',
        description = 'Vous devez équiper votre baguette pour lancer ce sort.',
        type = 'error',
        icon = 'wand-magic-sparkles'
    },
    noDoor = {
        title = 'Aloharis',
        description = 'Aucune porte verrouillée n\'est ciblée.',
        type = 'error',
        icon = 'key'
    },
    blacklisted = {
        title = 'Aloharis',
        description = 'Cette porte résiste à la magie.',
        type = 'error',
        icon = 'key'
    },
    alreadyUnlocked = {
        title = 'Aloharis',
        description = 'Cette porte est déjà déverrouillée.',
        type = 'warning',
        icon = 'unlock'
    },
    unlocked = {
        title = 'Aloharis',
        description = 'Le sort a déverrouillé la porte.',
        type = 'success',
        icon = 'unlock'
    },
    failed = {
        title = 'Aloharis',
        description = 'Impossible de déverrouiller cette porte.',
        type = 'error',
        icon = 'lock'
    }
}

Config.PreEffect = {
    duration = 2400,
    zOffset = 1.05,
    beamColor = { r = 150, g = 220, b = 255, a = 210 },
    light = {
        color = { r = 120, g = 210, b = 255 },
        distance = 6.5,
        brightness = 2.9
    },
    marker = {
        type = 28,
        scaleX = 0.35,
        scaleY = 0.35,
        scaleZ = 0.35,
        colorR = 150,
        colorG = 220,
        colorB = 255,
        colorA = 185,
        rotationSpeed = 7.0,
        zOffset = -0.1
    },
    outline = {
        color = { r = 130, g = 220, b = 255, a = 230 }
    }
}

Config.Effect = {
    burst = {
        rings = {
            asset = 'scr_rcbarry2',
            name = 'scr_clown_appears',
            scale = 1.5,
            zOffset = 1.1,
            duration = 2400
        },
        shockwave = {
            asset = 'scr_xs_celebration',
            name = 'scr_xs_confetti_burst',
            scale = 1.1,
            zOffset = 1.05
        },
        sparks = {
            asset = 'scr_xs_celebration',
            name = 'scr_xs_x16_sparkle_trail',
            scale = 0.9,
            zOffset = 1.2,
            count = 4,
            delay = 110
        }
    },
    lingering = {
        asset = 'core',
        name = 'ent_amb_elec_crackle',
        scale = 0.9,
        duration = 1800,
        zOffset = 1.0
    },
    light = {
        color = { r = 150, g = 230, b = 255 },
        distance = 9.0,
        brightness = 4.2,
        duration = 1600,
        zOffset = 1.05
    },
    outline = {
        duration = 2200,
        color = { r = 160, g = 230, b = 255, a = 255 },
        pulse = true
    },
    sound = {
        name = 'SELECT',
        set = 'HUD_FRONTEND_MP_RP_GAIN',
        useFrontend = true
    },
    camera = {
        shake = 'SMALL_EXPLOSION_SHAKE',
        amplitude = 0.15,
        postfx = 'SuccessNeutral',
        postfxDuration = 1400
    }
}

_ENV.Config = Config
