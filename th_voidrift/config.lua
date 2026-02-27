---@diagnostic disable: undefined-global, trailing-space
local Config <const> = {}

Config.Rift = {
    pullRadius = 12.0,
    pullForce = 2.8,
    duration = 4500,
    explodeAfter = 3500,
    explodeRadius = 8.0
}

Config.FX = {
    rift = { dict = 'core', particle = 'ent_amb_sparking_wires_sp', scale = 2.0 },
    aura = { dict = 'core', particle = 'veh_exhaust_spacecraft', scale = 1.1 },
    explode = { dict = 'core', particle = 'exp_grd_plane_small', scale = 1.2 }
}

Config.Module = {
    id = 'voidrift',
    name = 'Void Rift',
    description = "Ouvre une faille gravitationnelle attirant les cibles vers un centre de néant.",
    icon = 'circle-radiation',
    color = 'purple',
    cooldown = 9000,
    type = 'attack',
    image = 'images/power/th_voidrift.png',
    video = "YOUR_VIDEO_URL_HERE",
    professor = true
}

Config.Messages = {
    noWand = {
        title = 'Void Rift',
        description = 'Vous devez équiper une baguette.',
        type = 'error',
        icon = 'circle-radiation'
    }
}

Config.Debug = false

_ENV.Config = Config
