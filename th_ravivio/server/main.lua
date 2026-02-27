-- REQUIRES: ESX Framework (es_extended) - Replace ESX.GetPlayerFromId calls with your framework
---@diagnostic disable: undefined-global, trailing-space, unused-local
local function Notify(sourceId, payload)
    if not payload then
        return
    end

    TriggerClientEvent('ox_lib:notify', sourceId, payload)
end

local function GetNearestDeadPlayer(sourceId)
    local xPlayer = ESX.GetPlayerFromId(sourceId)
    if not xPlayer then
        return nil
    end

    local sourcePed = GetPlayerPed(sourceId)
    local sourceCoords = GetEntityCoords(sourcePed)
    local nearestPlayer = nil
    local nearestDistance = Config.ReviveSettings.maxDistance

    local players = GetPlayers()

    for _, playerId in ipairs(players) do
        local targetId = tonumber(playerId)

        if targetId and targetId ~= sourceId then
            local targetPed = GetPlayerPed(targetId)

            if targetPed and DoesEntityExist(targetPed) then
                local targetState = Player(targetId).state

                if targetState and targetState.isDead then
                    local targetCoords = GetEntityCoords(targetPed)
                    local distance = #(sourceCoords - targetCoords)

                    if distance <= nearestDistance then
                        nearestDistance = distance
                        nearestPlayer = targetId
                    end
                end
            end
        end
    end

    return nearestPlayer
end

RegisterNetEvent('th_ravivio:broadcastProjectile', function(finalTargetCoords)
    local _source <const> = source
    if not finalTargetCoords then
        return
    end

    local xPlayer = ESX.GetPlayerFromId(_source)
    if not xPlayer then
        return
    end

    -- Trouver le joueur mort le plus proche
    local targetPlayer = GetNearestDeadPlayer(_source)

    if not targetPlayer then
        local msg = Config.Messages.noDeadPlayer or {
            title = 'Ravivio',
            description = 'Aucun joueur mort à proximité',
            type = 'error',
            icon = 'skull'
        }
        Notify(_source, msg)
        return
    end

    TriggerClientEvent('th_ravivio:fireProjectile', -1, _source, finalTargetCoords, targetPlayer)
end)

RegisterNetEvent('th_ravivio:projectileHit', function(targetPlayer)
    local _source <const> = source
    local xPlayer = ESX.GetPlayerFromId(_source)
    local xTarget = ESX.GetPlayerFromId(targetPlayer)

    if not xPlayer or not xTarget then
        return
    end

    TriggerClientEvent('ft_respawn:revive', targetPlayer)

    TriggerClientEvent('th_ravivio:playReviveEffect', -1, targetPlayer)
    local successMsg = Config.Messages.success or {
        title = 'Ravivio',
        description = 'Vous avez réanimé ' .. xTarget.getName(),
        type = 'success',
        icon = 'heart-pulse'
    }
    successMsg.description = successMsg.description:gsub('{target}', xTarget.getName())
    Notify(_source, successMsg)

    local revivedMsg = Config.Messages.revived or {
        title = 'Ravivio',
        description = 'Vous avez été réanimé par ' .. xPlayer.getName(),
        type = 'success',
        icon = 'heart-pulse'
    }
    revivedMsg.description = revivedMsg.description:gsub('{caster}', xPlayer.getName())
    Notify(targetPlayer, revivedMsg)
end)

local function RegisterRavivioModule()
    local moduleData <const> = {
        id = Config.Module.id,
        name = Config.Module.name,
        description = Config.Module.description,
        icon = Config.Module.icon,
        color = Config.Module.color,
        cooldown = Config.Module.cooldown or 30000,
        type = Config.Module.type,
        isBasic = false,
        key = Config.Module.key,
        sound = 'YOUR_SOUND_URL_HERE',
        soundType = "3d",
        image = Config.Module.image or "images/power/th_ravivio.png",
        video = Config.Module.video or "YOUR_VIDEO_URL_HERE",
        professor = Config.Module.professor ~= false,
        animation = {
            dict = "export@nib@wizardsv_wand_attack_2",
            name = "nib@wizardsv_wand_attack_2",
            flag = 0,
            duration = 2000,
            speedMultiplier = 4.0,
            propsDelay = 1500
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
                spell = { id = 'ravivio', name = 'Ravivio', level = spellLevel },
                context = { temp = false, coords = source and GetEntityCoords(GetPlayerPed(source)) or nil}
            }
            exports['th_power']:LogSpellCast(data)
            TriggerClientEvent('th_ravivio:otherPlayerCasting', -1, source)
            TriggerClientEvent('th_ravivio:prepareCast', source)
            return true
        end
    }

    exports['th_power']:registerModule(moduleData, 0)
    print('[th_ravivio] Module enregistré avec succès')
end

CreateThread(function()
    while GetResourceState('th_power') ~= 'started' do
        Wait(100)
    end

    Wait(500)
    RegisterRavivioModule()
end)

AddEventHandler('onResourceStart', function(resourceName)
    if resourceName == 'th_power' then
        Wait(1000)
        RegisterRavivioModule()
    end
end)
