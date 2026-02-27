---@diagnostic disable: undefined-global, trailing-space, unused-local
lib.locale()

--- Handle damage BEFORE bullet is fired (damage_system protects players first)
RegisterNetEvent('dvr_impulsio:prepareImpact', function(impactCoords, spellLevel)
    local _source = source

    local radius = Config.Projectile.impactRadius or 5.0

    -- Apply damage via damage_system BEFORE the bullet arrives
    -- This protects players from native explosion damage and applies custom damage
    exports['dvr_power']:ApplySpellDamage(
        impactCoords,
        spellLevel,
        Config.Damage.perLevel,
        radius,
        _source,
        'Impulsio',
        800  -- Protection duration (ms) - enough time for bullet to arrive
    )

    -- Broadcast knockback to all players in range (will apply when bullet explodes)
    local knockbackRadius = Config.Knockback.radius or 6.0
    local forceUp = Config.Projectile.ragdollForceUp or 20.0
    local forceHorizontal = Config.Projectile.ragdollForceHorizontal or 12.0
    local ragdollTime = Config.Knockback.ragdollTime or 3000

    -- Delay knockback slightly so it happens after bullet impact
    SetTimeout(200, function()
        TriggerClientEvent('dvr_impulsio:applyKnockback', -1, impactCoords, spellLevel, forceUp, forceHorizontal, ragdollTime)
    end)
end)

--- Handle projectile creation event from client to broadcast to all clients
RegisterNetEvent('dvr_impulsio:createProjectile', function(startCoords, targetCoords, spellLevel)
    local _source = source
    -- Broadcast projectile creation to all clients
    TriggerClientEvent('dvr_impulsio:createProjectile', -1, startCoords, targetCoords, _source, spellLevel)
end)

--- Handle impact event from client to broadcast EMP particle to all clients
RegisterNetEvent('dvr_impulsio:onImpact', function(impactCoords, spellLevel)
    -- Broadcast EMP particle effect to all clients
    TriggerClientEvent('dvr_impulsio:playImpactFx', -1, impactCoords)
end)

local function GetCasterLevel(sourceId)
    local ok, hasSpell, level = pcall(function()
        return exports['dvr_power']:GetSpell(sourceId, 'impulsio')
    end)
    
    if ok and hasSpell then
        return level or 1
    end
    return 1
end

local function RegisterImpulsioModule()
    local moduleData = {
        id = Config.Module.id,
        name = Config.Module.name,
        description = Config.Module.description,
        icon = Config.Module.icon,
        color = Config.Module.color,
        cooldown = Config.Module.cooldown or 8000,
        type = Config.Module.type,
        isBasic = false,
        key = nil,
        soundType = "3d",
        sound = nil,  -- Raypistol has native sound
        video = Config.Module.videoSrc,
        image = Config.Module.imageSrc,
        professor = Config.Module.isProfessorOnly ~= false,
        animation = Config.Animation,
        onCast = function(hasItem, raycast, source, target, level)
            if not hasItem then
                TriggerClientEvent('ox_lib:notify', source, {
                    title = Config.Messages.noWand.title,
                    description = Config.Messages.noWand.description,
                    type = Config.Messages.noWand.type,
                    icon = Config.Messages.noWand.icon
                })
                return false
            end

            local spellLevel = level ~= nil and math.floor(tonumber(level) or 0) or GetCasterLevel(source)
            local data = {
                professor = { source = source },
                spell = { id = 'impulsio', name = 'Impulsio', level = spellLevel },
                context = { temp = false, coords = source and GetEntityCoords(GetPlayerPed(source)) or nil}
            }
            exports['dvr_power']:LogSpellCast(data)
            
            TriggerClientEvent('dvr_impulsio:otherPlayerCasting', -1, source)
            TriggerClientEvent('dvr_impulsio:prepareCast', source, spellLevel)
            return true
        end
    }

    exports['dvr_power']:registerModule(moduleData, 0)
    print('[dvr_impulsio] Module enregistré avec succès')
end

CreateThread(function()
    while GetResourceState('dvr_power') ~= 'started' do
        Wait(100)
    end
    
    Wait(500)
    RegisterImpulsioModule()
end)

AddEventHandler('onResourceStart', function(resourceName)
    if resourceName == 'dvr_power' then
        Wait(1000)
        RegisterImpulsioModule()
    end
end)
