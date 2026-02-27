---@diagnostic disable: undefined-global, trailing-space, unused-local
local function Notify(sourceId, payload)
    if not payload then return end
    TriggerClientEvent('ox_lib:notify', sourceId, payload)
end

local function GetCasterLevel(sourceId)
    local ok, hasSpell, level = pcall(function()
        return exports['th_power']:GetSpell(sourceId, 'venafuria')
    end)
    if ok and hasSpell then
        return math.floor(tonumber(level) or 0)
    end
    return 0
end

RegisterNetEvent('th_venafuria:broadcastProjectile', function(targetCoords, targetId, level)
    local _source <const> = source
    if not targetCoords then return end
    TriggerClientEvent('th_venafuria:spawnProjectile', -1, _source, targetCoords, targetId or 0, level or 0)
end)

RegisterNetEvent('th_venafuria:applyEffect', function(impactCoords, targetId, level)
    local _source <const> = source

    if not targetId or targetId <= 0 then return end
    if targetId == _source then return end

    if exports['th_prothea'] and exports['th_prothea'].hasActiveShield and exports['th_prothea']:hasActiveShield(targetId) then
        print(string.format('[Vena Furia] effet annule par Prothea pour %s', targetId))
        return
    end

    local damagePerLevel = Config.Damage and Config.Damage.perLevel or 80
    local damageRadius = Config.Damage and Config.Damage.radius or 3.0

    exports['th_power']:ApplySpellDamage(
        impactCoords,
        level,
        damagePerLevel,
        damageRadius,
        _source,
        'Vena Furia',
        800
    )
end)

RegisterNetEvent('th_venafuria:triggerDrop', function(targetId)
    local _source <const> = source
    if not targetId or targetId <= 0 then return end
    TriggerClientEvent('th_venafuria:syncDrop', -1, targetId)
end)

RegisterNetEvent('th_venafuria:triggerSmash', function(targetId, smashNumber, totalSmashes)
    local _source <const> = source
    if not targetId or targetId <= 0 then return end
    -- Broadcast le smash à tous les clients
    TriggerClientEvent('th_venafuria:syncSmash', -1, targetId, smashNumber, totalSmashes)
end)

RegisterNetEvent('th_venafuria:bloodImpact', function(coords)
    local _source <const> = source
    if not coords then return end
    -- Broadcast l'explosion de sang à tous les clients
    TriggerClientEvent('th_venafuria:syncBloodImpact', -1, coords)
end)

local function RegisterVenaFuriaModule()
    local anim <const> = Config.Module.animation or {}
    local moduleData <const> = {
        id = Config.Module.id,
        name = Config.Module.name,
        description = Config.Module.description,
        icon = Config.Module.icon,
        color = Config.Module.color,
        cooldown = Config.Module.cooldown or 12000,
        type = Config.Module.type,
        isBasic = false,
        sound = Config.Sounds.cast.url,
        soundType = "3d",
        image = Config.Module.image or "images/power/th_venafuria.png",
        video = Config.Module.video or "",
        professor = Config.Module.professor ~= false,
        animation = {
            dict = anim.dict,
            name = anim.name,
            flag = anim.flag or 0,
            duration = anim.duration or 3000,
            speedMultiplier = anim.speedMultiplier or 1.5
        },
        onCast = function(hasItem, raycast, source, target, level)
            if not hasItem then
                Notify(source, Config.Messages and Config.Messages.noWand)
                return false
            end

            local targetId = tonumber(target)
            if not targetId or targetId <= 0 then
                Notify(source, Config.Messages and Config.Messages.noTarget)
                return false
            end

            local casterPed = GetPlayerPed(source)
            local targetPed = GetPlayerPed(targetId)
            if not casterPed or casterPed == 0 or not targetPed or targetPed == 0 then
                Notify(source, Config.Messages and Config.Messages.noTarget)
                return false
            end

            local casterCoords = GetEntityCoords(casterPed)
            local targetCoords = GetEntityCoords(targetPed)
            local distance = #(casterCoords - targetCoords)
            local maxDistance = Config.Projectile and Config.Projectile.maxDistance or 100.0

            if distance > maxDistance then
                Notify(source, Config.Messages and Config.Messages.outOfRange)
                return false
            end

            local spellLevel = level ~= nil and math.floor(tonumber(level) or 0) or GetCasterLevel(source)
            local data = {
                professor = { source = source },
                target = { source = targetId },
                spell = { id = 'venafuria', name = 'Vena Furia', level = spellLevel },
                context = { temp = false, coords = casterCoords }
            }
            exports['th_power']:LogSpellCast(data)

            TriggerClientEvent('th_venafuria:otherPlayerCasting', -1, source)
            TriggerClientEvent('th_venafuria:prepareProjectile', source, targetId, spellLevel)

            -- Lever la cible immédiatement dès le lancer du sort (broadcast à tous pour sync)
            if not (exports['th_prothea'] and exports['th_prothea'].hasActiveShield and exports['th_prothea']:hasActiveShield(targetId)) then
                TriggerClientEvent('th_venafuria:syncLevitation', -1, targetId, spellLevel, source)
            end

            return true
        end
    }

    exports['th_power']:registerModule(moduleData, 0)
    print('[th_venafuria] Module enregistre avec succes')
end

CreateThread(function()
    while GetResourceState('th_power') ~= 'started' do
        Wait(100)
    end
    Wait(500)
    RegisterVenaFuriaModule()
end)

AddEventHandler('onResourceStart', function(resourceName)
    if resourceName == 'th_power' then
        Wait(1000)
        RegisterVenaFuriaModule()
    end
end)
