---@diagnostic disable: undefined-global, trailing-space
local Config <const> = {}

Config.Raycast = {
    maxDistance = 60.0
}

-- Config.WandFx = {
--     dict = "core",
--     particle = "ent_amb_fbi_door_smoke",
--     scale = 1.6,
--     duration = 3000
-- }
Config.WandFx = nil

Config.SmokeScreen = {
    dict = "core",
    particle = "exp_grd_bzgas_smoke",
    duration = 10000,
    centerScale = 4.5,
    ringScale = 4.0,
    radius = 3.0,
    pointsPerRing = 7,
    zOffsets = { 0.15 },
    maxRenderDistance = 250.0
}

Config.Module = {
    id = 'fumora',
    name = 'Fumora',
    description = "Libère un épais nuage de fumée enchantée obscurcissant la vision et les repères.",
    icon = 'smoke',
    color = 'purple',
    cooldown = 12000,
    type = 'utility',
    key = '5',
    image = 'images/power/firepunch.png',
    video = "YOUR_VIDEO_URL_HERE",
    professor = true
}

Config.Messages = {
    noWand = {
        title = 'Fumora',
        description = 'Vous devez équiper une baguette.',
        type = 'error',
        icon = 'smoke'
    },
    noGround = {
        title = 'Fumora',
        description = 'Aucun sol valide.',
        type = 'warning',
        icon = 'smoke'
    }
}

Config.Debug = false

_ENV.Config = Config

