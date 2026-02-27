---@diagnostic disable: undefined-global, trailing-space, unused-local
local function Notify(sourceId, payload)
    if not payload then
        return
    end

    TriggerClientEvent('ox_lib:notify', sourceId, payload)
end

RegisterNetEvent('th_thunder:broadcastProjectile', function(targetCoords, targetId, level, shotIndex, shotTotal)
    local _source <const> = source

    if not targetCoords then
        return
    end

    TriggerClientEvent('th_thunder:spawnProjectile', -1, _source, targetCoords, targetId or 0, level or 0, shotIndex or 1, shotTotal or 1)
end)

RegisterNetEvent('th_thunder:ragdollTarget', function(targetId, level)
    local _source <const> = source
    if not targetId or targetId <= 0 then
        return
    end

    if targetId == _source then
        return
    end

    if exports['th_prothea'] and exports['th_prothea'].hasActiveShield and exports['th_prothea']:hasActiveShield(targetId) then
        print(string.format('[Thunder] ragdoll annulé par Prothea pour %s', targetId))
        return
    end

    TriggerClientEvent('th_thunder:applyRagdoll', targetId, level or 0)
end)

RegisterNetEvent('th_thunder:applyLightningDamage', function(strikeCoords, spellLevel)
    local _source <const> = source
    
    if not strikeCoords or not spellLevel then
        return
    end
    
    -- Use centralized damage system from th_power
    local damagePerLevel = Config.Damage and Config.Damage.perLevel or 50
    local damageRadius = Config.Damage and Config.Damage.radius or 5.0
    
    -- Thunder has multiple lightning strikes, use longer protection duration (1000ms)
    exports['th_power']:ApplySpellDamage(
        strikeCoords,
        spellLevel,
        damagePerLevel,
        damageRadius,
        _source,
        'Thunder',
        1000  -- Longer protection for multiple strikes
    )
end)

local function RegisterThunderModule()
    local anim <const> = Config.Module.animation or {}
    local moduleData <const> = {
        id = Config.Module.id,
        name = Config.Module.name,
        description = Config.Module.description,
        icon = Config.Module.icon,
        color = Config.Module.color,
        cooldown = Config.Module.cooldown or 3000,
        type = Config.Module.type,
        isBasic = false,
        sound = Config.Sounds.cast.url,
        soundType = "3d",
        image = Config.Module.image or "images/power/th_thunder.png",
        video = Config.Module.video or "YOUR_VIDEO_URL_HERE",
        professor = Config.Module.professor ~= false,
        animation = {
            dict = anim.dict,
            name = anim.name,
            flag = anim.flag or 0,
            duration = anim.duration or 3000,
            speedMultiplier = anim.speedMultiplier or 1.5
        },
        onCast = function(hasItem, raycast, source, target, level)
            if not hasItem then
                Notify(source, Config.Messages and Config.Messages.noWand)
                return false
            end

            local spellLevel = level ~= nil and math.floor(tonumber(level) or 0) or GetCasterLevel(source)
            local data = {
                professor = { source = source },
                --target = { source = target }, -- f
                spell = { id = 'thunder', name = 'Thunder', level = spellLevel },
                context = { temp = false, coords = source and GetEntityCoords(GetPlayerPed(source)) or nil}
            }
            exports['th_power']:LogSpellCast(data)
            TriggerClientEvent('th_thunder:otherPlayerCasting', -1, source)
            TriggerClientEvent('th_thunder:prepareProjectile', source, target or 0, level or 0)
            return true
        end
    }

    exports['th_power']:registerModule(moduleData, 0)
    print('[th_thunder] Module enregistré avec succès')
end

CreateThread(function()
    while GetResourceState('th_power') ~= 'started' do
        Wait(100)
    end

    Wait(500)
    RegisterThunderModule()
end)

AddEventHandler('onResourceStart', function(resourceName)
    if resourceName == 'th_power' then
        Wait(1000)
        RegisterThunderModule()
    end
end)
