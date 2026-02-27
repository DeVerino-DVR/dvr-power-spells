---@diagnostic disable: undefined-global, trailing-space, unused-local
local GetGameTimer = GetGameTimer
local vector3 = vector3

-- Récupère le niveau du sort du lanceur
local function GetCasterLevel(sourceId)
    local ok, hasSpell, level = pcall(function()
        return exports['dvr_power']:GetSpell(sourceId, 'pyroth')
    end)

    if ok and hasSpell then
        return math.max(1, math.min(5, math.floor(tonumber(level) or 1)))
    end

    return 1
end

-- Récupère les paramètres de flammes selon le niveau
local function GetFlameSettings(level)
    local lvl = math.max(1, math.min(5, math.floor(tonumber(level) or 1)))
    return Config.FlameSettings[lvl] or Config.FlameSettings[1]
end

-- Zones de flammes actives pour les dégâts continus
local activeFlameZones = {}

-- Thread de gestion des dégâts continus (toutes les 3 secondes)
CreateThread(function()
    while true do
        Wait(500) -- Check plus fréquent pour la précision
        local now = GetGameTimer()

        for zoneId, zone in pairs(activeFlameZones) do
            -- Vérifier si la zone a expiré
            if now >= zone.endAt then
                activeFlameZones[zoneId] = nil
                goto continue_zone
            end

            -- Vérifier l'intervalle de dégâts (3 secondes)
            local damageInterval = Config.Damage.damageInterval or 3000
            if (now - zone.lastDamageTick) < damageInterval then
                goto continue_zone
            end
            zone.lastDamageTick = now

            -- Appliquer les dégâts aux joueurs dans la zone
            local players = exports['dvr_power']:GetPlayersInRadius(
                zone.coords, 
                zone.radius, 
                zone.caster
            )

            if players then
                for _, playerData in ipairs(players) do
                    local playerId = playerData[1] or playerData.playerId
                    if playerId then
                        -- Appliquer les dégâts via ApplySpellDamage
                        exports['dvr_power']:ApplySpellDamage(
                            zone.coords,
                            zone.level,
                            zone.damagePerLevel,
                            zone.radius,
                            zone.caster,
                            'Pyroth (Brûlure)',
                            Config.Damage.protectionDuration or 500,
                            { ragdollDuration = 0 }
                        )
                        
                        -- Réappliquer l'effet de brûlure visuel
                        TriggerClientEvent('dvr_pyroth:setPlayerOnFire', playerId, zone.burnDuration or 3000)
                    end
                end
            end

            ::continue_zone::
        end
    end
end)

-- Reçoit la demande de broadcast du projectile
RegisterNetEvent('dvr_pyroth:broadcastProjectile', function(targetCoords, level)
    local _source = source
    if not _source then return end

    if not targetCoords then
        return
    end

    local spellLevel = level or GetCasterLevel(_source)

    -- Broadcast le projectile à tous les clients
    TriggerClientEvent('dvr_pyroth:fireProjectile', -1, _source, targetCoords, spellLevel)
end)

-- Applique les dégâts de la zone de flammes via le damage_system de dvr_power
RegisterNetEvent('dvr_pyroth:applyFlameDamage', function(flameCoords, level, duration)
    local _source = source
    
    if not flameCoords or not level then
        return
    end
    
    local settings = GetFlameSettings(level)
    local damagePerLevel = Config.Damage.perLevel or 30
    local protectionDuration = Config.Damage.protectionDuration or 500
    local coords = vector3(flameCoords.x, flameCoords.y, flameCoords.z)
    local now = GetGameTimer()
    
    -- Dégâts initiaux à l'impact
    exports['dvr_power']:ApplySpellDamage(
        coords,
        level,                    -- Niveau du sort (1-5)
        damagePerLevel,           -- Dégâts par niveau
        settings.radius,          -- Rayon de la zone
        _source,                  -- ID du lanceur
        'Pyroth',                 -- Nom du sort pour les logs
        protectionDuration,       -- Durée de protection en ms
        { ragdollDuration = 0 }   -- Pas de ragdoll
    )
    
    -- Appliquer l'effet de brûlure visuel initial sur les joueurs dans la zone
    local players = exports['dvr_power']:GetPlayersInRadius(coords, settings.radius, _source)
    
    if players then
        for _, playerData in ipairs(players) do
            local playerId = playerData[1] or playerData.playerId
            if playerId then
                TriggerClientEvent('dvr_pyroth:setPlayerOnFire', playerId, settings.burnDuration or 3000)
            end
        end
    end
    
    -- Créer la zone de flammes pour les dégâts continus
    local zoneId = 'pyroth_' .. _source .. '_' .. now
    activeFlameZones[zoneId] = {
        coords = coords,
        radius = settings.radius,
        level = level,
        damagePerLevel = damagePerLevel,
        burnDuration = settings.burnDuration,
        caster = _source,
        endAt = now + (duration or settings.duration),
        lastDamageTick = now  -- Le premier tick a déjà été appliqué
    }
end)

-- Enregistre le module Pyroth
local function RegisterPyrothModule()
    local animCfg = Config.Animation or {}
    local moduleData = {
        id = Config.Module.id or 'pyroth',
        name = Config.Module.name or 'Pyroth',
        description = Config.Module.description or "Fait jaillir des flammes du sol à l'impact.",
        icon = Config.Module.icon or 'fire',
        color = Config.Module.color or 'red',
        cooldown = Config.Module.cooldown or 4000,
        type = Config.Module.type or 'attack',
        isBasic = false,
        key = Config.Module.key,
        sound = 'YOUR_SOUND_URL_HERE',
        soundType = "3d",
        image = Config.Module.image or "images/power/infshock.png",
        video = Config.Module.video or "",
        professor = Config.Module.professor ~= false,
        animation = {
            dict = animCfg.dict or 'export@nib@wizardsv_avada_kedrava',
            name = animCfg.name or 'nib@wizardsv_avada_kedrava',
            flag = animCfg.flag or 0,
            duration = animCfg.duration or 3000,
            speedMultiplier = animCfg.speedMultiplier or 3.0
        },
        onCast = function(hasItem, raycast, source, target, level)
            if not hasItem then
                TriggerClientEvent('ox_lib:notify', source, Config.Messages and Config.Messages.noWand)
                return false
            end

            -- Vérifier qu'il y a une collision valide (sol, mur, objet)
            if not raycast or not raycast.hitCoords then
                TriggerClientEvent('ox_lib:notify', source, Config.Messages and Config.Messages.noTarget)
                return false
            end

            local spellLevel = level ~= nil and math.floor(tonumber(level) or 1) or GetCasterLevel(source)
            spellLevel = math.max(1, math.min(5, spellLevel))

            -- Log du cast
            local data = {
                professor = { source = source },
                spell = { id = 'pyroth', name = 'Pyroth', level = spellLevel },
                context = { temp = false, coords = source and GetEntityCoords(GetPlayerPed(source)) or nil }
            }
            exports['dvr_power']:LogSpellCast(data)

            -- Déclencher le cast sur le client
            TriggerClientEvent('dvr_pyroth:prepareCast', source, spellLevel)
            TriggerClientEvent('dvr_pyroth:otherPlayerCasting', -1, source)

            return true
        end
    }

    exports['dvr_power']:registerModule(moduleData, 0)
    print('[dvr_pyroth] Module Pyroth enregistré avec succès')
end

-- Attendre que dvr_power soit démarré
CreateThread(function()
    while GetResourceState('dvr_power') ~= 'started' do
        Wait(100)
    end

    Wait(500)
    RegisterPyrothModule()
end)

-- Re-enregistrer si dvr_power redémarre
AddEventHandler('onResourceStart', function(resourceName)
    if resourceName == 'dvr_power' then
        Wait(1000)
        RegisterPyrothModule()
    end
end)
