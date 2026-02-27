---@diagnostic disable: undefined-global, trailing-space, unused-local
RegisterNetEvent('th_basic:broadcastProjectile', function(finalTargetCoords)
    local _source <const> = source
    if not finalTargetCoords then
        return
    end
    
    TriggerClientEvent('th_basic:fireProjectile', -1, _source, finalTargetCoords)
end)

local DAMAGE_PERCENTAGES <const> = {
    [1] = 0.10,
    [2] = 0.20,
    [3] = 0.30,
    [4] = 0.40,
    [5] = 0.50
}

local function GetRaycastTarget(raycastData, targetId)
    if raycastData and type(raycastData.entityHit) == 'number' and raycastData.entityHit > 0 then
        return raycastData.entityHit
    end

    if type(targetId) == 'number' and targetId > 0 then
        return targetId
    end

    return nil
end

local function RegisterBasicModule()
    local moduleData <const> = {
        id = Config.Module.id,
        name = Config.Module.name,
        description = Config.Module.description,
        icon = Config.Module.icon,
        color = Config.Module.color,
        cooldown = Config.Module.cooldown or 3000,
        type = Config.Module.type,
        isBasic = false,
        key = nil,
        soundType = "3d",
        image = Config.Module.image or "images/power/ljump.png",
        video = Config.Module.video or "YOUR_VIDEO_URL_HERE",
        professor = Config.Module.professor ~= false,
        animation = {
            dict = 'export@nib@wizardsv_avada_kedrava',
            name = 'nib@wizardsv_avada_kedrava',
            flag = 0,
            duration = 3000,
            speedMultiplier = 3.5
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

            local targetId = GetRaycastTarget(raycast, target)
            if targetId and raycast and raycast.hit then
                TriggerClientEvent('th_basic:removeHealth', targetId, level)
            end

            local spellLevel = level ~= nil and math.floor(tonumber(level) or 0) or GetCasterLevel(source)
            local data = {
                professor = { source = source },
                --target = { source = target }, -- f
                spell = { id = 'basic', name = 'Basic', level = spellLevel },
                context = { temp = false, coords = source and GetEntityCoords(GetPlayerPed(source)) or nil}
            }
            exports['th_power']:LogSpellCast(data)
            
            TriggerClientEvent('th_basic:otherPlayerCasting', -1, source)
            TriggerClientEvent('th_basic:prepareProjectile', source)
            return true
        end
    }

    exports['th_power']:registerModule(moduleData, 0)
    print('[th_basic] Module enregistré avec succès')
end

CreateThread(function()
    while GetResourceState('th_power') ~= 'started' do
        Wait(100)
    end
    
    Wait(500)
    RegisterBasicModule()
end)

AddEventHandler('onResourceStart', function(resourceName)
    if resourceName == 'th_power' then
        Wait(1000)
        RegisterBasicModule()
    end
end)
