local Config <const> = {}

Config.Debug = true

Config.Module = {
    id = 'aveuglus',
    name = 'Aveuglus',
    description = "Aveugle la cible en obscurcissant complètement sa vision.",
    icon = 'eye-slash',
    color = 'black',
    cooldown = 3000,
    type = 'curse',
    image = 'images/power/dvr_aveuglus.png',
    professor = true,
    animation = {
        dict = "export@nib@wizardsv_wand_attack_smash",
        name = "nib@wizardsv_wand_attack_smash",
        flag = 0,
        duration = 1500,
        speedMultiplier = 1.0
    }
}

Config.Sounds = {
    cast = {
        url = 'YOUR_SOUND_URL_HERE',
        volume = 0.85
    }
}

-- Durées d'aveuglement par niveau (en millisecondes)
Config.BlindDurations = {
    [1] = 10000,  -- 10 secondes
    [2] = 30000,  -- 30 secondes
    [3] = 45000,  -- 45 secondes
    [4] = 60000,  -- 60 secondes
    [5] = -1      -- -1 = toggle (permanent jusqu'à désactivation)
}

Config.TransitionFx = {
    asset = 'ns_ptfx',
    effect = 'fire',
    duration = 2000,
    alpha = 1.0,
    scale = 1.0,
    min_channel = 0,
    attach = 'bone',
    bone = 31086, -- SKEL_Head
    offset = { x = 0.0, y = 0.12, z = 0.0 },
    rot = { x = 0.0, y = 0.0, z = 0.0 }
}

Config.Messages = {
    blinded = {
        title = 'Aveuglus',
        description = 'Vous avez été aveuglé!',
        type = 'error',
        icon = 'eye-slash'
    },
    restored = {
        title = 'Aveuglus',
        description = 'Votre vision est restaurée.',
        type = 'success',
        icon = 'eye'
    }
}

_ENV.Config = Config
