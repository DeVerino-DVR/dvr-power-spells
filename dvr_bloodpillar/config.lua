---@diagnostic disable: undefined-global, trailing-space
local Config <const> = {}

Config.Levitation = {
    duration = 10000,
    height = 3.0,
    riseTime = 1000,
    playerAnimDict = 'skydive@base',
    playerAnimName = 'ragdoll_to_free_idle'
}

Config.Expulsion = {
    force = 15.0,
    projectileSpeed = 60.0,
    projectileModel = 'nib_magic_ray_basic',
    projectileDelay = 500
}

Config.Animation = {
    phase1 = {
        dict = 'export@nib@wizardsv_wand_attack_lightning',
        name = 'nib@wizardsv_wand_attack_lightning',
        flag = 48,
        duration = 1000
    },
    phase2 = {
        dict = 'export@nib@wizardsv_wand_attack_b5',
        name = 'nib@wizardsv_wand_attack_b5',
        flag = 0,
        duration = 2000,
        speedMultiplier = 10.5
    }
}

Config.Effects = {
    aura = {
        asset = 'core',
        effect = 'ent_amb_elec_crackle',
        offset = { x = 0.0, y = 0.0, z = 0.6 },
        scale = 0.9,
        color = { r = 0.6, g = 0.0, b = 0.0 },
        alpha = 120
    },
    pulseLight = {
        color = { r = 200, g = 20, b = 20 },
        radius = 6.0,
        intensity = 10.0,
        period = 1800
    },
    impact = {
        asset = 'core',
        effect = 'blood_stab',
        scale = 8.0
    },
    trail = {
        asset = 'core',
        effect = 'veh_light_red_trail',
        scale = 0.6,
        color = { r = 0.5, g = 0.0, b = 0.0 }
    },
    wand = {
        asset = 'core',
        effect = 'veh_light_clear',
        color = { r = 0.8, g = 0.0, b = 0.0 }
    }
}

Config.Module = {
    id = 'bloodpillar',
    name = 'Blood Pillar',
    description = 'Leve la cible en levitation puis l\'expulse avec une force sanguine devastatrice.',
    icon = 'droplet',
    color = 'red',
    cooldown = 3000,
    type = 'control',
    image = 'images/power/dvr_bloodpillar.png',
    video = '',
    professor = false
}

Config.Damage = {
    perLevel = 50,
    radius = 3.0
}

Config.Sounds = {
    cast = {
        url = '',
        volume = 0.7
    }
}

Config.Messages = {
    noWand = {
        title = 'Blood Pillar',
        description = 'Vous devez equiper une baguette.',
        type = 'error',
        icon = 'droplet'
    },
    noTarget = {
        title = 'Blood Pillar',
        description = 'Vous devez viser un joueur.',
        type = 'warning',
        icon = 'droplet'
    },
    wrongTarget = {
        title = 'Blood Pillar',
        description = 'Vous devez re-viser la cible en levitation.',
        type = 'warning',
        icon = 'droplet'
    }
}

Config.Debug = false

_ENV.Config = Config