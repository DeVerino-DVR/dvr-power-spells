---@diagnostic disable: undefined-global, trailing-space, unused-local, param-type-mismatch, missing-parameter
local activeMeteors = {}
local activeSignalProjectiles = {}
local wandParticles = {}
local allParticles = {}
local activeGroundMarkers = {}

-- Native caching for performance
local RequestNamedPtfxAsset = RequestNamedPtfxAsset
local HasNamedPtfxAssetLoaded = HasNamedPtfxAssetLoaded
local UseParticleFxAsset = UseParticleFxAsset
local UseParticleFxAssetNextCall = UseParticleFxAssetNextCall
local StartParticleFxLoopedOnEntity = StartParticleFxLoopedOnEntity
local StartParticleFxLoopedAtCoord = StartParticleFxLoopedAtCoord
local StartNetworkedParticleFxLoopedOnEntity = StartNetworkedParticleFxLoopedOnEntity
local SetParticleFxLoopedColour = SetParticleFxLoopedColour
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
local GetPlayerFromServerId = GetPlayerFromServerId
local GetPlayerPed = GetPlayerPed
local GetPlayerServerId = GetPlayerServerId
local PlayerId = PlayerId
local GetHashKey = GetHashKey
local CreateObject = CreateObject
local ShakeGameplayCam = ShakeGameplayCam
local AddExplosion = AddExplosion

--- Check if player has Prothea shield active
local function HasProtheaShield()
    local hasShield = false
    if LocalPlayer and LocalPlayer.state then
        hasShield = LocalPlayer.state.protheaShield == true
    end
    if not hasShield and exports['dvr_prothea'] and exports['dvr_prothea'].hasLocalShield then
        local ok, result = pcall(function()
            return exports['dvr_prothea']:hasLocalShield()
        end)
        hasShield = ok and result == true
    end
    return hasShield
end

--- Convert camera rotation to direction vector
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

--- Stop and cleanup wand particle effect
local function StopWandTrail(playerPed)
    local handle = wandParticles[playerPed]
    if handle then
        StopParticleFxLooped(handle, false)
        RemoveParticleFx(handle, false)
        allParticles[handle] = nil
        wandParticles[playerPed] = nil
    end
end

--- Create glowing wand effect during cast
local function CreateWandParticles(playerPed, isNetworked)
    local weapon = GetCurrentPedWeaponEntityIndex and GetCurrentPedWeaponEntityIndex(playerPed)
    if not weapon or not DoesEntityExist(weapon) then
        return nil
    end

    RequestNamedPtfxAsset('core')
    while not HasNamedPtfxAssetLoaded('core') do
        Wait(0)
    end
    UseParticleFxAsset('core')

    local handle
    if isNetworked then
        handle = StartNetworkedParticleFxLoopedOnEntity('veh_light_clear', weapon, 0.95, 0.0, 0.1, 0.0, 0.0, 0.0, 0.6, false, false, false)
    else
        handle = StartParticleFxLoopedOnEntity('veh_light_clear', weapon, 0.95, 0.0, 0.1, 0.0, 0.0, 0.0, 0.6, false, false, false)
    end

    -- Orange/red color for meteor spell
    SetParticleFxLoopedColour(handle, 1.0, 0.35, 0.0, false)
    SetParticleFxLoopedAlpha(handle, 255)

    wandParticles[playerPed] = handle
    allParticles[handle] = { createdTime = GetGameTimer(), type = 'wandGlow' }
    return handle
end

--- Attach fire trail to signal projectile
local function AttachSignalTrail(prop)
    if not prop or not DoesEntityExist(prop) then
        return nil
    end

    RequestNamedPtfxAsset('core')
    while not HasNamedPtfxAssetLoaded('core') do
        Wait(0)
    end

    UseParticleFxAsset('core')
    UseParticleFxAssetNextCall('core')

    -- Main trail effect
    local trailHandle = StartParticleFxLoopedOnEntity(
        'veh_light_red_trail', prop,
        0.0, 0.0, 0.3, 0.0, 0.0, 0.0,
        0.8, false, false, false
    )

    if trailHandle then
        SetParticleFxLoopedColour(trailHandle, 1.0, 0.4, 0.0, false)
        SetParticleFxLoopedAlpha(trailHandle, 255.0)
        allParticles[trailHandle] = { createdTime = GetGameTimer(), type = 'signalTrail' }
    end

    -- Fire glow
    UseParticleFxAssetNextCall('core')
    local fireHandle = StartParticleFxLoopedOnEntity(
        'veh_light_clear', prop,
        0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
        0.5, false, false, false
    )

    if fireHandle then
        SetParticleFxLoopedColour(fireHandle, 1.0, 0.5, 0.0, false)
        allParticles[fireHandle] = { createdTime = GetGameTimer(), type = 'signalFire' }
    end

    return { trail = trailHandle, fire = fireHandle }
end

--- Attach fire trail to meteor prop
local function AttachMeteorTrail(meteorProp)
    if not meteorProp or not DoesEntityExist(meteorProp) then
        return nil
    end

    RequestNamedPtfxAsset('core')
    while not HasNamedPtfxAssetLoaded('core') do
        Wait(0)
    end

    UseParticleFxAsset('core')
    UseParticleFxAssetNextCall('core')

    -- Fire trail effect
    local trailHandle = StartParticleFxLoopedOnEntity(
        'veh_light_red_trail', meteorProp,
        0.0, 0.0, 0.5, 0.0, 0.0, 0.0,
        1.2, false, false, false
    )

    if trailHandle then
        SetParticleFxLoopedColour(trailHandle, 1.0, 0.3, 0.0, false)
        SetParticleFxLoopedAlpha(trailHandle, 255.0)
        allParticles[trailHandle] = { createdTime = GetGameTimer(), type = 'meteorTrail' }
    end

    -- Additional fire particles
    UseParticleFxAssetNextCall('core')
    local fireHandle = StartParticleFxLoopedOnEntity(
        'ent_ray_heli_aprtmnt_l_fire', meteorProp,
        0.0, 0.0, 0.2, 0.0, 0.0, 0.0,
        0.5, false, false, false
    )

    if fireHandle then
        allParticles[fireHandle] = { createdTime = GetGameTimer(), type = 'meteorFire' }
    end

    return { trail = trailHandle, fire = fireHandle }
end

--- Create ground marker when signal projectile arrives (simple, no smoke)
local function CreateGroundMarker(coords, level)
    RequestNamedPtfxAsset('core')
    while not HasNamedPtfxAssetLoaded('core') do
        Wait(0)
    end

    local handles = {}
    local levelConfig = Config.Levels[level] or Config.Levels[1]
    local spreadRadius = (Config.Meteor.spreadRadius or 8.0) * (levelConfig.spreadMult or 1.0)

    -- Simple glowing center (no smoke!)
    UseParticleFxAssetNextCall('core')
    local centerFx = StartParticleFxLoopedAtCoord(
        'ent_brk_sparking_wires', coords.x, coords.y, coords.z + 0.1,
        0.0, 0.0, 0.0, 1.0, false, false, false, false
    )
    if centerFx then
        handles[#handles + 1] = centerFx
        allParticles[centerFx] = { createdTime = GetGameTimer(), type = 'groundMarker' }
    end

    -- Small fire ring (just 4 points, no smoke)
    local ringPoints = 4
    for i = 1, ringPoints do
        local angle = ((i - 1) / ringPoints) * 2 * math.pi
        local ringRadius = spreadRadius * 0.5
        local px = coords.x + math.cos(angle) * ringRadius
        local py = coords.y + math.sin(angle) * ringRadius

        UseParticleFxAssetNextCall('core')
        local ringFx = StartParticleFxLoopedAtCoord(
            'ent_ray_heli_aprtmnt_l_fire', px, py, coords.z + 0.05,
            0.0, 0.0, 0.0, 0.25, false, false, false, false
        )
        if ringFx then
            handles[#handles + 1] = ringFx
            allParticles[ringFx] = { createdTime = GetGameTimer(), type = 'groundMarker' }
        end
    end

    return handles
end

--- Cleanup ground marker effects
local function CleanupGroundMarker(markerId)
    local data = activeGroundMarkers[markerId]
    if not data then return end

    if data.effects then
        for _, fx in ipairs(data.effects) do
            if fx then
                StopParticleFxLooped(fx, false)
                RemoveParticleFx(fx, false)
                allParticles[fx] = nil
            end
        end
    end

    activeGroundMarkers[markerId] = nil
end

--- Spawn impact effects at meteor landing position (reduced smoke)
local function SpawnImpactEffects(coords, level)
    RequestNamedPtfxAsset('core')
    while not HasNamedPtfxAssetLoaded('core') do
        Wait(0)
    end

    local handles = {}
    local scale = 0.6 + (level * 0.1)

    -- Ground fire effect only
    UseParticleFxAssetNextCall('core')
    local fireFx = StartParticleFxLoopedAtCoord(
        'ent_ray_heli_aprtmnt_l_fire', coords.x, coords.y, coords.z,
        0.0, 0.0, 0.0, scale, false, false, false, false
    )
    if fireFx then
        handles[#handles + 1] = fireFx
        allParticles[fireFx] = { createdTime = GetGameTimer(), type = 'impact' }
    end

    -- Sparks only (no smoke)
    UseParticleFxAssetNextCall('core')
    local sparksFx = StartParticleFxLoopedAtCoord(
        'ent_brk_sparking_wires', coords.x, coords.y, coords.z,
        0.0, 0.0, 0.0, scale * 0.5, false, false, false, false
    )
    if sparksFx then
        handles[#handles + 1] = sparksFx
        allParticles[sparksFx] = { createdTime = GetGameTimer(), type = 'impact' }
    end

    -- Cleanup impact effects after duration
    SetTimeout(2000 + (level * 150), function()
        for _, fx in ipairs(handles) do
            if fx then
                StopParticleFxLooped(fx, false)
                RemoveParticleFx(fx, false)
                allParticles[fx] = nil
            end
        end
    end)
end

--- Cleanup a signal projectile
local function CleanupSignalProjectile(propId)
    local data = activeSignalProjectiles[propId]
    if not data then return end

    if data.effects then
        if data.effects.trail then
            StopParticleFxLooped(data.effects.trail, false)
            RemoveParticleFx(data.effects.trail, false)
            allParticles[data.effects.trail] = nil
        end
        if data.effects.fire then
            StopParticleFxLooped(data.effects.fire, false)
            RemoveParticleFx(data.effects.fire, false)
            allParticles[data.effects.fire] = nil
        end
    end

    if DoesEntityExist(data.prop) then
        SetEntityVisible(data.prop, false, false)
        SetEntityCoords(data.prop, 0.0, 0.0, -5000.0, false, false, false, false)
        DeleteEntity(data.prop)
        DeleteObject(data.prop)
    end

    activeSignalProjectiles[propId] = nil
end

--- Cleanup a meteor entity and its effects
local function CleanupMeteor(meteorId)
    local data = activeMeteors[meteorId]
    if not data then return end

    if data.effects then
        if data.effects.trail then
            StopParticleFxLooped(data.effects.trail, false)
            RemoveParticleFx(data.effects.trail, false)
            allParticles[data.effects.trail] = nil
        end
        if data.effects.fire then
            StopParticleFxLooped(data.effects.fire, false)
            RemoveParticleFx(data.effects.fire, false)
            allParticles[data.effects.fire] = nil
        end
    end

    if DoesEntityExist(data.prop) then
        SetEntityVisible(data.prop, false, false)
        SetEntityCoords(data.prop, 0.0, 0.0, -5000.0, false, false, false, false)
        DeleteEntity(data.prop)
        DeleteObject(data.prop)
    end

    activeMeteors[meteorId] = nil
end

--- Create signal projectile that travels from wand to target
local function CreateSignalProjectile(startCoords, targetCoords, sourceServerId, casterPed, spellLevel)
    local propModel <const> = GetHashKey("nib_magic_ray_basic")
    lib.requestModel(propModel, 5000)

    local prop <const> = CreateObject(propModel, startCoords.x, startCoords.y, startCoords.z, false, false, false)
    SetEntityCollision(prop, false, false)
    SetEntityAsMissionEntity(prop, true, true)
    SetEntityCompletelyDisableCollision(prop, true, false)

    local direction = vector3(
        targetCoords.x - startCoords.x,
        targetCoords.y - startCoords.y,
        targetCoords.z - startCoords.z
    )
    local distance = #direction
    if distance <= 0.001 then
        distance = 1.0
    end
    direction = direction / distance

    local heading <const> = math.deg(math.atan2(direction.y, direction.x)) + 90.0
    local pitch <const> = -math.deg(math.asin(direction.z))

    SetEntityCoords(prop, startCoords.x, startCoords.y, startCoords.z, false, false, false, false)
    SetEntityRotation(prop, pitch, 0.0, heading, 2, true)

    local effects = AttachSignalTrail(prop)

    local speed = Config.SignalProjectile and Config.SignalProjectile.speed or 55.0
    local duration = (distance / speed) * 1000.0
    local startTime = GetGameTimer()
    local endTime = startTime + duration

    activeSignalProjectiles[prop] = {
        prop = prop,
        startCoords = startCoords,
        targetCoords = targetCoords,
        direction = direction,
        distance = distance,
        startTime = startTime,
        endTime = endTime,
        heading = heading,
        pitch = pitch,
        sourceServerId = sourceServerId,
        effects = effects,
        spellLevel = spellLevel or 1
    }
end

--- Create a single meteor falling from the sky
local function CreateMeteor(targetCoords, sourceServerId, level, meteorIndex, totalMeteors)
    local levelConfig = Config.Levels[level] or Config.Levels[1]
    local spreadRadius = (Config.Meteor.spreadRadius or 8.0) * (levelConfig.spreadMult or 1.0)
    
    local angle = math.random() * 2 * math.pi
    local distance = math.random() * spreadRadius
    local offsetX = math.cos(angle) * distance
    local offsetY = math.sin(angle) * distance
    
    local impactCoords = vector3(
        targetCoords.x + offsetX,
        targetCoords.y + offsetY,
        targetCoords.z
    )
    
    local spawnHeight = Config.Meteor.spawnHeight or 80.0
    local startCoords = vector3(
        impactCoords.x + (offsetX * 0.3),
        impactCoords.y + (offsetY * 0.3),
        impactCoords.z + spawnHeight
    )

    local propModel <const> = GetHashKey("nib_magic_ray_basic")
    lib.requestModel(propModel, 5000)

    local meteorProp <const> = CreateObject(propModel, startCoords.x, startCoords.y, startCoords.z, false, false, false)
    SetEntityCollision(meteorProp, false, false)
    SetEntityAsMissionEntity(meteorProp, true, true)
    SetEntityCompletelyDisableCollision(meteorProp, true, false)

    local direction = vector3(
        impactCoords.x - startCoords.x,
        impactCoords.y - startCoords.y,
        impactCoords.z - startCoords.z
    )
    local travelDistance = #direction
    if travelDistance <= 0.001 then
        travelDistance = spawnHeight
    end
    direction = direction / travelDistance

    local pitch = -math.deg(math.asin(direction.z))
    local heading = math.deg(math.atan2(direction.y, direction.x)) + 90.0

    SetEntityCoords(meteorProp, startCoords.x, startCoords.y, startCoords.z, false, false, false, false)
    SetEntityRotation(meteorProp, pitch, 0.0, heading, 2, true)

    local effects = AttachMeteorTrail(meteorProp)

    local speed = Config.Meteor.fallSpeed or 45.0
    local duration = (travelDistance / speed) * 1000.0
    local startTime = GetGameTimer()
    local endTime = startTime + duration

    activeMeteors[meteorProp] = {
        prop = meteorProp,
        startCoords = startCoords,
        impactCoords = impactCoords,
        direction = direction,
        distance = travelDistance,
        startTime = startTime,
        endTime = endTime,
        pitch = pitch,
        heading = heading,
        sourceServerId = sourceServerId,
        effects = effects,
        level = level or 1,
        meteorIndex = meteorIndex,
        totalMeteors = totalMeteors,
        rotation = 0.0
    }
end

--- Spawn meteor shower after signal arrives
local function TriggerMeteorShower(targetCoords, sourceServerId, level)
    local levelConfig = Config.Levels[level] or Config.Levels[1]
    local meteorCount = levelConfig.meteorCount or 3
    local delayBetween = Config.Meteor.delayBetween or 350

    -- Create ground marker
    local markerId = GetGameTimer()
    local markerEffects = CreateGroundMarker(targetCoords, level)
    activeGroundMarkers[markerId] = { effects = markerEffects }

    -- Spawn meteors with staggered timing
    for i = 1, meteorCount do
        SetTimeout((i - 1) * delayBetween, function()
            CreateMeteor(targetCoords, sourceServerId, level, i, meteorCount)
        end)
    end

    -- Cleanup ground marker after all meteors
    local cleanupTime = (meteorCount * delayBetween) + 3000
    SetTimeout(cleanupTime, function()
        CleanupGroundMarker(markerId)
    end)
end

-- Main update loop for signal projectiles
CreateThread(function()
    while true do
        Wait(1)
        local currentTime <const> = GetGameTimer()

        for propId, data in pairs(activeSignalProjectiles) do
            if type(data) == "table" then
                if currentTime < data.endTime and DoesEntityExist(data.prop) then
                    local progress = (currentTime - data.startTime) / (data.endTime - data.startTime)
                    progress = math.min(progress, 1.0)

                    local newPos <const> = vector3(
                        data.startCoords.x + (data.direction.x * data.distance * progress),
                        data.startCoords.y + (data.direction.y * data.distance * progress),
                        data.startCoords.z + (data.direction.z * data.distance * progress)
                    )

                    SetEntityCoords(data.prop, newPos.x, newPos.y, newPos.z, false, false, false, false)
                    SetEntityRotation(data.prop, data.pitch, 0.0, data.heading, 2, true)
                end

                -- Signal arrived at target
                if currentTime >= data.endTime then
                    local targetCoords = data.targetCoords
                    local level = data.spellLevel or 1

                    -- Small visual burst on arrival
                    AddExplosion(targetCoords.x, targetCoords.y, targetCoords.z, 82, 0.01, true, false, 0.1)

                    -- Trigger meteor shower!
                    TriggerMeteorShower(targetCoords, data.sourceServerId, level)

                    CleanupSignalProjectile(propId)
                end
            end
        end
    end
end)

-- Main update loop for active meteors
CreateThread(function()
    while true do
        Wait(1)
        local currentTime <const> = GetGameTimer()

        for propId, data in pairs(activeMeteors) do
            if type(data) == "table" then
                if currentTime < data.endTime and DoesEntityExist(data.prop) then
                    local progress = (currentTime - data.startTime) / (data.endTime - data.startTime)
                    progress = math.min(progress, 1.0)

                    local newPos <const> = vector3(
                        data.startCoords.x + (data.direction.x * data.distance * progress),
                        data.startCoords.y + (data.direction.y * data.distance * progress),
                        data.startCoords.z + (data.direction.z * data.distance * progress)
                    )

                    SetEntityCoords(data.prop, newPos.x, newPos.y, newPos.z, false, false, false, false)

                    local rotSpeed = Config.Meteor.rotationSpeed or 720.0
                    data.rotation = data.rotation + (rotSpeed * 0.001)
                    SetEntityRotation(data.prop, data.pitch, data.rotation, data.heading, 2, true)
                end

                -- Meteor impact
                if currentTime >= data.endTime then
                    if DoesEntityExist(data.prop) then
                        local impactCoords <const> = data.impactCoords
                        local level = data.level or 1
                        local isLocalCaster = GetPlayerServerId(PlayerId()) == data.sourceServerId

                        if isLocalCaster then
                            TriggerServerEvent('dvr_meteora:applyMeteorDamage', impactCoords, level, data.meteorIndex)
                        end

                        Wait(150)

                        SpawnImpactEffects(impactCoords, level)

                        local explosionScale = 0.01 + (level * 0.015)
                        AddExplosion(impactCoords.x, impactCoords.y, impactCoords.z, 2, explosionScale, true, false, 0.25)

                        if level >= 3 then
                            AddExplosion(impactCoords.x, impactCoords.y, impactCoords.z, 82, explosionScale * 0.6, true, false, 0.15)
                        end

                        local playerCoords <const> = GetEntityCoords(cache.ped)
                        local dist = #(playerCoords - impactCoords)
                        local shakeCfg = Config.Effects.shake
                        local levelConfig = Config.Levels[level] or Config.Levels[1]

                        if shakeCfg and dist < (shakeCfg.maxDistance or 25.0) then
                            local baseIntensity = (shakeCfg.intensity or 0.35) * (levelConfig.shakeMult or 1.0)
                            local factor = 1.0 - (dist / (shakeCfg.maxDistance or 25.0))
                            local intensity = math.max(0.05, baseIntensity * factor)
                            ShakeGameplayCam('SMALL_EXPLOSION_SHAKE', intensity)
                        end
                    end

                    CleanupMeteor(propId)
                end
            end
        end
    end
end)

-- Periodic cleanup of orphaned particles
CreateThread(function()
    while true do
        Wait(30000)
        local currentTime = GetGameTimer()
        local toRemove = {}

        for particleHandle, particleData in pairs(allParticles) do
            if currentTime - (particleData.createdTime or 0) > 15000 then
                toRemove[#toRemove + 1] = particleHandle
            end
        end

        for _, particleHandle in ipairs(toRemove) do
            StopParticleFxLooped(particleHandle, false)
            RemoveParticleFx(particleHandle, false)
            allParticles[particleHandle] = nil
        end
    end
end)

--- Play cast sound at position
local function PlayCastSound(coords)
    if not Config.Sounds or not Config.Sounds.cast or Config.Sounds.cast.url == '' then
        return
    end

    -- REPLACE WITH YOUR SOUND SYSTEM
    -- exports['lo_audio']:playSound({
    -- id = ('dvr_meteora_cast_%s'):format(GetGameTimer()),
    -- url = Config.Sounds.cast.url,
    -- volume = Config.Sounds.cast.volume or 0.7,
    -- loop = false,
    -- spatial = true,
    -- distance = 15.0,
    -- pos = { x = coords.x, y = coords.y, z = coords.z }
    -- })
end

--- Calculate target position from camera raycast
local function FindTargetCoords()
    local camCoords <const> = GetGameplayCamCoord()
    local camRot <const> = GetGameplayCamRot(2)
    local direction <const> = RotationToDirection(camRot)
    local maxDist = 50.0

    local hit, entityHit, coords = lib.raycast.cam(1 | 2 | 4 | 8 | 16, 4, maxDist)

    if coords and (coords.x ~= 0.0 or coords.y ~= 0.0 or coords.z ~= 0.0) then
        return coords
    end

    return vector3(
        camCoords.x + direction.x * maxDist,
        camCoords.y + direction.y * maxDist,
        camCoords.z + direction.z * maxDist
    )
end

-- Event: Local player starts casting
RegisterNetEvent('dvr_meteora:prepareCast', function(spellLevel)
    local casterPed <const> = cache.ped

    CreateWandParticles(casterPed, true)

    local handBone <const> = GetPedBoneIndex(casterPed, 28422)
    local handPos <const> = GetWorldPositionOfEntityBone(casterPed, handBone)
    PlayCastSound(handPos)

    CreateThread(function()
        local duration = Config.Animation.duration or 2500
        local speed = Config.Animation.speedMultiplier or 1.8
        local realDuration = duration / speed
        local castDelay = math.floor(realDuration * 0.5)

        if castDelay < 0 then castDelay = 0 end
        Wait(castDelay)

        local targetCoords = FindTargetCoords()

        -- Send to server to broadcast the signal projectile
        TriggerServerEvent('dvr_meteora:broadcastSignalProjectile', targetCoords, spellLevel)

        Wait(800)
        StopWandTrail(casterPed)
    end)
end)

-- Event: Another player is casting (for visual sync)
RegisterNetEvent('dvr_meteora:otherPlayerCasting', function(sourceServerId)
    local myServerId <const> = GetPlayerServerId(PlayerId())
    if sourceServerId == myServerId then return end

    local casterPlayer <const> = GetPlayerFromServerId(sourceServerId)
    if casterPlayer == -1 then return end

    local casterPed <const> = GetPlayerPed(casterPlayer)
    if not DoesEntityExist(casterPed) then return end

    CreateWandParticles(casterPed, true)

    SetTimeout(3000, function()
        StopWandTrail(casterPed)
    end)
end)

-- Event: Spawn signal projectile (all clients see it fly from caster to target)
RegisterNetEvent('dvr_meteora:spawnSignalProjectile', function(sourceServerId, targetCoords, spellLevel)
    if not targetCoords then return end

    local casterPlayer = GetPlayerFromServerId(sourceServerId)
    if casterPlayer == -1 then return end

    local casterPed = GetPlayerPed(casterPlayer)
    if not DoesEntityExist(casterPed) then return end

    local handBone = GetPedBoneIndex(casterPed, 28422)
    local startCoords = GetWorldPositionOfEntityBone(casterPed, handBone)

    CreateSignalProjectile(startCoords, targetCoords, sourceServerId, casterPed, spellLevel)
end)

-- Cleanup on resource stop
AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end

    for propId, data in pairs(activeSignalProjectiles) do
        if type(data) == "table" and DoesEntityExist(data.prop) then
            DeleteEntity(data.prop)
            DeleteObject(data.prop)
        end
    end
    activeSignalProjectiles = {}

    for propId, data in pairs(activeMeteors) do
        if type(data) == "table" and DoesEntityExist(data.prop) then
            DeleteEntity(data.prop)
            DeleteObject(data.prop)
        end
    end
    activeMeteors = {}

    for markerId, data in pairs(activeGroundMarkers) do
        if data.effects then
            for _, fx in ipairs(data.effects) do
                if fx then
                    StopParticleFxLooped(fx, false)
                    RemoveParticleFx(fx, false)
                end
            end
        end
    end
    activeGroundMarkers = {}

    for ped, handle in pairs(wandParticles) do
        StopParticleFxLooped(handle, false)
        RemoveParticleFx(handle, false)
    end
    wandParticles = {}

    for particleHandle, _ in pairs(allParticles) do
        StopParticleFxLooped(particleHandle, false)
        RemoveParticleFx(particleHandle, false)
    end
    allParticles = {}

    RemoveNamedPtfxAsset('core')
end)
