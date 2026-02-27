---@diagnostic disable: trailing-space
local function GetCasterLevel(sourceId)
    local ok, hasSpell, level = pcall(function()
        return exports['dvr_power']:GetSpell(sourceId, 'cruorax')
    end)

    if ok and hasSpell then
        return math.floor(tonumber(level) or 0)
    end

    return 0
end

local function CalculateCruoraxDuration(level)
    local maxDuration = Config.Cruorax.duration or 20000
    local minDuration = math.min(10000, maxDuration)
    local lvl = math.max(0, math.floor(tonumber(level) or 0))
    local ratio = math.min(lvl / 5.0, 1.0)

    return math.floor(minDuration + ((maxDuration - minDuration) * ratio))
end

RegisterNetEvent('dvr_cruorax:applyEffect', function(targetServerId, spellLevelFromClient)
    local _source <const> = source

    local spellLevel <const> = spellLevelFromClient or GetCasterLevel(_source)
    local duration <const> = CalculateCruoraxDuration(spellLevel)

    if targetServerId and targetServerId > 0 then
        if exports['dvr_prothea'] and exports['dvr_prothea'].hasActiveShield and exports['dvr_prothea']:hasActiveShield(targetServerId) then
            print(string.format('[Cruorax] annulé par Prothea pour %s', targetServerId))
            return
        end

        TriggerClientEvent('dvr_cruorax:applySurrender', targetServerId, duration, spellLevel)

        SetTimeout(duration, function()
            TriggerClientEvent('dvr_cruorax:removeSurrender', targetServerId)
        end)

        print(string.format('[Cruorax] Player %s surrendered for %dms (lvl %d)', targetServerId, duration, spellLevel))
    end
end)

RegisterNetEvent('dvr_cruorax:broadcastProjectile', function(finalTargetCoords, spellLevelFromClient, targetServerId, projectileType)
    local _source <const> = source
    if not finalTargetCoords then
        return
    end

    local spellLevel <const> = spellLevelFromClient or GetCasterLevel(_source)
    local duration <const> = CalculateCruoraxDuration(spellLevel)

    TriggerClientEvent('dvr_cruorax:fireProjectile', -1, _source, finalTargetCoords, targetServerId, spellLevel, duration, projectileType or 1)
end)

RegisterNetEvent('dvr_cruorax:playSecondAnimation', function()
    local _source <const> = source
    TriggerClientEvent('dvr_cruorax:playSecondAnim', _source)
    TriggerClientEvent('dvr_cruorax:otherPlayerSecondAnim', -1, _source)
end)

RegisterNetEvent('dvr_cruorax:surrenderPlayer', function(targetServerId)
    local _source <const> = source
    if not targetServerId or targetServerId <= 0 then
        return
    end

    if exports['dvr_prothea'] and exports['dvr_prothea'].hasActiveShield and exports['dvr_prothea']:hasActiveShield(targetServerId) then
        print(string.format('[Cruorax] annulé par Prothea pour %s', targetServerId))
        return
    end

    local spellLevel <const> = GetCasterLevel(_source)
    local duration <const> = CalculateCruoraxDuration(spellLevel)

    TriggerClientEvent('dvr_cruorax:applySurrender', targetServerId, duration, spellLevel)

    SetTimeout(duration, function()
        TriggerClientEvent('dvr_cruorax:removeSurrender', targetServerId)
    end)

    print(string.format('[Cruorax] Player %s surrendered for %dms (lvl %d)', targetServerId, duration, spellLevel))
end)

local function RegisterCruoraxModule()
    local moduleData <const> = {
        id = 'cruorax',
        name = 'Cruorax',
        description = "Force la cible à se soumettre et à lever les mains en l'air, incapable de résister pendant un court instant.",
        icon = 'hands',
        color = 'yellow',
        cooldown = Config.Cruorax.cooldown or 25000,
        type = 'offensive',
        level = 3,
        unforgivable = false,
        sound = '',
        soundType = "3d",
        key = nil,
        image = "images/power/dvr_cruorax.png",
        professor = false,
        animation = {
            dict = Config.Animation.dict,
            name = Config.Animation.name,
            flag = Config.Animation.flag,
            duration = Config.Animation.duration,
            speedMultiplier = Config.Animation.speedMultiplier,
        },
        onCast = function(hasItem, raycast, source, target, level)
            if not hasItem then
                TriggerClientEvent('ox_lib:notify', source, {
                    title = 'Cruorax',
                    description = 'Vous n\'avez pas de baguette équipée',
                    type = 'error',
                    icon = 'hands'
                })
                return false
            end

            local spellLevel <const> = level ~= nil and math.floor(tonumber(level) or 0) or GetCasterLevel(source)
            local data = {
                professor = { source = source },
                spell = { id = 'cruorax', name = 'Cruorax', level = spellLevel },
                context = { temp = false, coords = source and GetEntityCoords(GetPlayerPed(source)) or nil }
            }
            exports['dvr_power']:LogSpellCast(data)
            TriggerClientEvent('dvr_cruorax:otherPlayerCasting', -1, source)
            TriggerClientEvent('dvr_cruorax:prepareProjectile', source, spellLevel)
            return true
        end
    }

    exports['dvr_power']:registerModule(moduleData, 0)
    print('[dvr_cruorax] Module enregistré avec succès')
end

CreateThread(function()
    while GetResourceState('dvr_power') ~= 'started' do
        Wait(100)
    end

    Wait(500)
    RegisterCruoraxModule()
end)

AddEventHandler('onResourceStart', function(resourceName)
    if resourceName == 'dvr_power' then
        Wait(1000)
        RegisterCruoraxModule()
    end
end)
