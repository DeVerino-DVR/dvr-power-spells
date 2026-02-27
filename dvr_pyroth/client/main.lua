---@diagnostic disable: undefined-global, trailing-space, unused-local, param-type-mismatch, missing-parameter, deprecated
local RequestNamedPtfxAsset = RequestNamedPtfxAsset
local HasNamedPtfxAssetLoaded = HasNamedPtfxAssetLoaded
local UseParticleFxAsset = UseParticleFxAsset
local UseParticleFxAssetNextCall = UseParticleFxAssetNextCall
local StartNetworkedParticleFxLoopedOnEntity = StartNetworkedParticleFxLoopedOnEntity
local StartParticleFxLoopedOnEntity = StartParticleFxLoopedOnEntity
local StartParticleFxLoopedAtCoord = StartParticleFxLoopedAtCoord
local StartParticleFxNonLoopedAtCoord = StartParticleFxNonLoopedAtCoord
local SetParticleFxLoopedAlpha = SetParticleFxLoopedAlpha
local StopParticleFxLooped = StopParticleFxLooped
local RemoveParticleFx = RemoveParticleFx
local RemoveNamedPtfxAsset = RemoveNamedPtfxAsset
local DeleteObject = DeleteObject
local DeleteEntity = DeleteEntity
local DoesEntityExist = DoesEntityExist
local GetGameTimer = GetGameTimer
local GetGameplayCamCoord = GetGameplayCamCoord
local GetGameplayCamRot = GetGameplayCamRot
local GetPedBoneIndex = GetPedBoneIndex
local GetWorldPositionOfEntityBone = GetWorldPositionOfEntityBone
local GetEntityCoords = GetEntityCoords
local SetEntityCoords = SetEntityCoords
local SetEntityRotation = SetEntityRotation
local SetEntityCollision = SetEntityCollision
local SetEntityAsMissionEntity = SetEntityAsMissionEntity
local SetEntityCompletelyDisableCollision = SetEntityCompletelyDisableCollision
local SetEntityVisible = SetEntityVisible
local SetEntityAlpha = SetEntityAlpha
local GetPlayerFromServerId = GetPlayerFromServerId
local GetPlayerPed = GetPlayerPed
local GetPlayerServerId = GetPlayerServerId
local PlayerId = PlayerId
local GetHashKey = GetHashKey
local CreateObject = CreateObject
local ShakeGameplayCam = ShakeGameplayCam
local StartScreenEffect = StartScreenEffect
local StopScreenEffect = StopScreenEffect
local StartParticleFxLoopedOnPedBone = StartParticleFxLoopedOnPedBone
local PlayerPedId = PlayerPedId
local GetCurrentPedWeaponEntityIndex = GetCurrentPedWeaponEntityIndex

local pyrothProjectiles = {}
local activeFlameZones = {}
local wandParticles = {}
local projectileFx = {}
local playerBurnHandle = nil
local playerBurnEndTime = 0

-- Convertit rotation en direction
local function RotationToDirection(rotation)
    local adjustedRotation <const> = {
        x = (math.pi / 180) * rotation.x,
        y = (math.pi / 180) * rotation.y,
        z = (math.pi / 180) * rotation.z
    }
    local direction <const> = {
        x = -math.sin(adjustedRotation.z) * math.abs(math.cos(adjustedRotation.x)),
        y = math.cos(adjustedRotation.z) * math.abs(math.cos(adjustedRotation.x)),
        z = math.sin(adjustedRotation.x)
    }
    return direction
end

-- Calcule les timings d'animation
local function GetAnimationTimings()
    local animConfig = Config.Animation or {}
    local speedMult = animConfig.speedMultiplier or 1.0
    if speedMult <= 0.0 then
        speedMult = 1.0
    end

    local propsDelay = animConfig.propsDelay or 2100
    local duration = animConfig.duration or 3000
    local scaledDelay = math.floor(propsDelay / speedMult)
    local scaledDuration = math.max(scaledDelay, math.floor(duration / speedMult))
    local cleanupDelay = math.max(0, scaledDuration - scaledDelay)

    return scaledDelay, cleanupDelay, scaledDuration
end

-- Récupère les paramètres de flammes selon le niveau
local function GetFlameSettingsForLevel(level)
    local lvl = math.max(1, math.min(5, math.floor(tonumber(level) or 1)))
    return Config.FlameSettings[lvl] or Config.FlameSettings[1]
end

-- Arrête les particules de baguette
local function StopWandParticles(playerPed)
    local handles = wandParticles[playerPed]
    if not handles then return end

    if handles.trail then
        StopParticleFxLooped(handles.trail, false)
        RemoveParticleFx(handles.trail, false)
    end
    wandParticles[playerPed] = nil
end

-- Crée les particules de baguette (trail rouge)
local function CreateWandParticles(playerPed, isNetworked)
    local weapon = GetCurrentPedWeaponEntityIndex(playerPed)
    if not weapon or not DoesEntityExist(weapon) then
        return nil
    end

    RequestNamedPtfxAsset('core')
    while not HasNamedPtfxAssetLoaded('core') do
        Wait(0)
    end
    UseParticleFxAsset('core')

    local trailHandle
    if isNetworked then
        trailHandle = StartNetworkedParticleFxLoopedOnEntity(
            'veh_light_red_trail', weapon, 
            0.75, 0.0, 0.05, 
            0.0, 0.0, 0.0, 
            0.45, false, false, false
        )
    else
        trailHandle = StartParticleFxLoopedOnEntity(
            'veh_light_red_trail', weapon, 
            0.75, 0.0, 0.05, 
            0.0, 0.0, 0.0, 
            0.45, false, false, false
        )
    end

    wandParticles[playerPed] = {
        trail = trailHandle
    }

    return trailHandle
end

-- Démarre le trail du projectile
local function StartProjectileTrail(prop)
    if not prop or not DoesEntityExist(prop) then return end

    RequestNamedPtfxAsset('core')
    while not HasNamedPtfxAssetLoaded('core') do
        Wait(0)
    end
    UseParticleFxAsset('core')

    local trail = StartNetworkedParticleFxLoopedOnEntity(
        Config.Projectile.trailParticle or 'veh_light_red_trail',
        prop,
        0.35, 0.0, 0.1,
        0.0, 0.0, 0.0,
        Config.Projectile.trailScale or 0.55,
        false, false, false
    )

    projectileFx[prop] = { trail = trail }
end

-- Nettoie le FX du projectile
local function CleanupProjectileFx(prop)
    local fxHandles = projectileFx[prop]
    if fxHandles then
        if fxHandles.trail then
            StopParticleFxLooped(fxHandles.trail, false)
            RemoveParticleFx(fxHandles.trail, false)
        end
    end
    projectileFx[prop] = nil
end

-- Joue le son d'impact
local function PlayImpactSound(coords)
    local soundCfg = Config.ImpactSound
    if not soundCfg or not soundCfg.url then return end

    -- REPLACE WITH YOUR SOUND SYSTEM
    -- exports['lo_audio']:playSound({
    -- id = ('dvr_pyrodvr_impact_%s'):format(GetGameTimer()),
    -- url = soundCfg.url,
    -- volume = soundCfg.volume or 0.8,
    -- loop = false,
    -- spatial = true,
    -- distance = 15.0,
    -- pos = {
    -- x = coords.x,
    -- y = coords.y,
    -- z = coords.z
    -- }
    -- })
end

-- Nettoie une zone de flammes
local function ClearFlameZone(zone)
    if not zone or not zone.flames then
        return
    end

    for _, flame in ipairs(zone.flames) do
        if flame then
            StopParticleFxLooped(flame, 0)
            RemoveParticleFx(flame, false)
        end
    end

    zone.flames = {}
end

-- Crée la zone de flammes au sol (effet Pyroth)
local function SpawnFlameZone(coords, level, sourceServerId)
    local settings = GetFlameSettingsForLevel(level)
    local radius = settings.radius
    local duration = settings.duration
    local flameScale = settings.flameScale
    local innerFlames = settings.innerFlames
    local outerFlames = settings.outerFlames

    -- Charger les assets de particules
    RequestNamedPtfxAsset('core')
    while not HasNamedPtfxAssetLoaded('core') do
        Wait(0)
    end

    local flames = {}
    local primaryPtfx = Config.FlameParticles.primary
    local secondaryPtfx = Config.FlameParticles.secondary
    local smokePtfx = Config.FlameParticles.smoke

    -- Flammes centrales (ent_sht_flame)
    UseParticleFxAssetNextCall('core')
    local centerFlame = StartParticleFxLoopedAtCoord(
        primaryPtfx.name, 
        coords.x, coords.y, coords.z + primaryPtfx.offsetZ, 
        0.0, 0.0, 0.0, 
        flameScale * 1.5, 
        false, false, false, false
    )
    if centerFlame then
        SetParticleFxLoopedAlpha(centerFlame, 1.0)
        flames[#flames + 1] = centerFlame
    end

    -- Faisceau de feu central (ent_amb_fbi_fire_beam)
    UseParticleFxAssetNextCall('core')
    local beamFlame = StartParticleFxLoopedAtCoord(
        secondaryPtfx.name, 
        coords.x, coords.y, coords.z + secondaryPtfx.offsetZ, 
        0.0, 0.0, 0.0, 
        flameScale * 1.2, 
        false, false, false, false
    )
    if beamFlame then
        flames[#flames + 1] = beamFlame
    end

    -- Flammes intérieures en cercle
    for i = 1, innerFlames do
        local angle = (i / innerFlames) * 2 * math.pi
        local x = coords.x + (math.cos(angle) * (radius * 0.4))
        local y = coords.y + (math.sin(angle) * (radius * 0.4))
        local z = coords.z + 0.05

        UseParticleFxAssetNextCall('core')
        local flame = StartParticleFxLoopedAtCoord(
            primaryPtfx.name, x, y, z, 
            0.0, 0.0, 0.0, 
            flameScale * 0.9, 
            false, false, false, false
        )
        if flame then
            SetParticleFxLoopedAlpha(flame, 1.0)
            flames[#flames + 1] = flame
        end
    end

    -- Flammes extérieures en cercle (limite de la zone)
    for i = 1, outerFlames do
        local angle = (i / outerFlames) * 2 * math.pi
        local x = coords.x + (math.cos(angle) * radius)
        local y = coords.y + (math.sin(angle) * radius)
        local z = coords.z + 0.05

        UseParticleFxAssetNextCall('core')
        local flame = StartParticleFxLoopedAtCoord(
            primaryPtfx.name, x, y, z, 
            0.0, 0.0, 0.0, 
            flameScale * 0.7, 
            false, false, false, false
        )
        if flame then
            SetParticleFxLoopedAlpha(flame, 1.0)
            flames[#flames + 1] = flame
        end
    end

    -- Fumée au centre
    UseParticleFxAssetNextCall('core')
    local smoke = StartParticleFxLoopedAtCoord(
        smokePtfx.name, 
        coords.x, coords.y, coords.z + smokePtfx.offsetZ, 
        0.0, 0.0, 0.0, 
        smokePtfx.scale * flameScale, 
        false, false, false, false
    )
    if smoke then
        flames[#flames + 1] = smoke
    end

    local zoneId = 'pyrodvr_' .. GetGameTimer()
    activeFlameZones[zoneId] = {
        flames = flames,
        coords = coords,
        endTime = GetGameTimer() + duration,
        level = level,
        sourceServerId = sourceServerId
    }

    -- Nettoyer après la durée
    SetTimeout(duration, function()
        ClearFlameZone(activeFlameZones[zoneId])
        activeFlameZones[zoneId] = nil
    end)

    -- Notifier le serveur pour les dégâts
    local myServerId = GetPlayerServerId(PlayerId())
    if sourceServerId == myServerId then
        TriggerServerEvent('dvr_pyroth:applyFlameDamage', coords, level, duration)
    end
end

-- Crée le projectile Pyroth
local function CreatePyrothProjectile(startCoords, targetCoords, sourceServerId, level)
    local projCfg = Config.Projectile or {}
    local propModel = GetHashKey(projCfg.model or 'nib_magic_ray_basic')
    lib.requestModel(propModel, 5000)

    local rayProp = CreateObject(propModel, startCoords.x, startCoords.y, startCoords.z, false, false, false)
    SetEntityCollision(rayProp, false, false)
    SetEntityAsMissionEntity(rayProp, true, true)
    SetEntityCompletelyDisableCollision(rayProp, false, false)
    SetEntityAlpha(rayProp, 255, false)

    local direction = vector3(
        targetCoords.x - startCoords.x,
        targetCoords.y - startCoords.y,
        targetCoords.z - startCoords.z
    )
    local distance = #direction
    if distance < 0.01 then distance = 0.01 end
    direction = direction / distance

    local heading = math.deg(math.atan2(direction.y, direction.x)) + 90.0
    local pitch = -math.deg(math.asin(direction.z))
    local roll = 0.0

    SetEntityCoords(rayProp, startCoords.x, startCoords.y, startCoords.z, false, false, false, false)
    SetEntityRotation(rayProp, pitch, roll, heading, 2, true)

    StartProjectileTrail(rayProp)

    local speed = projCfg.speed or 45.0
    local projDuration = (distance / speed) * 1000.0
    local startTime = GetGameTimer()
    local endTime = startTime + projDuration

    pyrothProjectiles[rayProp] = {
        prop = rayProp,
        startCoords = startCoords,
        targetCoords = targetCoords,
        direction = direction,
        distance = distance,
        startTime = startTime,
        endTime = endTime,
        heading = heading,
        pitch = pitch,
        roll = roll,
        sourceServerId = sourceServerId,
        level = level or 1
    }
end

-- Thread de mise à jour des projectiles
CreateThread(function()
    while true do
        Wait(1)

        local currentTime = GetGameTimer()

        for propId, data in pairs(pyrothProjectiles) do
            if type(data) == "table" then
                if DoesEntityExist(data.prop) then
                    if currentTime < data.endTime then
                        local progress = (currentTime - data.startTime) / (data.endTime - data.startTime)
                        progress = math.min(progress, 1.0)

                        local newPos = vector3(
                            data.startCoords.x + (data.direction.x * data.distance * progress),
                            data.startCoords.y + (data.direction.y * data.distance * progress),
                            data.startCoords.z + (data.direction.z * data.distance * progress)
                        )

                        SetEntityCoords(data.prop, newPos.x, newPos.y, newPos.z, false, false, false, false)
                        SetEntityRotation(data.prop, data.pitch, data.roll, data.heading, 2, true)
                    else
                        -- Arrivée à destination - déclencher les flammes
                        local propCoords = GetEntityCoords(data.prop)

                        PlayImpactSound(propCoords)
                        SpawnFlameZone(propCoords, data.level, data.sourceServerId)

                        -- Screen shake léger
                        ShakeGameplayCam('SMALL_EXPLOSION_SHAKE', 0.15)

                        CleanupProjectileFx(data.prop)
                        SetEntityVisible(data.prop, false, false)
                        SetEntityCoords(data.prop, 0.0, 0.0, -5000.0, false, false, false, false)
                        Wait(50)
                        DeleteEntity(data.prop)
                        DeleteObject(data.prop)

                        pyrothProjectiles[propId] = nil
                    end
                else
                    CleanupProjectileFx(data.prop)
                    pyrothProjectiles[propId] = nil
                end
            end
        end
    end
end)

-- Prépare le lancement du sort (côté lanceur)
RegisterNetEvent('dvr_pyroth:prepareCast', function(level)
    local casterPed = cache.ped

    CreateWandParticles(casterPed, true)

    local propsDelay, cleanupDelay, totalDuration = GetAnimationTimings()

    CreateThread(function()
        Wait(propsDelay)

        local handBone = GetPedBoneIndex(casterPed, Config.Projectile.handBone or 28422)
        local startCoords = GetWorldPositionOfEntityBone(casterPed, handBone)

        local camCoords = GetGameplayCamCoord()
        local camRot = GetGameplayCamRot(2)
        local direction = RotationToDirection(camRot)

        -- Raycast pour trouver le point d'impact
        local hit, entityHit, coords = lib.raycast.cam(1 | 2 | 4 | 8 | 16, 4, Config.Projectile.maxDistance or 1000.0)
        local finalTargetCoords

        if coords and (coords.x ~= 0.0 or coords.y ~= 0.0 or coords.z ~= 0.0) then
            finalTargetCoords = coords
        else
            finalTargetCoords = vector3(
                camCoords.x + direction.x * (Config.Projectile.maxDistance or 1000.0),
                camCoords.y + direction.y * (Config.Projectile.maxDistance or 1000.0),
                camCoords.z + direction.z * (Config.Projectile.maxDistance or 1000.0)
            )
        end

        TriggerServerEvent('dvr_pyroth:broadcastProjectile', finalTargetCoords, level or 1)

        Wait(cleanupDelay)
        StopWandParticles(casterPed)
    end)
end)

-- Affiche l'animation de cast pour les autres joueurs
RegisterNetEvent('dvr_pyroth:otherPlayerCasting', function(sourceServerId)
    local myServerId = GetPlayerServerId(PlayerId())

    if sourceServerId == myServerId then
        return
    end

    local casterPlayer = GetPlayerFromServerId(sourceServerId)
    if casterPlayer == -1 then
        return
    end

    local casterPed = GetPlayerPed(casterPlayer)
    if not DoesEntityExist(casterPed) then
        return
    end

    CreateWandParticles(casterPed, true)

    local _, _, totalDuration = GetAnimationTimings()
    SetTimeout(totalDuration, function()
        StopWandParticles(casterPed)
    end)
end)

-- Fait apparaître le projectile pour tous les joueurs
RegisterNetEvent('dvr_pyroth:fireProjectile', function(sourceServerId, targetCoords, level)
    local casterPlayer = GetPlayerFromServerId(sourceServerId)
    if casterPlayer == -1 then
        return
    end

    local casterPed = GetPlayerPed(casterPlayer)
    if not DoesEntityExist(casterPed) then
        return
    end

    local handBone = GetPedBoneIndex(casterPed, Config.Projectile.handBone or 28422)
    local startCoords = GetWorldPositionOfEntityBone(casterPed, handBone)

    CreatePyrothProjectile(startCoords, targetCoords, sourceServerId, level or 1)
end)

-- Applique l'effet de brûlure sur le joueur
RegisterNetEvent('dvr_pyroth:setPlayerOnFire', function(duration)
    local ped = PlayerPedId()
    local now = GetGameTimer()

    playerBurnEndTime = math.max(playerBurnEndTime, now + (duration or 3000))

    if playerBurnHandle then
        return
    end

    CreateThread(function()
        RequestNamedPtfxAsset('core')
        while not HasNamedPtfxAssetLoaded('core') do
            Wait(0)
        end

        UseParticleFxAssetNextCall('core')
        playerBurnHandle = StartParticleFxLoopedOnPedBone(
            'ent_sht_flame', ped, 
            0.0, 0.0, 0.0, 
            0.0, 0.0, 0.0, 
            GetPedBoneIndex(ped, 0), 
            0.6, false, false, false
        )

        while GetGameTimer() < playerBurnEndTime do
            ShakeGameplayCam('SMALL_EXPLOSION_SHAKE', 0.08)
            StartScreenEffect('RaceTurbo', 80, false)
            Wait(400)
        end

        if playerBurnHandle then
            StopParticleFxLooped(playerBurnHandle, 0)
            RemoveParticleFx(playerBurnHandle, false)
            playerBurnHandle = nil
        end

        StopScreenEffect('RaceTurbo')
    end)
end)

-- Nettoyage à l'arrêt de la ressource
AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end

    if playerBurnHandle then
        StopParticleFxLooped(playerBurnHandle, 0)
        RemoveParticleFx(playerBurnHandle, false)
        playerBurnHandle = nil
    end
    StopScreenEffect('RaceTurbo')

    for id, zone in pairs(activeFlameZones) do
        ClearFlameZone(zone)
        activeFlameZones[id] = nil
    end

    for ped, handles in pairs(wandParticles) do
        if handles.trail then
            StopParticleFxLooped(handles.trail, false)
            RemoveParticleFx(handles.trail, false)
        end
    end
    wandParticles = {}

    for prop, data in pairs(pyrothProjectiles) do
        if type(data) == "table" and DoesEntityExist(data.prop) then
            CleanupProjectileFx(data.prop)
            DeleteEntity(data.prop)
            DeleteObject(data.prop)
        end
    end
    pyrothProjectiles = {}

    for prop, fxHandles in pairs(projectileFx) do
        if fxHandles.trail then
            StopParticleFxLooped(fxHandles.trail, false)
            RemoveParticleFx(fxHandles.trail, false)
        end
    end
    projectileFx = {}

    RemoveNamedPtfxAsset('core')
end)
