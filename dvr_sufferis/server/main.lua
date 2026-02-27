---@diagnostic disable: undefined-global, trailing-space, unused-local
local function Notify(sourceId, payload)
    if not payload then
        return
    end

    TriggerClientEvent('ox_lib:notify', sourceId, payload)
end

RegisterNetEvent('dvr_sufferis:broadcastProjectile', function(targetCoords, targetId, level)
    local _source <const> = source

    if not targetCoords then
        return
    end

    TriggerClientEvent('dvr_sufferis:spawnProjectile', -1, _source, targetCoords, targetId or 0, level or 0)
end)

RegisterNetEvent('dvr_sufferis:ragdollTarget', function(targetId, level)
    if not targetId or targetId <= 0 then
        return
    end

    TriggerClientEvent('dvr_sufferis:applyRagdoll', targetId, level or 0)
end)

local function RegisterSufferisModule()
    local moduleData <const> = {
        id = Config.Module.id,
        name = Config.Module.name,
        description = Config.Module.description,
        icon = Config.Module.icon,
        color = Config.Module.color,
        cooldown = Config.Module.cooldown or 8000,
        type = Config.Module.type,
        isBasic = false,
        key = Config.Module.key,
        sound = '',
        soundType = "3d",
        image = Config.Module.image or "images/power/dvr_sufferis.png",
        video = Config.Module.video or "YOUR_VIDEO_URL_HERE",
        professor = Config.Module.professor ~= false,
        animation = {
            dict = "export@nib@wizardsv_wand_attack_b4",
            name = "nib@wizardsv_wand_attack_b4",
            flag = 0,
            duration = 3000,
            speedMultiplier = (Config.Animation and Config.Animation.speedMultiplier) or 16.5
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
                spell = { id = 'sufferis', name = 'Sufferis', level = spellLevel },
                context = { temp = false, coords = source and GetEntityCoords(GetPlayerPed(source)) or nil}
            }
            exports['dvr_power']:LogSpellCast(data)

            TriggerClientEvent('dvr_sufferis:otherPlayerCasting', -1, source)
            TriggerClientEvent('dvr_sufferis:prepareProjectile', source, target or 0, level or 0)
            return true
        end
    }

    exports['dvr_power']:registerModule(moduleData, 0)
    print('[dvr_sufferis] Module enregistré avec succès')
end

CreateThread(function()
    while GetResourceState('dvr_power') ~= 'started' do
        Wait(100)
    end

    Wait(500)
    RegisterSufferisModule()
end)

AddEventHandler('onResourceStart', function(resourceName)
    if resourceName == 'dvr_power' then
        Wait(1000)
        RegisterSufferisModule()
    end
end)
