local Config <const> = {}

Config.Debug = true

Config.Module = {
    id = 'black',
    name = 'Black',
    description = "Applique un maquillage noir sur le visage.",
    icon = 'mask',
    color = 'black',
    cooldown = 2000,
    type = 'utility',
    image = 'images/power/dvr_black.png',
    professor = false
}

-- Add player-specific makeup styles here using their discord/license identifier
Config.Makeup = {
    -- ['discord:YOUR_DISCORD_ID'] = {
    --     overlay_id = 4,
    --     style = 49,
    --     opacity = 1.0,
    --     colour_type = 1,
    --     colour = 56,
    --     secondary_colour = 56
    -- },
}

Config.TransitionFx = {
    asset = 'ns_ptfx', -- dvr_power/stream/ns_ptfx.ypt
    effect = 'fire',
    duration = 3000,
    alpha = 1.0,
    scale = 1.0,
    min_channel = 0, -- pas de boost: noir reste noir
    attach = 'bone', -- 'entity' (comme dvr_transvalis) ou 'bone'
    bone = 31086, -- SKEL_Head
    offset = { x = 0.0, y = 0.12, z = 0.0 },
    rot = { x = 0.0, y = 0.0, z = 0.0 }
}

Config.Messages = {
    applied = {
        title = 'Black',
        description = 'Maquillage noir appliqué.',
        type = 'success',
        icon = 'mask'
    },
    removed = {
        title = 'Black',
        description = 'Maquillage retiré.',
        type = 'inform',
        icon = 'mask'
    }
}

_ENV.Config = Config
