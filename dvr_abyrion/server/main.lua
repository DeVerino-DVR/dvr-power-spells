---@diagnostic disable: undefined-global, trailing-space, unused-local
local activeCircles = {}

local function GetLevelConfig(level)
    local lvl = tonumber(level) or 1
    if lvl < 1 then lvl = 1 end
    if lvl > 5 then lvl = 5 end
    return Config.Levels[lvl]
end

local function Notify(source, payload)
    if not payload then return end
    TriggerClientEvent('ox_lib:notify', source, payload)
end

local playerCircles = {}

RegisterNetEvent('dvr_abyrion:cast', function(coords, level)
    local _source = source

    if not coords then return end

    local lvl = tonumber(level) or 1
    local levelConfig = GetLevelConfig(lvl)

    if lvl == 5 and playerCircles[_source] then
        local existingCircleId = playerCircles[_source]
        activeCircles[existingCircleId] = nil
        playerCircles[_source] = nil
        TriggerClientEvent('dvr_abyrion:destroyCircle', -1, existingCircleId, true)
        TriggerClientEvent('ox_lib:notify', _source, {
            title = 'Abyrion',
            description = 'Le cercle de flammes a ete dissipe.',
            type = 'info',
            icon = 'fire'
        })
        return
    end

    local circleId = ('abyrion_%s_%s'):format(_source, os.time())

    activeCircles[circleId] = {
        id = circleId,
        sourceId = _source,
        coords = coords,
        level = lvl,
        startTime = os.time(),
        duration = levelConfig.duration
    }

    if lvl == 5 then
        playerCircles[_source] = circleId
    end

    TriggerClientEvent('dvr_abyrion:spawnCircle', -1, _source, coords, lvl, circleId)

    if lvl < 5 then
        SetTimeout(levelConfig.duration, function()
            activeCircles[circleId] = nil
            TriggerClientEvent('dvr_abyrion:destroyCircle', -1, circleId)
        end)
    end
end)

RegisterNetEvent('dvr_abyrion:playerBurning', function(targetServerId, duration)
    TriggerClientEvent('dvr_abyrion:showBurningFx', -1, targetServerId, duration)
end)

local function RegisterAbyrionModule()
    local animCfg = Config.Animation or {}

    local moduleData = {
        id = Config.Module.id,
        name = Config.Module.name,
        description = Config.Module.description,
        icon = Config.Module.icon,
        color = Config.Module.color,
        cooldown = Config.Module.cooldown or 20000,
        type = Config.Module.type,
        isBasic = false,
        key = Config.Module.key,
        sound = nil,
        soundType = nil,
        image = Config.Module.image or "images/power/dvr_abyrion.png",
        video = Config.Module.video,
        professor = Config.Module.professor ~= false,
        noWandTrail = Config.Module.noWandTrail ~= false,
        animation = {
            dict = animCfg.dict or 'export@nib@wizardsv_wand_attack_3',
            name = animCfg.name or 'nib@wizardsv_wand_attack_3',
            flag = animCfg.flag or 0,
            duration = animCfg.duration or 3000,
            speedMultiplier = animCfg.speedMultiplier or 5.0
        },
        onCast = function(hasItem, raycast, source, target, level)
            if not hasItem then
                Notify(source, Config.Messages and Config.Messages.noWand)
                return false
            end

            local spellLevel = level ~= nil and math.floor(tonumber(level) or 1) or 1
            if spellLevel < 1 then spellLevel = 1 end
            if spellLevel > 5 then spellLevel = 5 end

            -- Check if this is a level 5 toggle-off (player already has a circle)
            local isToggleOff = spellLevel == 5 and playerCircles[source] ~= nil

            local data = {
                professor = { source = source },
                spell = { id = 'abyrion', name = 'Abyrion', level = spellLevel },
                context = { temp = false, coords = source and GetEntityCoords(GetPlayerPed(source)) or nil }
            }

            pcall(function()
                exports['dvr_power']:LogSpellCast(data)
            end)

            if not isToggleOff then
                TriggerClientEvent('dvr_abyrion:otherPlayerCasting', -1, source)
            end

            TriggerClientEvent('dvr_abyrion:prepare', source, spellLevel, isToggleOff)

            return true
        end
    }

    exports['dvr_power']:registerModule(moduleData, 0)
    print('[dvr_abyrion] Module enregistre avec succes')
end

CreateThread(function()
    while GetResourceState('dvr_power') ~= 'started' do
        Wait(100)
    end

    Wait(500)
    RegisterAbyrionModule()
end)

AddEventHandler('onResourceStart', function(resourceName)
    if resourceName == 'dvr_power' then
        Wait(1000)
        RegisterAbyrionModule()
    end
end)

AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end

    activeCircles = {}
    playerCircles = {}
end)
