---@diagnostic disable: undefined-global, trailing-space, unused-local

local function Notify(sourceId, payload)
    if not payload then
        return
    end

    TriggerClientEvent('ox_lib:notify', sourceId, payload)
end

RegisterNetEvent('th_firepillar:broadcastPillar', function(targetCoords, level)
    local _source <const> = source

    if not targetCoords then
        return
    end

    TriggerClientEvent('th_firepillar:spawnPillar', -1, _source, targetCoords, level or 0)
end)

RegisterNetEvent('th_firepillar:applyPillarDamage', function(pillarCoords, spellLevel)
    local _source <const> = source
    
    if not pillarCoords or not spellLevel then
        return
    end
    
    -- Use centralized damage system from th_power
    local damagePerLevel = Config.Damage and Config.Damage.perLevel or 50
    local damageRadius = Config.Damage and Config.Damage.radius or 5.0
    
    -- Fire pillar has longer duration, use 1000ms protection
    exports['th_power']:ApplySpellDamage(
        pillarCoords,
        spellLevel,
        damagePerLevel,
        damageRadius,
        _source,
        'Fire Pillar',
        1000
    )
end)

local function RegisterFirepillarModule()
    local animCfg <const> = Config.Animation or {}
    local moduleData <const> = {
        id = Config.Module.id,
        name = Config.Module.name,
        description = Config.Module.description,
        icon = Config.Module.icon,
        color = Config.Module.color,
        cooldown = Config.Module.cooldown or 3000,
        type = Config.Module.type,
        isBasic = false,
        key = Config.Module.key,
        sound = 'YOUR_SOUND_URL_HERE',
        soundType = "3d",
        image = Config.Module.image or "images/power/ljump.png",
        video = Config.Module.video or "YOUR_VIDEO_URL_HERE",
        professor = Config.Module.professor ~= false,
        animation = {
            dict = animCfg.dict or 'export@nib@wizardsv_avada_kedrava',
            name = animCfg.name or 'nib@wizardsv_avada_kedrava',
            flag = animCfg.flag or 0,
            duration = animCfg.duration or 3000,
            speedMultiplier = animCfg.speedMultiplier or 1.0
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
                spell = { id = 'firepillar', name = 'Firepillar', level = spellLevel },
                context = { temp = false, coords = source and GetEntityCoords(GetPlayerPed(source)) or nil}
            }
            exports['th_power']:LogSpellCast(data)

            TriggerClientEvent('th_firepillar:otherPlayerCasting', -1, source)
            TriggerClientEvent('th_firepillar:preparePillar', source, level or 0)
            return true
        end
    }

    exports['th_power']:registerModule(moduleData, 0)
    print('[th_firepillar] Module enregistré avec succès')
end

CreateThread(function()
    while GetResourceState('th_power') ~= 'started' do
        Wait(100)
    end

    Wait(500)
    RegisterFirepillarModule()
end)

AddEventHandler('onResourceStart', function(resourceName)
    if resourceName == 'th_power' then
        Wait(1000)
        RegisterFirepillarModule()
    end
end)
