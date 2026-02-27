---@diagnostic disable: trailing-space
local Config <const> = {}

Config.Animation = {
    dict = 'export@nib@wizardsv_wand_attack_lightning',
    name = 'nib@wizardsv_wand_attack_lightning',
    flag = 48,
    duration = 1000
}

Config.Levitation = {
    duration = 5000,
    height = 1.5,
    riseTime = 1000,
    objectRadius = 3.0,
    controlRange = 15.0,
    maxControlRange = 35.0,
    dropForce = 12.0,
    playerAnimDict = 'skydive@base',
    playerAnimName = 'ragdoll_to_free_idle'
}

Config.Effects = {
    castFlash = {
        asset = 'core',
        effect = 'ent_amb_elec_crackle',
        count = 2,
        scale = 1.2,
        offset = { x = 0.0, y = 0.0, z = 0.8 },
        light = {
            color = { r = 150, g = 200, b = 255 },
            radius = 6.0,
            intensity = 11.0,
            duration = 420
        }
    },
    playerAura = {
        asset = 'core',
        effect = 'ent_amb_elec_crackle',
        offset = { x = 0.0, y = 0.0, z = 0.6 },
        scale = 0.9,
        color = { r = 0.4, g = 0.8, b = 1.0 },
        alpha = 120
    },
    objectAura = {
        asset = 'core',
        effect = 'ent_amb_elec_crackle',
        offset = { x = 0.0, y = 0.0, z = 0.3 },
        scale = 0.7,
        color = { r = 0.6, g = 0.9, b = 1.0 },
        alpha = 110
    },
    pulseLight = {
        color = { r = 130, g = 200, b = 255 },
        radius = 6.5,
        intensity = 10.5,
        period = 1800
    },
    release = {
        asset = 'core',
        effect = 'ent_sht_elec_fire_sp',
        count = 2,
        scale = 1.4,
        offset = { x = 0.0, y = 0.0, z = 0.6 },
        light = {
            color = { r = 160, g = 210, b = 255 },
            radius = 7.0,
            intensity = 12.0,
            duration = 380
        }
    }
}

_ENV.Config = Config
