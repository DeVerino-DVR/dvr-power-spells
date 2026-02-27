---@diagnostic disable: undefined-global, trailing-space
local GetGameTimer = GetGameTimer
local vector3 = vector3

local activeEffects = {}
local pendingProjectiles = {}

local function GetCasterLevel(sourceId)
    local ok, hasSpell, level = pcall(function()
        return exports['dvr_power']:GetSpell(sourceId, 'firedrix')
    end)

    if ok and hasSpell then
        return math.floor(tonumber(level) or 0)
    end

    return 0
end

local function BuildFireSettings(level)
    local lvl = math.max(0, math.floor(tonumber(level) or 0))
    local ratio = math.min(lvl / 5.0, 1.0)

    local maxRadius = (Config.FireCircle and Config.FireCircle.radius) or 3.0
    local minRadius = 1.5
    local maxDuration = (Config.FireCircle and Config.FireCircle.duration) or 1000
    local minDuration = 600
    local maxDamage = (Config.Damage and Config.Damage.damageOverTime) or 5
    local minDamage = 1
    local damageInterval = (Config.Damage and Config.Damage.damageInterval) or 500

    return {
        radius = minRadius + ((maxRadius - minRadius) * ratio),
        duration = math.floor(minDuration + ((maxDuration - minDuration) * ratio)),
        damage = math.floor(minDamage + ((maxDamage - minDamage) * ratio)),
        damageInterval = damageInterval
    }
end

CreateThread(function()
    while true do
        Wait(150)
        local now = GetGameTimer()

        for effectId, effect in pairs(activeEffects) do
            if effect.endAt and now >= effect.endAt then
                activeEffects[effectId] = nil
                goto continue_effect
            end

            if effect.type ~= 'fireZone' then
                goto continue_effect
            end

            local interval = effect.damageInterval or 1000
            if (now - (effect.lastTick or 0)) < interval then
                goto continue_effect
            end
            effect.lastTick = now

            local players = GetPlayers()
            for _, player in ipairs(players) do
                local playerId = tonumber(player)
                if not playerId then goto continue_player end

                local playerPed = GetPlayerPed(playerId)
                if not DoesEntityExist(playerPed) then
                    goto continue_player
                end

                local playerCoords = GetEntityCoords(playerPed)
                if #(playerCoords - effect.coords) > effect.radius then
                    goto continue_player
                end

                local ok, applied = pcall(function()
                    return exports['dvr_power']:DealDamage(playerId, effect.damage, effect.caster or 0, 'firedrix')
                end)


                if ok and applied then
                    local lastNotify = effect.notified[playerId] or 0
                    if (now - lastNotify) >= 2000 then
                        TriggerClientEvent('dvr_incendrix:setPlayerOnFire', playerId, 3000)
                        effect.notified[playerId] = now
                    end
                elseif not ok and Config.Debug then
                    print(('[dvr_firedrix] Damage failed for %s: %s'):format(playerId or 'nil', applied or 'unknown'))
                end

                ::continue_player::
            end

            ::continue_effect::
        end
    end
end)

RegisterNetEvent('dvr_firedrix:broadcastProjectile', function(targetCoords, radius, duration)
    local source = source
    if not source then return end

    local pending = pendingProjectiles[source]
    if not pending then return end

    TriggerClientEvent('dvr_firedrix:fireProjectile', -1, source, targetCoords, pending.radius, pending.duration)

    local casterPed = GetPlayerPed(source)
    local casterCoords = casterPed and GetEntityCoords(casterPed) or nil

    if casterCoords and targetCoords then
        local distance = #(vector3(targetCoords.x, targetCoords.y, targetCoords.z) - casterCoords)
        local speed = (Config.Projectile and Config.Projectile.speed) or 80.0
        local travelTime = math.floor((distance / speed) * 1000)

        SetTimeout(travelTime, function()
            local fireId = 'fire_' .. source .. '_' .. GetGameTimer()
            local now = GetGameTimer()
            activeEffects[fireId] = {
                type = 'fireZone',
                coords = vector3(targetCoords.x, targetCoords.y, targetCoords.z),
                radius = pending.radius,
                damage = pending.damage,
                damageInterval = pending.damageInterval or 1000,
                endAt = now + pending.duration,
                lastTick = now,
                caster = source,
                notified = {}
            }
        end)
    end

    pendingProjectiles[source] = nil
end)

local function RegisterIncendioModule()
    local moduleData <const> = {
        id = 'firedrix',
        name = 'Firedrix',
        description = "Sortilège interdit traçant un cercle de flammes infernales, symbole de destruction.",
        icon = 'fire',
        color = 'orange',
        cooldown = 4000,
        type = 'attack',
        level = 2,
        castTime = 3000,
        image = "images/power/shell.png",
        video = "YOUR_VIDEO_URL_HERE",
        professor = false,
        noWandTrail = true,
        animation = {
            dict = 'export@nib@wizardsv_avada_kedrava',
            name = 'nib@wizardsv_avada_kedrava',
            flag = 0,
            speedMultiplier = 3.0,
            duration = 3000
        },
        effect = {
            particle = true,
            sound = 'incendio'
        },
        onCast = function(hasItem, raycast, source, target, level)
            if not hasItem then
                TriggerClientEvent('ox_lib:notify', source, {
                    title = 'Firedrix',
                    description = 'Vous n\'avez pas de baguette équipée',
                    type = 'error',
                    icon = 'fire'
                })
                return false
            end

            if not raycast or not raycast.hitCoords then
                TriggerClientEvent('ox_lib:notify', source, {
                    title = 'Firedrix',
                    description = 'Aucune cible détectée',
                    type = 'warning',
                    icon = 'fire'
                })
                return false
            end

            local spellLevel = level ~= nil and math.floor(tonumber(level) or 0) or GetCasterLevel(source)
            local settings = BuildFireSettings(spellLevel)

            local data = {
                professor = { source = source },
                spell = { id = 'firedrix', name = 'Firedrix', level = spellLevel },
                context = { temp = false, coords = source and GetEntityCoords(GetPlayerPed(source)) or nil}
            }
            exports['dvr_power']:LogSpellCast(data)

            pendingProjectiles[source] = {
                radius = settings.radius,
                duration = settings.duration,
                damage = settings.damage,
                damageInterval = settings.damageInterval
            }

            TriggerClientEvent('dvr_firedrix:prepareCast', source, settings.radius, settings.duration)
            TriggerClientEvent('dvr_firedrix:otherPlayerCasting', -1, source)

            return true
        end
    }

    exports['dvr_power']:registerModule(moduleData, 0)
    print('[dvr_firedrix] Module enregistré avec succès')
end

CreateThread(function()
    while GetResourceState('dvr_power') ~= 'started' do
        Wait(100)
    end

    Wait(500)
    RegisterIncendioModule()
end)

AddEventHandler('onResourceStart', function(resourceName)
    if resourceName == 'dvr_power' then
        Wait(1000)
        RegisterIncendioModule()
    end
end)
