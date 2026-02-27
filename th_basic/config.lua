---@diagnostic disable: undefined-global, trailing-space
local Config <const> = {}

Config.Projectile = {
    speed = 30.0,
    maxDistance = 1000.0
}

Config.Module = {
    id = 'basic',
    name = 'Basicus',
    description = "Sortilège élémentaire servant à canaliser et maîtriser les bases du Flux.",
    icon = 'wand-magic-sparkles',
    color = 'green',
    cooldown = 2000,
    type = 'attack',
    key = nil,
    image = 'images/power/th_basic.png',
    video = 'YOUR_VIDEO_URL_HERE',
    professor = true
}

Config.Damage = {
    base = 0,          -- Dégâts additionnels fixes
    perLevel = 5       -- Multiplicateur de dégâts par niveau (>0 = dégâts)
}

Config.Messages = {
    noWand = {
        title = 'Basicus',
        description = 'Vous n\'avez pas de baguette équipée',
        type = 'error',
        icon = 'wand-magic-sparkles'
    },
    noTarget = {
        title = 'Basicus',
        description = 'Aucune cible détectée',
        type = 'warning',
        icon = 'wand-magic-sparkles'
    }
}

Config.Debug = false

_ENV.Config = Config    
