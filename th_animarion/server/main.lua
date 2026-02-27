---@diagnostic disable: trailing-space
local Config = require 'config'

local function GetCasterLevel(sourceId)
    local ok, hasSpell, level = pcall(function()
        return exports['th_power']:GetSpell(sourceId, 'animarion')
    end)

    if ok and hasSpell then
        return math.floor(tonumber(level) or 0)
    end

    return 0
end

local function CalculateTransformDuration(level)
    local maxDuration = Config.Animagus.duration or 30000
    local minDuration = math.floor(maxDuration * 0.2)
    local lvl = math.max(0, math.floor(tonumber(level) or 0))
    local ratio = math.min(lvl / 5.0, 1.0)

    return math.floor(minDuration + ((maxDuration - minDuration) * ratio))
end

RegisterNetEvent('th_animarion:broadcastProjectile', function(finalTargetCoords, targetEntity)
    local _source <const> = source
    if not finalTargetCoords then
        return
    end

    local spellLevel = GetCasterLevel(_source)
    local duration = CalculateTransformDuration(spellLevel)
    
    TriggerClientEvent('th_animarion:fireProjectile', -1, _source, finalTargetCoords, targetEntity, spellLevel, duration)
end)

RegisterNetEvent('th_animarion:transformPlayer', function(targetServerId)
    local _source <const> = source
    if not targetServerId or targetServerId <= 0 then
        return
    end

    if exports['th_prothea'] and exports['th_prothea'].hasActiveShield and exports['th_prothea']:hasActiveShield(targetServerId) then
        print(string.format('[Animagus] transformation annulée par Prothea pour %s', targetServerId))
        return
    end

    local spellLevel = GetCasterLevel(_source)
    local duration = CalculateTransformDuration(spellLevel)
    local randomAnimal <const> = Config.Animagus.animals[math.random(#Config.Animagus.animals)]
    
    if targetServerId and targetServerId ~= -1 then
        TriggerClientEvent('th_animarion:applyTransform', targetServerId, randomAnimal, duration, spellLevel)
        
        SetTimeout(duration, function()
            TriggerClientEvent('th_animarion:revertToHuman', targetServerId)
        end)
        
        print(string.format('[Animagus] Player %s transformed into %s (dur %sms lvl %d)', targetServerId, randomAnimal, duration, spellLevel))
    end
end)

RegisterNetEvent('th_animarion:revertTransform', function()
    local _source <const> = source
    
    TriggerClientEvent('th_animarion:revertToHuman', _source)
end)

local function RegisterAnimagusModule()
    local moduleData <const> = {
        id = 'animarion',
        name = 'Animarion',
        description = "Altère temporairement l’essence d’une cible vivante, la métamorphosant en animal.",
        icon = 'paw',
        color = 'orange',
        cooldown = 45000,
        type = 'utility',
        level = 5,
        unforgivable = false,
        key = nil,
        sound = 'YOUR_SOUND_URL_HERE',
        soundType = "3d",
        image = "images/power/bodymolt.png",
        video = "YOUR_VIDEO_URL_HERE",
        animation = {
            dict = Config.Animation.dict,
            name = Config.Animation.name,
            flag = Config.Animation.flag,
            speedMultiplier = Config.Animation.speedMultiplier,
            duration = Config.Animation.duration
        },
        onCast = function(hasItem, raycast, source, target, level)
            if not hasItem then
                TriggerClientEvent('ox_lib:notify', source, {
                    title = 'Animarion',
                    description = 'Vous n\'avez pas de baguette équipée',
                    type = 'error',
                    icon = 'paw'
                })
                return false
            end

            local spellLevel = level ~= nil and math.floor(tonumber(level) or 0) or GetCasterLevel(source)

            local data = {
                professor = { source = source },
                target = { source = target }, -- f
                spell = { id = 'animarion', name = 'Animarion', level = spellLevel },
                context = { temp = false, coords = source and GetEntityCoords(GetPlayerPed(source)) or nil}
            }
            exports['th_power']:LogSpellCast(data)
            
            TriggerClientEvent('th_animarion:otherPlayerCasting', -1, source)
            TriggerClientEvent('th_animarion:prepareProjectile', source, spellLevel)
            return true
        end
    }

    exports['th_power']:registerModule(moduleData, 0)
    print('[th_animarion] Module enregistré avec succès')
end

CreateThread(function()
    while GetResourceState('th_power') ~= 'started' do
        Wait(100)
    end
    
    Wait(500)
    RegisterAnimagusModule()
end)

AddEventHandler('onResourceStart', function(resourceName)
    if resourceName == 'th_power' then
        Wait(1000)
        RegisterAnimagusModule()
    end
end)
