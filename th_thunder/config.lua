---@diagnostic disable: undefined-global, trailing-space
local Config <const> = {}

Config.Projectile = {
    speed = 45.0,
    maxDistance = 999999.0,
    -- Delais (ms) depuis le début de l'animation pour déclencher chaque éclair.
    shotTimings = { 300, 1100, 1900 }
}

Config.Ragdoll = {
    baseDuration = 2000,
    perLevel = 350,
    maxDuration = 5000
}

Config.Damage = {
    perLevel = 110,      -- Damage per spell level (Level 1 = 50, Level 2 = 100, etc.)
    radius = 5.0        -- Damage radius in meters from lightning strike center
}

Config.Effects = {
    props = {
        boltSmall = 'wizardsV_nib_wizards_lightning_boltSmall',
        sub = 'wizardsV_nib_wizards_lightning_sub2',
        main = 'wizardsV_nib_wizards_lightning_main'
    },
    particle = {
        dict = 'scr_bike_adversary',
        name = 'scr_adversary_gunsmith_weap_smoke',
        alpha = 1.0,
        offset = { x = 0.4, y = 0.0, zstart = 0.0, zend = 0.05 },
        rot = { x = 0.0, y = 0.0, z = 0.0 }
    },
    shake = {
        maxDistance = math.huge,
        intensity = 0.6
    }
}

Config.Sounds = {
    cast = {
        url = 'YOUR_SOUND_URL_HERE',
        volume = 0.85,
        shake = {
            maxDistance = 25.0,
            intensity = 1.2 -- stronger shake during cast (~4x previous minimum)
        }
    },
    launch = {
        url = '',
        volume = 0.9
    }
}

Config.Module = {
    id = 'thunder',
    name = 'Thunder',
    description = "Déchaîne une tempête d’éclairs frappant le sol dans un fracas dévastateur.",
    icon = 'bolt',
    color = 'blue',
    cooldown = 4500,
    type = 'attack',
    image = 'images/power/th_thunder.png',
    video = 'YOUR_VIDEO_URL_HERE',
    professor = true,
    animation = {
        dict = "export@nib@wizardsv_wand_attack_smash",
        name = "nib@wizardsv_wand_attack_smash",
        flag = 0,
        duration = 3000,
        speedMultiplier = 1.5
    }
}

Config.Messages = {
    noWand = {
        title = 'Thunder',
        description = 'Vous devez équiper une baguette.',
        type = 'error',
        icon = 'bolt'
    }
}

Config.Debug = false

_ENV.Config = Config    
