---@diagnostic disable: trailing-space
local Config <const> = {}

Config.Projectile = {
    model = 'nib_accio_ray',
    speed = 80.0,
    handBone = 28422
}

Config.Animation = {
    dict = 'export@nib@wizardsv_avada_kedrava',
    name = 'nib@wizardsv_avada_kedrava',
    flag = 0,
    duration = 3000,
    speedMultiplier = 3.0,
    propsDelay = 2100
}

Config.WandParticle = {
    name = 'ent_amb_torch_fire',
    offset = { x = 0.85, y = 0.0, z = 0.05 },
    rot = { x = 0.0, y = 0.0, z = 0.0 },
    scale = 0.35,
    color = { r = 1.0, g = 0.5, b = 0.0 },
    alpha = 1.0
}

Config.WandAura = {
    name = 'veh_light_red_trail',
    offset = { x = 0.75, y = 0.0, z = 0.1 },
    scale = 0.5,
    color = { r = 1.0, g = 0.4, b = 0.0 },
    alpha = 200
}

Config.ProjectileTrail = {
    name = 'veh_light_red_trail',
    scale = 0.6,
    color = { r = 1.0, g = 0.4, b = 0.0 },
    alpha = 255
}

Config.ImpactSound = {
    url = 'YOUR_SOUND_URL_HERE',
    volume = 1.0
}

Config.FireCircle = {
    radius = 4.0,
    duration = 5000,
    outerFlames = 48,
    middleFlames = 24,
    innerFlames = 12,
    outerScale = 1.5,
    middleScale = 1.3,
    innerScale = 1.0,
    centerPtfx = 'ent_amb_foundry_fire',
    centerScale = 2.0,
    centerOffsetZ = 0.15,
    centerAlpha = 1.0
}

Config.Damage = {
    damageOverTime = 15,
    damageInterval = 400
}

_ENV.Config = Config
