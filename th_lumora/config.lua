local Config <const> = {}

Config.LightRance = 5.0
Config.LightIntensity = 8.0
Config.MaxDistance = 100.0
Config.FallbackDistance = 80.0

Config.MaxLevel = 5
Config.LevelSettings = {
    [0] = { range = 1.4, intensity = 3.0, maxDistance = 40.0, fallbackDistance = 30.0 },
    [1] = { range = 1.8, intensity = 4.5, maxDistance = 55.0, fallbackDistance = 40.0 },
    [2] = { range = 2.2, intensity = 6.0, maxDistance = 70.0, fallbackDistance = 50.0 },
    [3] = { range = 2.6, intensity = 7.0, maxDistance = 85.0, fallbackDistance = 65.0 },
    [4] = { range = 2.8, intensity = 7.5, maxDistance = 95.0, fallbackDistance = 75.0 },
    [5] = { range = Config.LightRance, intensity = Config.LightIntensity, maxDistance = Config.MaxDistance, fallbackDistance = Config.FallbackDistance }
}

Config.Animation = {
    dict = 'export@nib@wizardsv_wand_attack_b2',
    name = 'nib@wizardsv_wand_attack_b2',
    flag = 0,
    duration = 800
}

_ENV.Config = Config
