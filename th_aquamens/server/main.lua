---@diagnostic disable: undefined-global, trailing-space, unused-local
local function Notify(sourceId, payload)
    if not payload then
        return
    end

    TriggerClientEvent('ox_lib:notify', sourceId, payload)
end

RegisterNetEvent('th_aquamens:doTeleport', function(startCoords, targetCoords)
    local _source <const> = source

    if not startCoords or not targetCoords then
        return
    end

    TriggerClientEvent('th_aquamens:runTeleport', -1, _source, startCoords, targetCoords)
end)

local function RegisterAquamensModule()
    local moduleData <const> = {
        id = Config.Module.id,
        name = Config.Module.name,
        description = Config.Module.description,
        icon = Config.Module.icon,
        color = Config.Module.color,
        cooldown = Config.Module.cooldown or 6000,
        type = Config.Module.type,
        isBasic = false,
        key = Config.Module.key,
        sound = '',
        soundType = "3d",
        image = Config.Module.image or "images/power/th_aquamens.png",
        video = Config.Module.video or "YOUR_VIDEO_URL_HERE",
        professor = Config.Module.professor ~= false,
        animation = {
            dict = 'export@nib@wizardsv_wand_attack_1',
            name = 'nib@wizardsv_wand_attack_1',
            flag = 0,
            duration = 1200,
            speedMultiplier = 4.5,
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
                spell = { id = 'aquamens', name = 'Aquamens', level = spellLevel },
                context = { temp = false, coords = source and GetEntityCoords(GetPlayerPed(source)) or nil}
            }
            exports['th_power']:LogSpellCast(data)

            TriggerClientEvent('th_aquamens:otherPlayerCasting', -1, source)
            TriggerClientEvent('th_aquamens:prepareTeleport', source)
            return true
        end
    }

    exports['th_power']:registerModule(moduleData, 0)
    print('[th_aquamens] Module enregistré avec succès')
end

CreateThread(function()
    while GetResourceState('th_power') ~= 'started' do
        Wait(100)
    end

    Wait(500)
    RegisterAquamensModule()
end)

AddEventHandler('onResourceStart', function(resourceName)
    if resourceName == 'th_power' then
        Wait(1000)
        RegisterAquamensModule()
    end
end)
