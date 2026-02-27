---@diagnostic disable: undefined-global, trailing-space, unused-local
RegisterNetEvent('th_ignifera:broadcastProjectile', function(finalTargetCoords, spellLevel)
    local _source <const> = source
    if not finalTargetCoords then
        return
    end
    
    TriggerClientEvent('th_ignifera:fireProjectile', -1, _source, finalTargetCoords, spellLevel)
end)

RegisterNetEvent('th_ignifera:applyExplosionDamage', function(explosionCoords, spellLevel)
    local _source <const> = source
    
    if not explosionCoords or not spellLevel then
        return
    end
    
    -- Use centralized damage system from th_power
    local damagePerLevel = Config.Damage and Config.Damage.perLevel or 50
    local damageRadius = Config.Damage and Config.Damage.radius or 5.0
    
    exports['th_power']:ApplySpellDamage(
        explosionCoords,
        spellLevel,
        damagePerLevel,
        damageRadius,
        _source,
        'Ignifera'
    )
end)

local function GetRaycastTarget(raycastData, targetId)
    if raycastData and type(raycastData.entityHit) == 'number' and raycastData.entityHit > 0 then
        return raycastData.entityHit
    end

    if type(targetId) == 'number' and targetId > 0 then
        return targetId
    end

    return nil
end

local function RegisterIgniferaModule()
    local moduleData <const> = {
        id = Config.Module.id,
        name = Config.Module.name,
        description = Config.Module.description,
        icon = Config.Module.icon,
        color = Config.Module.color,
        cooldown = Config.Module.cooldown or 15000,
        type = Config.Module.type,
        isBasic = false,
        key = nil,
        soundType = "3d",
        sound = Config.Module.sound or 'YOUR_SOUND_URL_HERE',
        video = Config.Module.video,
        image = Config.Module.image,
        professor = Config.Module.professor ~= false,
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

            -- L'explosion gère les dégâts, mais on peut ajouter des dégâts directs si on touche
            local targetId = GetRaycastTarget(raycast, target)
            if targetId and raycast and raycast.hit then
                -- Optionnel : dégâts directs supplémentaires
            end

            local spellLevel = level ~= nil and math.floor(tonumber(level) or 0) or GetCasterLevel(source)
            local data = {
                professor = { source = source },
                spell = { id = 'ignifera', name = 'Ignifera', level = spellLevel },
                context = { temp = false, coords = source and GetEntityCoords(GetPlayerPed(source)) or nil}
            }
            exports['th_power']:LogSpellCast(data)
            
            TriggerClientEvent('th_ignifera:otherPlayerCasting', -1, source)
            TriggerClientEvent('th_ignifera:prepareProjectile', source, spellLevel)
            return true
        end
    }

    exports['th_power']:registerModule(moduleData, 0)
    print('[th_ignifera] Module enregistré avec succès')
end

CreateThread(function()
    while GetResourceState('th_power') ~= 'started' do
        Wait(100)
    end
    
    Wait(500)
    RegisterIgniferaModule()
end)

AddEventHandler('onResourceStart', function(resourceName)
    if resourceName == 'th_power' then
        Wait(1000)
        RegisterIgniferaModule()
    end
end)
