---@diagnostic disable: undefined-global, trailing-space, unused-local
local function Notify(sourceId, payload)
    if not payload then
        return
    end

    TriggerClientEvent('ox_lib:notify', sourceId, payload)
end

RegisterNetEvent('dvr_waterpillar:broadcastProjectile', function(targetCoords, level)
    local _source <const> = source

    if not targetCoords then
        return
    end

    TriggerClientEvent('dvr_waterpillar:spawnPillar', -1, _source, targetCoords, level or 0)
end)

RegisterNetEvent('dvr_waterpillar:applyPillarDamage', function(pillarCoords, spellLevel)
    local _source <const> = source
    
    if not pillarCoords or not spellLevel then
        return
    end
    
    -- Use centralized damage system from dvr_power
    local damagePerLevel = Config.Damage and Config.Damage.perLevel or 80
    local damageRadius = Config.Damage and Config.Damage.radius or 5.0
    
    -- Water pillar has longer duration, use 1000ms protection
    exports['dvr_power']:ApplySpellDamage(
        pillarCoords,
        spellLevel,
        damagePerLevel,
        damageRadius,
        _source,
        'Water Pillar',
        1000
    )
end)

local function RegisterWaterpillarModule()
    local moduleData <const> = {
        id = Config.Module.id,
        name = Config.Module.name,
        description = Config.Module.description,
        icon = Config.Module.icon,
        color = Config.Module.color,
        cooldown = Config.Module.cooldown or 4000,
        type = Config.Module.type,
        isBasic = false,
        sound = 'YOUR_SOUND_URL_HERE',
        soundType = "3d",
        image = Config.Module.image or "images/power/ljump.png",
        video = Config.Module.video or "YOUR_VIDEO_URL_HERE",
        professor = Config.Module.professor ~= false,
        animation = {
            dict = 'export@nib@wizardsv_avada_kedrava',
            name = 'nib@wizardsv_avada_kedrava',
            flag = 0,
            duration = 3000,
            speedMultiplier = 2.5,
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
                spell = { id = 'waterpillar', name = 'Waterpillar', level = spellLevel },
                context = { temp = false, coords = source and GetEntityCoords(GetPlayerPed(source)) or nil}
            }
            
            exports['dvr_power']:LogSpellCast(data)
            TriggerClientEvent('dvr_waterpillar:otherPlayerCasting', -1, source)
            TriggerClientEvent('dvr_waterpillar:preparePillar', source, level or 0)
            return true
        end
    }

    exports['dvr_power']:registerModule(moduleData, 0)
    print('[dvr_waterpillar] Module enregistré avec succès')
end

CreateThread(function()
    while GetResourceState('dvr_power') ~= 'started' do
        Wait(100)
    end

    Wait(500)
    RegisterWaterpillarModule()
end)

AddEventHandler('onResourceStart', function(resourceName)
    if resourceName == 'dvr_power' then
        Wait(1000)
        RegisterWaterpillarModule()
    end
end)
