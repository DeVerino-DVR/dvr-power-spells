---@diagnostic disable: undefined-global, trailing-space, unused-local
local function Notify(sourceId, payload)
    if not payload then
        return
    end
    TriggerClientEvent('ox_lib:notify', sourceId, payload)
end

RegisterNetEvent('dvr_shockwave:trigger', function(targetCoords)
    local _source <const> = source
    if not targetCoords then
        return
    end
    TriggerClientEvent('dvr_shockwave:fire', -1, _source, targetCoords)
end)

local function RegisterShockwaveModule()
    local moduleData <const> = {
        id = Config.Module.id,
        name = Config.Module.name,
        description = Config.Module.description,
        icon = Config.Module.icon,
        color = Config.Module.color,
        cooldown = Config.Module.cooldown or 7000,
        type = Config.Module.type,
        isBasic = false,
        sound = '',
        soundType = "3d",
        image = Config.Module.image or "images/power/ljump.png",
        video = Config.Module.video or "YOUR_VIDEO_URL_HERE",
        professor = Config.Module.professor ~= false,
        animation = {
            dict = "export@nib@wizardsv_wand_attack_lightning",
        name = "nib@wizardsv_wand_attack_lightning",
            flag = 48,
            duration = 1500,
            speedMultiplier = 1.5,
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
                spell = { id = 'shockwave', name = 'Shockwave', level = spellLevel },
                context = { temp = false, coords = source and GetEntityCoords(GetPlayerPed(source)) or nil}
            }
            exports['dvr_power']:LogSpellCast(data)

            TriggerClientEvent('dvr_shockwave:otherPlayerCasting', -1, source)
            TriggerClientEvent('dvr_shockwave:prepare', source)
            return true
        end
    }
    exports['dvr_power']:registerModule(moduleData, 0)
    print('[dvr_shockwave] Module enregistré avec succès')
end

CreateThread(function()
    while GetResourceState('dvr_power') ~= 'started' do
        Wait(100)
    end
    Wait(500)
    RegisterShockwaveModule()
end)

AddEventHandler('onResourceStart', function(resourceName)
    if resourceName == 'dvr_power' then
        Wait(1000)
        RegisterShockwaveModule()
    end
end)
