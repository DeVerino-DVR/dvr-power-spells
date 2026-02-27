---@diagnostic disable: trailing-space
local function GetCasterLevel(sourceId)
    local ok, hasSpell, level = pcall(function()
        return exports['dvr_power']:GetSpell(sourceId, 'staturion')
    end)

    if ok and hasSpell then
        return math.floor(tonumber(level) or 0)
    end

    return 0
end

local function CalculatePetrifyDuration(level)
    local maxDuration = Config.Petrificus.duration or 15000
    local minDuration = math.min(5000, maxDuration)
    local lvl = math.max(0, math.floor(tonumber(level) or 0))
    local ratio = math.min(lvl / 5.0, 1.0)

    return math.floor(minDuration + ((maxDuration - minDuration) * ratio))
end

RegisterNetEvent('dvr_staturion:broadcastProjectile', function(finalTargetCoords, targetEntity)
    local _source <const> = source
    if not finalTargetCoords then
        return
    end

    local spellLevel <const> = GetCasterLevel(_source)
    local duration <const> = CalculatePetrifyDuration(spellLevel)
    
    TriggerClientEvent('dvr_staturion:fireProjectile', -1, _source, finalTargetCoords, targetEntity, spellLevel, duration)
end)

RegisterNetEvent('dvr_staturion:petrifyPlayer', function(targetServerId)
    local _source <const> = source
    if not targetServerId or targetServerId <= 0 then
        return
    end

    if exports['dvr_prothea'] and exports['dvr_prothea'].hasActiveShield and exports['dvr_prothea']:hasActiveShield(targetServerId) then
        print(string.format('[Petrificus] annulé par Prothea pour %s', targetServerId))
        return
    end

    local spellLevel <const> = GetCasterLevel(_source)
    local duration <const> = CalculatePetrifyDuration(spellLevel)
    
    TriggerClientEvent('dvr_staturion:applyPetrify', targetServerId, duration, spellLevel)
    
    SetTimeout(duration, function()
        TriggerClientEvent('dvr_staturion:removePetrify', targetServerId)
    end)
    
    print(string.format('[Petrificus] Player %s petrified for %dms (lvl %d)', targetServerId, duration, spellLevel))
end)

local function RegisterPetrificusModule()
    local moduleData <const> = {
        id = 'staturion',
        name = 'Staturion',
        description = "Fige une cible dans un état d’immobilité absolue, scellant également sa voix.",
        icon = 'snowflake',
        color = 'blue',
        cooldown = 20000,
        type = 'offensive',
        level = 4,
        unforgivable = false,
        sound = 'YOUR_SOUND_URL_HERE',
        soundType = "3d",
        key = nil,
        image = "images/power/shiftrift.png",
        video = "YOUR_VIDEO_URL_HERE",
        animation = {
            dict = 'export@nib@wizardsv_wand_attack_b2',
            name = 'nib@wizardsv_wand_attack_b2',
            flag = 0,
            duration = 2200,
            speedMultiplier = 1.5,
        },
        onCast = function(hasItem, raycast, source, target, level)
            if not hasItem then
                TriggerClientEvent('ox_lib:notify', source, {
                    title = 'Staturion',
                    description = 'Vous n\'avez pas de baguette équipée',
                    type = 'error',
                    icon = 'snowflake'
                })
                return false
            end

            local spellLevel <const> = level ~= nil and math.floor(tonumber(level) or 0) or GetCasterLevel(source)
            local spellLevel = level ~= nil and math.floor(tonumber(level) or 0) or GetCasterLevel(source)
            local data = {
                professor = { source = source },
                --target = { source = target }, -- f
                spell = { id = 'staturion', name = 'Staturion', level = spellLevel },
                context = { temp = false, coords = source and GetEntityCoords(GetPlayerPed(source)) or nil}
            }
            exports['dvr_power']:LogSpellCast(data)
            TriggerClientEvent('dvr_staturion:otherPlayerCasting', -1, source)
            TriggerClientEvent('dvr_staturion:prepareProjectile', source, spellLevel)
            return true
        end
    }

    exports['dvr_power']:registerModule(moduleData, 0)
    print('[dvr_staturion] Module enregistré avec succès')
end

CreateThread(function()
    while GetResourceState('dvr_power') ~= 'started' do
        Wait(100)
    end
    
    Wait(500)
    RegisterPetrificusModule()
end)

AddEventHandler('onResourceStart', function(resourceName)
    if resourceName == 'dvr_power' then
        Wait(1000)
        RegisterPetrificusModule()
    end
end)
