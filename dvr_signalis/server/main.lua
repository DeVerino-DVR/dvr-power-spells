---@diagnostic disable: undefined-global, trailing-space, unused-local
RegisterNetEvent('dvr_signalis:broadcastProjectile', function(finalTargetCoords)
    local _source <const> = source
    if not finalTargetCoords then
        return
    end
    
    TriggerClientEvent('dvr_signalis:fireProjectile', -1, _source, finalTargetCoords)
end)

local function RegisterSignalisModule()
    local moduleData <const> = {
        id = Config.Module.id,
        name = Config.Module.name,
        description = Config.Module.description,
        icon = Config.Module.icon,
        color = Config.Module.color,
        cooldown = Config.Module.cooldown or 5000,
        type = Config.Module.type,
        isBasic = false,
        key = nil,
        soundType = "3d",
        image = Config.Module.image,
        video = Config.Module.video,
        professor = Config.Module.professor ~= false,
        animation = {
            dict = 'export@nib@wizardsv_wand_attack_b2',
            name = 'nib@wizardsv_wand_attack_b2',
            flag = 0,
            duration = 2000,
            speedMultiplier = 1.5
        },
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
                spell = { id = 'signalis', name = 'Signalis', level = spellLevel },
                context = { temp = false, coords = source and GetEntityCoords(GetPlayerPed(source)) or nil}
            }
            exports['dvr_power']:LogSpellCast(data)
            
            TriggerClientEvent('dvr_signalis:otherPlayerCasting', -1, source)
            TriggerClientEvent('dvr_signalis:prepareProjectile', source)
            return true
        end
    }

    exports['dvr_power']:registerModule(moduleData, 0)
    print('[dvr_signalis] Module enregistré avec succès')
end

CreateThread(function()
    while GetResourceState('dvr_power') ~= 'started' do
        Wait(100)
    end
    
    Wait(500)
    RegisterSignalisModule()
end)

AddEventHandler('onResourceStart', function(resourceName)
    if resourceName == 'dvr_power' then
        Wait(1000)
        RegisterSignalisModule()
    end
end)
