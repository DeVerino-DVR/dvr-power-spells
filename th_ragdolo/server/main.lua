---@diagnostic disable: undefined-global, trailing-space, unused-local
local function Notify(sourceId, payload)
    if not payload then
        return
    end

    TriggerClientEvent('ox_lib:notify', sourceId, payload)
end

RegisterNetEvent('th_ragdolo:broadcastProjectile', function(targetCoords, targetId, level)
    local _source <const> = source

    if not targetCoords then
        return
    end

    TriggerClientEvent('th_ragdolo:spawnProjectile', -1, _source, targetCoords, targetId or 0, level or 0)
end)

RegisterNetEvent('th_ragdolo:ragdollTarget', function(targetId, level)
    local _source <const> = source
    if not targetId or targetId <= 0 then
        return
    end

    if targetId == _source then
        return
    end

    if exports['th_prothea'] and exports['th_prothea'].hasActiveShield and exports['th_prothea']:hasActiveShield(targetId) then
        print(string.format('[Ragdolo] ragdoll annulé par Prothea pour %s', targetId))
        return
    end

    TriggerClientEvent('th_ragdolo:applyRagdoll', targetId, level or 0)
end)

local function RegisterRagdoloModule()
    local animCfg <const> = Config.Animation or {}
    local moduleData <const> = {
        id = Config.Module.id,
        name = Config.Module.name,
        description = Config.Module.description,
        icon = Config.Module.icon,
        color = Config.Module.color,
        cooldown = Config.Module.cooldown or 3000,
        type = Config.Module.type,
        isBasic = false,
        key = Config.Module.key,
        sound = 'YOUR_SOUND_URL_HERE@',
        soundType = "3d",
        image = Config.Module.image or "images/power/th_ragdolo.png",
        video = Config.Module.video or "YOUR_VIDEO_URL_HERE",
        professor = Config.Module.professor ~= false,
        animation = {
            dict = animCfg.dict or 'export@nib@wizardsv_avada_kedrava',
            name = animCfg.name or 'nib@wizardsv_avada_kedrava',
            flag = animCfg.flag or 0,
            duration = animCfg.duration or 3000,
            speedMultiplier = animCfg.speedMultiplier or 3.5
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
                spell = { id = 'ragdolo', name = 'Ragdolo', level = spellLevel },
                context = { temp = false, coords = source and GetEntityCoords(GetPlayerPed(source)) or nil}
            }
            exports['th_power']:LogSpellCast(data)

            TriggerClientEvent('th_ragdolo:otherPlayerCasting', -1, source)
            TriggerClientEvent('th_ragdolo:prepareProjectile', source, target or 0, level or 0)
            return true
        end
    }

    exports['th_power']:registerModule(moduleData, 0)
    print('[th_ragdolo] Module enregistré avec succès')
end

CreateThread(function()
    while GetResourceState('th_power') ~= 'started' do
        Wait(100)
    end

    Wait(500)
    RegisterRagdoloModule()
end)

AddEventHandler('onResourceStart', function(resourceName)
    if resourceName == 'th_power' then
        Wait(1000)
        RegisterRagdoloModule()
    end
end)
