---@diagnostic disable: trailing-space
local Config <const> = {}

Config.Key = 'P'

Config.Animation = {
    dict = 'gun_head@sharror',
    name = 'gun_head_clip',
    flag = 48,
    duration = 1500
}

Config.Shield = {
    model = 'nib_protego_prop',
    animDict = 'export@nib_protego_prop',
    animName = 'nib_protego_prop',
    alpha = 200,
    duration = 1000,
    blockDamage = 0.8,
    cooldown = 1000
}

Config.Effects = {
    castFlash = {
        asset = 'core',
        effect = 'ent_amb_elec_crackle',
        count = 3,
        scale = 1.3,
        light = {
            color = { r = 120, g = 200, b = 255 },
            radius = 7.0,
            intensity = 13.0,
            duration = 420
        }
    },
    shieldLoop = {
        asset = 'core',
        effect = 'ent_amb_elec_crackle',
        offset = { x = 0.0, y = 0.0, z = 0.4 },
        scale = 1.0,
        color = { r = 0.4, g = 0.8, b = 1.0 },
        alpha = 100
    },
    pulse = {
        color = { r = 90, g = 180, b = 255 },
        radius = 7.5,
        intensity = 11.0,
        period = 1600
    },
    breakFlash = {
        asset = 'core',
        effect = 'ent_sht_elec_fire_sp',
        count = 2,
        scale = 1.5,
        light = {
            color = { r = 150, g = 220, b = 255 },
            radius = 8.5,
            intensity = 12.5,
            duration = 520
        }
    }
}

Config.MaxLevel = 5
Config.Levels = {
    [0] = { duration = 1200, blockDamage = 1.0, props = true, godmode = false, cooldown = 10000 },
    [1] = { duration = 1200, blockDamage = 1.0, props = true, godmode = false, cooldown = 10000 },
    [2] = { duration = 1500, blockDamage = 1.0, props = true, godmode = true, cooldown = 6000 },
    [3] = { duration = 1800, blockDamage = 1.0, props = true, godmode = true, cooldown = 6000 },
    [4] = { duration = 2100, blockDamage = 1.0, props = true, godmode = true, cooldown = 3000 },
    [5] = { duration = 2400, blockDamage = 1.0, props = true, godmode = true, cooldown = 1000 }
}

_ENV.Config = Config
