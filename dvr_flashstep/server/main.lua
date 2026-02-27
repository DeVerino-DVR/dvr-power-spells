---@diagnostic disable: undefined-global, trailing-space, unused-local
local function Notify(sourceId, payload)
    if not payload then
        return
    end
    TriggerClientEvent('ox_lib:notify', sourceId, payload)
end

RegisterNetEvent('dvr_flashstep:dash', function(targetCoords)
    local _source <const> = source
    if not targetCoords then
        return
    end
    TriggerClientEvent('dvr_flashstep:doDash', -1, _source, targetCoords)
end)

local function RegisterFlashstepModule()
    local moduleData <const> = {
        id = Config.Module.id,
        name = Config.Module.name,
        description = Config.Module.description,
        icon = Config.Module.icon,
        color = Config.Module.color,
        cooldown = Config.Module.cooldown or 6000,
        type = Config.Module.type,
        isBasic = false,
        sound = Config.FX.sound,
        soundType = "3d",
        image = Config.Module.image or "images/power/dvr_flashstep.png",
        video = Config.Module.video or "YOUR_VIDEO_URL_HERE",
        professor = Config.Module.professor ~= false,
        animation = {
            dict = 'export@nib@wizardsv_wand_attack_lightning',
            name = 'nib@wizardsv_wand_attack_lightning',
            flag = 48,
            duration = 1200
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
                spell = { id = 'flashstep', name = 'Flashstep', level = spellLevel },
                context = { temp = false, coords = source and GetEntityCoords(GetPlayerPed(source)) or nil}
            }
            exports['dvr_power']:LogSpellCast(data)

            TriggerClientEvent('dvr_flashstep:otherPlayerCasting', -1, source)
            TriggerClientEvent('dvr_flashstep:prepareDash', source)
            return true
        end
    }
    exports['dvr_power']:registerModule(moduleData, 0)
    print('[dvr_flashstep] Module enregistré avec succès')
end

CreateThread(function()
    while GetResourceState('dvr_power') ~= 'started' do
        Wait(100)
    end
    Wait(500)
    RegisterFlashstepModule()
end)

AddEventHandler('onResourceStart', function(resourceName)
    if resourceName == 'dvr_power' then
        Wait(1000)
        RegisterFlashstepModule()
    end
end)
