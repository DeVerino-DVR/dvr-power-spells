---@diagnostic disable: undefined-global, trailing-space, unused-local
local function Notify(sourceId, payload)
    if not payload then return end
    TriggerClientEvent('ox_lib:notify', sourceId, payload)
end

local function RegisterCoagulisModule()
    local moduleData = {
        id = Config.Module.id,
        name = Config.Module.name,
        description = Config.Module.description,
        icon = Config.Module.icon,
        color = Config.Module.color,
        cooldown = Config.Module.cooldown or 6000,
        type = Config.Module.type,
        isBasic = false,
        key = Config.Module.key,
        sound = 'YOUR_SOUND_URL_HERE',
        video = 'YOUR_VIDEO_URL_HERE',
        soundType = "3d",
        image = Config.Module.image or "images/power/th_coagulis.png",
        professor = Config.Module.professor ~= false,
        animation = {
            dict = 'export@nib@wizardsv_avada_kedrava',
            name = 'nib@wizardsv_avada_kedrava',
            flag = 0,
            duration = 2200
        },
        onCast = function(hasItem, raycast, source, target, level)
            if not hasItem then
                Notify(source, Config.Messages and Config.Messages.noWand)
                return false
            end
            local spellLevel = level ~= nil and math.floor(tonumber(level) or 0) or 0
            local data = {
                professor = { source = source },
                spell = { id = 'coagulis', name = 'Coagulis', level = spellLevel },
                context = { temp = false, coords = source and GetEntityCoords(GetPlayerPed(source)) or nil}
            }
            exports['th_power']:LogSpellCast(data)
            TriggerClientEvent('th_coagulis:otherPlayerCasting', -1, source)
            TriggerClientEvent('th_coagulis:prepareProjectile', source)
            return true
        end
    }
    exports['th_power']:registerModule(moduleData, 0)
    print('[th_coagulis] Module enregistré avec succès')
end

RegisterNetEvent('th_coagulis:broadcastProjectile', function(finalTargetCoords)
    local _source = source
    if not finalTargetCoords then
        return
    end
    TriggerClientEvent('th_coagulis:fireProjectile', -1, _source, finalTargetCoords)
end)

RegisterNetEvent('th_coagulis:stopBleedServer', function(targetId)
    local _source = source
    if not targetId or targetId <= 0 then
        targetId = _source
    end
    
    TriggerEvent('th_sanguiris:stopBleed', targetId)
    
    TriggerClientEvent('th_coagulis:stopBleedRemote', -1, targetId)
    TriggerClientEvent('th_sanguiris:stopBleedFx', -1, targetId)
end)

CreateThread(function()
    while GetResourceState('th_power') ~= 'started' do
        Wait(100)
    end
    Wait(500)
    RegisterCoagulisModule()
end)

AddEventHandler('onResourceStart', function(resourceName)
    if resourceName == 'th_power' then
        Wait(1000)
        RegisterCoagulisModule()
    end
end)
