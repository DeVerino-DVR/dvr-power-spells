---@diagnostic disable: undefined-global, trailing-space, unused-local
local function Notify(sourceId, payload)
    if not payload then
        return
    end

    TriggerClientEvent('ox_lib:notify', sourceId, payload)
end

RegisterNetEvent('dvr_juliusis:broadcastProjectile', function(targetCoords, targetId, level)
    local _source <const> = source

    if not targetCoords then
        return
    end

    TriggerClientEvent('dvr_juliusis:spawnProjectile', -1, _source, targetCoords, targetId or 0, level or 0)
end)

RegisterNetEvent('dvr_juliusis:ragdollTarget', function(targetId, level)
    local _source <const> = source
    if not targetId or targetId <= 0 then
        return
    end

    if targetId == _source then
        return
    end

    if exports['dvr_prothea'] and exports['dvr_prothea'].hasActiveShield and exports['dvr_prothea']:hasActiveShield(targetId) then
        print(string.format('[Juliusis] ragdoll annulé par Prothea pour %s', targetId))
        return
    end

    TriggerClientEvent('dvr_juliusis:applyRagdoll', targetId, level or 0)
end)

local function RegisterJuliusisModule()
    local moduleData <const> = {
        id = Config.Module.id,
        name = Config.Module.name,
        description = Config.Module.description,
        icon = Config.Module.icon,
        color = Config.Module.color,
        cooldown = Config.Module.cooldown or 5000,
        type = Config.Module.type,
        isBasic = false,
        image = Config.Module.image or "images/power/dvr_juliusis.png",
        professor = Config.Module.professor ~= false,
        hidden = Config.Module.hidden == true,
        animation = {
            dict = 'anim@mp_player_intupperfinger',
            name = 'idle_a_fp',
            flag = 49,
            duration = 1000
        },
        onCast = function(hasItem, raycast, source, target, level)
            if not hasItem then
                Notify(source, Config.Messages and Config.Messages.noWand)
                return false
            end

            local spellLevel = level ~= nil and math.floor(tonumber(level) or 0) or GetCasterLevel(source)
            local data = {
                professor = { source = source },
                spell = { id = 'juliusis', name = 'Juliusis', level = spellLevel },
                context = { temp = false, coords = source and GetEntityCoords(GetPlayerPed(source)) or nil}
            }
            exports['dvr_power']:LogSpellCast(data)

            local casterCoords = GetEntityCoords(GetPlayerPed(source))
            TriggerClientEvent('dvr_juliusis:playSound', -1, source, casterCoords)
            TriggerClientEvent('dvr_juliusis:otherPlayerCasting', -1, source)
            TriggerClientEvent('dvr_juliusis:prepareProjectile', source, target or 0, level or 0)
            return true
        end
    }

    exports['dvr_power']:registerModule(moduleData, 0)
    print('[dvr_juliusis] Module enregistré avec succès')
end

CreateThread(function()
    while GetResourceState('dvr_power') ~= 'started' do
        Wait(100)
    end

    Wait(500)
    RegisterJuliusisModule()
end)

AddEventHandler('onResourceStart', function(resourceName)
    if resourceName == 'dvr_power' then
        Wait(1000)
        RegisterJuliusisModule()
    end
end)
