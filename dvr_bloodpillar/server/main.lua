---@diagnostic disable: undefined-global, trailing-space, unused-local

local activeCasts = {}

local function Notify(sourceId, payload)
    if not payload then return end
    TriggerClientEvent('ox_lib:notify', sourceId, payload)
end

local function GetCasterLevel(sourceId)
    if exports['dvr_power'] and exports['dvr_power'].GetPlayerLevel then
        local ok, level = pcall(function()
            return exports['dvr_power']:GetPlayerLevel(sourceId)
        end)
        if ok and level then
            return math.floor(tonumber(level) or 1)
        end
    end
    return 1
end

RegisterNetEvent('dvr_bloodpillar:levitationExpired', function(targetServerId)
    local _source <const> = source
    if activeCasts[_source] and activeCasts[_source] == targetServerId then
        activeCasts[_source] = nil
    end
end)

RegisterNetEvent('dvr_bloodpillar:applyExpulsionDamage', function(impactCoords, spellLevel)
    local _source <const> = source
    if not impactCoords or not spellLevel then return end

    local damagePerLevel = Config.Damage and Config.Damage.perLevel or 50
    local damageRadius = Config.Damage and Config.Damage.radius or 3.0

    exports['dvr_power']:ApplySpellDamage(
        impactCoords,
        spellLevel,
        damagePerLevel,
        damageRadius,
        _source,
        'Blood Pillar',
        800
    )
end)

local function RegisterBloodpillarModule()
    local phase1Anim <const> = Config.Animation.phase1 or {}
    local levCfg <const> = Config.Levitation or {}

    local moduleData <const> = {
        id = Config.Module.id,
        name = Config.Module.name,
        description = Config.Module.description,
        icon = Config.Module.icon,
        color = Config.Module.color,
        cooldown = Config.Module.cooldown or 3000,
        type = Config.Module.type,
        isBasic = false,
        sound = Config.Sounds and Config.Sounds.cast and Config.Sounds.cast.url or '',
        soundType = "3d",
        image = Config.Module.image or "images/power/darkpunch.png",
        video = Config.Module.video or "",
        professor = Config.Module.professor ~= false,
        animation = {
            dict = phase1Anim.dict,
            name = phase1Anim.name,
            flag = phase1Anim.flag or 48,
            duration = phase1Anim.duration or 1000
        },
        onCast = function(hasItem, raycast, source, target, level)
            if not hasItem then
                Notify(source, Config.Messages and Config.Messages.noWand)
                return false
            end

            local spellLevel = level ~= nil and math.floor(tonumber(level) or 0) or GetCasterLevel(source)
            if spellLevel < 1 then spellLevel = 1 end
            if spellLevel > 5 then spellLevel = 5 end

            if not activeCasts[source] then
                if not target or target == -1 then
                    Notify(source, Config.Messages and Config.Messages.noTarget)
                    return false
                end

                if exports['dvr_prothea'] and exports['dvr_prothea'].hasActiveShield and exports['dvr_prothea']:hasActiveShield(target) then
                    return false
                end

                activeCasts[source] = target

                local duration = levCfg.duration or 6000
                local height = levCfg.height or 1.5

                TriggerClientEvent('dvr_bloodpillar:startLevitation', -1, target, source, duration, height, spellLevel)

                local casterSource = source
                SetTimeout(duration + 1000, function()
                    if activeCasts[casterSource] == target then
                        activeCasts[casterSource] = nil
                    end
                end)

                local data = {
                    professor = { source = source },
                    target = { source = target },
                    spell = { id = 'bloodpillar', name = 'Blood Pillar', level = spellLevel },
                    context = { temp = false, coords = source and GetEntityCoords(GetPlayerPed(source)) or nil }
                }
                exports['dvr_power']:LogSpellCast(data)

                return true
            else
                local expectedTarget = activeCasts[source]

                if target ~= expectedTarget then
                    Notify(source, Config.Messages and Config.Messages.wrongTarget)
                    return false
                end

                if exports['dvr_prothea'] and exports['dvr_prothea'].hasActiveShield and exports['dvr_prothea']:hasActiveShield(target) then
                    activeCasts[source] = nil
                    return false
                end

                activeCasts[source] = nil

                TriggerClientEvent('dvr_bloodpillar:playSecondAnim', source)
                TriggerClientEvent('dvr_bloodpillar:otherPlayerSecondAnim', -1, source)
                TriggerClientEvent('dvr_bloodpillar:expelTarget', -1, source, target, spellLevel)

                local data = {
                    professor = { source = source },
                    target = { source = target },
                    spell = { id = 'bloodpillar_expel', name = 'Blood Pillar (Expulsion)', level = spellLevel },
                    context = { temp = false, coords = source and GetEntityCoords(GetPlayerPed(source)) or nil }
                }
                exports['dvr_power']:LogSpellCast(data)

                return true
            end
        end
    }

    exports['dvr_power']:registerModule(moduleData, 0)
    print('[dvr_bloodpillar] Module enregistre avec succes')
end

CreateThread(function()
    while GetResourceState('dvr_power') ~= 'started' do
        Wait(100)
    end
    Wait(500)
    RegisterBloodpillarModule()
end)

AddEventHandler('onResourceStart', function(resourceName)
    if resourceName == 'dvr_power' then
        Wait(1000)
        RegisterBloodpillarModule()
    end
end)
