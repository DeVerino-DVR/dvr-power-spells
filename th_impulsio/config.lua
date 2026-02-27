---@diagnostic disable: undefined-global, trailing-space
local Config <const> = {}

-- Projectile configuration (uses native WEAPON_RAYPISTOL)
Config.Projectile = {
    speed = 80.0,                  -- Bullet speed (raypistol default is ~125, we use 80 for visibility)
    maxDistance = 100.0,           -- Max shooting distance
    impactRadius = 5.0,            -- Damage radius
    ragdollForceUp = 20.0,         -- Strong upward force
    ragdollForceHorizontal = 12.0, -- Strong horizontal force
}

-- Knockback configuration
Config.Knockback = {
    radius = 6.0,          -- Knockback radius
    ragdollTime = 3000,    -- Ragdoll duration (ms)
}

-- Damage configuration (uses th_power ApplySpellDamage)
Config.Damage = {
    perLevel = 18,         -- Damage per spell level (50/100/150/200/250)
    radius = 5.0           -- Damage radius
}

-- Animation
Config.Animation = {
    dict = 'export@nib@wizardsv_avada_kedrava',
    name = 'nib@wizardsv_avada_kedrava',
    flag = 0,
    duration = 2500,
    speedMultiplier = 3.5
}

-- Module registration
Config.Module = {
    id = 'impulsio',
    name = 'Impulsio',
    description = "Tire un rayon d'énergie qui explose et propulse violemment les cibles dans les airs.",
    icon = 'bolt',
    color = 'green',
    cooldown = 8000,
    type = 'attack',
    imageSrc = 'images/power/th_impulsio.png',
    videoSrc = '',
    isProfessorOnly = true
}

-- Messages
Config.Messages = {
    noWand = {
        title = 'Impulsio',
        description = 'Vous devez équiper une baguette.',
        type = 'error',
        icon = 'bolt'
    }
}

Config.Debug = false

_ENV.Config = Config
