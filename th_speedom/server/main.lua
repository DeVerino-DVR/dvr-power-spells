---@diagnostic disable: undefined-global, trailing-space, unused-local
local function Notify(sourceId, payload)
    if not payload then
        return
    end
    TriggerClientEvent('ox_lib:notify', sourceId, payload)
end

RegisterNetEvent('th_speedom:applySpeed', function(targetServerId)
    local _source <const> = source
    local target = targetServerId and targetServerId > 0 and targetServerId or _source
    TriggerClientEvent('th_speedom:grantSpeed', target, Config.Buff.duration or 30000, _source ~= target)
end)

local function RegisterSpeedomModule()
    local moduleData <const> = {
        id = Config.Module.id,
        name = Config.Module.name,
        description = Config.Module.description,
        icon = Config.Module.icon,
        color = Config.Module.color,
        cooldown = Config.Module.cooldown or 10000,
        type = Config.Module.type,
        isBasic = false,
        key = Config.Module.key,
        sound = '',
        soundType = "3d",
        image = Config.Module.image or "images/power/ljump.png",
        video = Config.Module.video or "YOUR_VIDEO_URL_HERE",
        professor = Config.Module.professor ~= false,
        animation = {
            dict = 'export@nib@wizardsv_wand_attack_b2',
            name = 'nib@wizardsv_wand_attack_b2',
            flag = 0,
            duration = 1500
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
                spell = { id = 'speedom', name = 'Speedom', level = spellLevel },
                context = { temp = false, coords = source and GetEntityCoords(GetPlayerPed(source)) or nil}
            }
            exports['th_power']:LogSpellCast(data)
            TriggerClientEvent('th_speedom:otherPlayerCasting', -1, source)
            TriggerClientEvent('th_speedom:prepareSpeed', source, target or 0)
            return true
        end
    }

    exports['th_power']:registerModule(moduleData, 0)
    print('[th_speedom] Module enregistré avec succès')
end

CreateThread(function()
    while GetResourceState('th_power') ~= 'started' do
        Wait(100)
    end

    Wait(500)
    RegisterSpeedomModule()
end)

AddEventHandler('onResourceStart', function(resourceName)
    if resourceName == 'th_power' then
        Wait(1000)
        RegisterSpeedomModule()
    end
end)
