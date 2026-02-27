local Config <const> = {}

Config.Debug = true

Config.Module = {
    id = 'snailus',
    name = 'Snailus',
    description = "Ralentit considérablement les mouvements de la cible.",
    icon = 'person-walking',
    color = 'blue',
    cooldown = 3000,
    type = 'curse',
    image = 'images/power/dvr_snailus.png',
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

-- Multiplicateurs de vitesse par niveau (1.0 = vitesse normale, 0.5 = 50% de vitesse)
Config.SpeedMultipliers = {
    [1] = 0.85,  -- Léger ralentissement (85% de la vitesse normale)
    [2] = 0.65,  -- Ralentissement moyen (65% de la vitesse normale)
    [3] = 0.45,  -- Ralentissement important (45% de la vitesse normale)
    [4] = 0.25,  -- Ralentissement majeur (25% de la vitesse normale)
    [5] = 0.25   -- Toggle (même ralentissement que niveau 4)
}

-- Durées de ralentissement par niveau (en millisecondes)
Config.SlowDurations = {
    [1] = 15000,  -- 15 secondes
    [2] = 20000,  -- 20 secondes
    [3] = 30000,  -- 30 secondes
    [4] = 45000,  -- 45 secondes
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
    bone = 11816, -- SKEL_R_Foot
    offset = { x = 0.0, y = 0.0, z = 0.0 },
    rot = { x = 0.0, y = 0.0, z = 0.0 }
}

Config.Messages = {
    slowed = {
        title = 'Snailus',
        description = 'Vous avez été ralenti!',
        type = 'error',
        icon = 'person-walking'
    },
    restored = {
        title = 'Snailus',
        description = 'Votre vitesse est restaurée.',
        type = 'success',
        icon = 'person-running'
    }
}

_ENV.Config = Config
