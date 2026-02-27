---@diagnostic disable: undefined-global, trailing-space, unused-local, param-type-mismatch, missing-parameter, deprecated
local fireRayProps = {}
local wandParticles = {}
local allParticles = {}
local activePillars = {}
local RequestNamedPtfxAsset = RequestNamedPtfxAsset
local HasNamedPtfxAssetLoaded = HasNamedPtfxAssetLoaded
local UseParticleFxAsset = UseParticleFxAsset
local UseParticleFxAssetNextCall = UseParticleFxAssetNextCall
local StartNetworkedParticleFxLoopedOnEntity = StartNetworkedParticleFxLoopedOnEntity
local StartParticleFxLoopedOnEntity = StartParticleFxLoopedOnEntity
local StartParticleFxNonLoopedOnEntity = StartParticleFxNonLoopedOnEntity
local StartNetworkedParticleFxNonLoopedOnEntity = StartNetworkedParticleFxNonLoopedOnEntity
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
local SetEntityHeading = SetEntityHeading
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
local AddExplosion = AddExplosion
local ExplosionSoundUrl <const> = "YOUR_SOUND_URL_HERE"

local function StopWandTrail(playerPed)
    local handle = wandParticles[playerPed]
    if handle then
        StopParticleFxLooped(handle, false)
        RemoveParticleFx(handle, false)
        allParticles[handle] = nil
        wandParticles[playerPed] = nil
    end
end

local function RemoveWandParticles(playerPed)
    StopWandTrail(playerPed)
end

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

local function GetAnimationTimings()
    local anim <const> = Config.Animation or {}
    local speedMult = anim.speedMultiplier or 1.0
    if speedMult <= 0.0 then
        speedMult = 1.0
    end

    local propsDelay <const> = anim.propsDelay or 2200
    local duration <const> = anim.duration or 3000
    local scaledProps <const> = math.floor(propsDelay / speedMult)
    local scaledDuration <const> = math.max(scaledProps, math.floor(duration / speedMult))
    local cleanupDelay <const> = math.max(0, scaledDuration - scaledProps)

    return scaledProps, cleanupDelay, scaledDuration
end

local function CreateWandParticles(playerPed, isNetworked)
    return nil
end

local function AttachProjectileTrail(rayProp, isNetworked)
    if not rayProp or not DoesEntityExist(rayProp) then
        return
    end

    RequestNamedPtfxAsset('core')
    while not HasNamedPtfxAssetLoaded('core') do
        Wait(0)
    end

    UseParticleFxAsset('core')
    UseParticleFxAssetNextCall('core')

    if isNetworked then
        StartNetworkedParticleFxNonLoopedOnEntity('veh_light_red_trail', rayProp, 0.35, 0.0, 0.1, 0.0, 0.0, 0.0)
    else
        StartParticleFxNonLoopedOnEntity('veh_light_red_trail', rayProp, 0.35, 0.0, 0.1, 0.0, 0.0, 0.0)
    end

    local trailHandle
    if isNetworked then
        trailHandle = StartNetworkedParticleFxLoopedOnEntity('veh_light_red_trail', rayProp, 0.35, 0.0, 0.1, 0.0, 0.0, 0.0, 0.55, false, false, false)
    else
        trailHandle = StartParticleFxLoopedOnEntity('veh_light_red_trail', rayProp, 0.35, 0.0, 0.1, 0.0, 0.0, 0.0, 0.55, false, false, false)
    end

    allParticles[trailHandle] = {
        createdTime = GetGameTimer(),
        type = 'projectileTrail'
    }

    return trailHandle
end

local function TransferWandTrailToProjectile(casterPed, rayProp)
    StopWandTrail(casterPed)
    return AttachProjectileTrail(rayProp, false)
end

local function AttachPillarParticles(pillar)
    if not DoesEntityExist(pillar) then
        return {}
    end

    local handles = {}
    RequestNamedPtfxAsset('ns_ptfx')
    while not HasNamedPtfxAssetLoaded('ns_ptfx') do
        Wait(0)
    end

    for i = 1, 4 do
        UseParticleFxAssetNextCall('ns_ptfx')
        local fx = StartParticleFxLoopedOnEntity('fire', pillar, 0.0, 0.0, -0.8 + (i * 0.55), 0.0, 0.0, 0.0, 1.35, false, false, false)
        if fx then
            handles[#handles + 1] = fx
            allParticles[fx] = {
                createdTime = GetGameTimer(),
                type = 'pillar'
            }
        end
    end

    RequestNamedPtfxAsset('core')
    while not HasNamedPtfxAssetLoaded('core') do
        Wait(0)
    end

    UseParticleFxAssetNextCall('core')
    local smoke = StartParticleFxLoopedOnEntity('exp_grd_bzgas_smoke', pillar, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 0.85, false, false, false)
    if smoke then
        handles[#handles + 1] = smoke
        allParticles[smoke] = {
            createdTime = GetGameTimer(),
            type = 'pillar_smoke'
        }
    end

    return handles
end

local function CleanupPillar(pillar)
    local data = activePillars[pillar]
    if not data then
        return
    end

    if data.particles then
        for _, handle in ipairs(data.particles) do
            StopParticleFxLooped(handle, false)
            RemoveParticleFx(handle, false)
            allParticles[handle] = nil
        end
    end

    if DoesEntityExist(pillar) then
        SetEntityVisible(pillar, false, false)
        DeleteEntity(pillar)
        DeleteObject(pillar)
    end

    activePillars[pillar] = nil
end

local function TriggerLevelExplosion(coords, level, sourceServerId)
    if not coords then
        return
    end

    local lvl = tonumber(level) or 0
    local shake = 0.0
    local soundVolume = 0.0

    if lvl >= 5 then
        shake = 0.35
        soundVolume = 1.0
    elseif lvl == 4 then
        shake = 0.2
        soundVolume = 0.65
    elseif lvl == 3 then
        shake = 0.08
        soundVolume = 0.4
    elseif lvl == 2 then
        shake = 0.0
        soundVolume = 0.25
    else -- lvl <= 1
        shake = 0.0
        soundVolume = 0.0
    end
    
    -- Notify server BEFORE explosion to protect players
    local myServerId = GetPlayerServerId(PlayerId())
    if sourceServerId == myServerId then
        TriggerServerEvent('th_firepillar:applyPillarDamage', coords, level)
    end
    
    -- Wait for protection to activate
    Wait(200)

    -- Visual/sound explosion only - NO damage (players are protected)
    AddExplosion(coords.x, coords.y, coords.z, 1, 0.0, true, false, 0.0)

    if soundVolume > 0.0 and ExplosionSoundUrl then
        -- REPLACE WITH YOUR SOUND SYSTEM
        -- exports['lo_audio']:playSound({
        -- id = ('firepillar_explosion_%s'):format(GetGameTimer()),
        -- url = ExplosionSoundUrl,
        -- volume = soundVolume,
        -- loop = false,
        -- spatial = true,
        -- distance = 10.0,
        -- pos = { x = coords.x, y = coords.y, z = coords.z }
        -- })
    end
end

local function CreateFirePillar(spawnCoords, baseHeading, sourceServerId, level)
    local propModel <const> = GetHashKey(Config.Pillar.model or 'nib_fire_tornado')
    lib.requestModel(propModel, 5000)

    local pillar <const> = CreateObject(propModel, spawnCoords.x, spawnCoords.y, spawnCoords.z, false, false, false)
    if not DoesEntityExist(pillar) then
        return
    end

    TriggerLevelExplosion(spawnCoords, level, sourceServerId)

    SetEntityCollision(pillar, false, false)
    SetEntityAsMissionEntity(pillar, true, true)
    SetEntityCompletelyDisableCollision(pillar, true, false)
    SetEntityHeading(pillar, baseHeading or 0.0)
    SetEntityLodDist(pillar, 2000)
    if SetEntityDistanceCullingRadius then
        SetEntityDistanceCullingRadius(pillar, 2000.0)
    end

    local now <const> = GetGameTimer()
    activePillars[pillar] = {
        prop = pillar,
        heading = baseHeading or 0.0,
        lastUpdate = now,
        endTime = now + (Config.Pillar.duration or 6000),
        rotationSpeed = Config.Pillar.rotation_speed or 120.0,
        particles = AttachPillarParticles(pillar),
        sourceServerId = sourceServerId,
        level = level or 0
    }
end

local function CreateFireProjectile(startCoords, targetCoords, sourceServerId, casterPed, level)
    local propModel <const> = GetHashKey("nib_magic_ray_basic")
    lib.requestModel(propModel, 5000)

    local rayProp <const> = CreateObject(propModel, startCoords.x, startCoords.y, startCoords.z, false, false, false)
    SetEntityCollision(rayProp, false, false)
    SetEntityAsMissionEntity(rayProp, true, true)
    SetEntityCompletelyDisableCollision(rayProp, true, false)

    local direction = vector3(
        targetCoords.x - startCoords.x,
        targetCoords.y - startCoords.y,
        targetCoords.z - startCoords.z
    )
    local distance = #direction
    if distance <= 0.001 then
        distance = 0.001
    end
    direction = direction / distance

    local heading <const> = math.deg(math.atan2(direction.y, direction.x)) + 90.0
    local pitch <const> = -math.deg(math.asin(direction.z))
    local roll <const> = 0.0

    SetEntityCoords(rayProp, startCoords.x, startCoords.y, startCoords.z, false, false, false, false)
    SetEntityRotation(rayProp, pitch, roll, heading, 2, true)

    local trailHandle <const> = TransferWandTrailToProjectile(casterPed, rayProp)

    local duration <const> = (distance / (Config.Projectile.speed or 30.0)) * 1000.0
    local startTime <const> = GetGameTimer()
    local endTime <const> = startTime + duration

    fireRayProps[rayProp] = {
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
        trailHandle = trailHandle,
        level = level or 0
    }
end

CreateThread(function()
    while true do
        Wait(30000)

        local currentTime = GetGameTimer()
        local toRemove = {}

        for particleHandle, particleData in pairs(allParticles) do
            if currentTime - (particleData.createdTime or 0) > 10000 then
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

CreateThread(function()
    while true do
        Wait(1)

        local currentTime <const> = GetGameTimer()

        for propId, data in pairs(fireRayProps) do
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

                    if data.heading and data.pitch and data.roll then
                        SetEntityRotation(data.prop, data.pitch, data.roll, data.heading, 2, true)
                    end
                end

                if currentTime >= data.endTime then
                    if data.trailHandle then
                        StopParticleFxLooped(data.trailHandle, false)
                        RemoveParticleFx(data.trailHandle, false)
                        allParticles[data.trailHandle] = nil
                        data.trailHandle = nil
                    end

                    if DoesEntityExist(data.prop) then
                        local propCoords <const> = GetEntityCoords(data.prop)
                        CreateFirePillar(propCoords, data.heading, data.sourceServerId, data.level)

                        SetEntityVisible(data.prop, false, false)
                        SetEntityCoords(data.prop, 0.0, 0.0, -5000.0, false, false, false, false)
                        Wait(50)
                        DeleteEntity(data.prop)
                        DeleteObject(data.prop)
                    end

                    fireRayProps[propId] = nil
                end
            end
        end
    end
end)

CreateThread(function()
    while true do
        Wait(1)

        local now <const> = GetGameTimer()
        for pillar, data in pairs(activePillars) do
            if type(data) == 'table' then
                if now < data.endTime and DoesEntityExist(pillar) then
                    local delta <const> = now - (data.lastUpdate or now)
                    data.lastUpdate = now
                    data.heading = (data.heading + (data.rotationSpeed * (delta / 1000.0))) % 360.0
                    SetEntityHeading(pillar, data.heading)
                else
                    CleanupPillar(pillar)
                end
            end
        end
    end
end)

RegisterNetEvent('th_firepillar:preparePillar', function(level)
    local casterPed <const> = cache.ped
    local propsDelay, cleanupDelay = GetAnimationTimings()

    CreateWandParticles(casterPed, true)

    CreateThread(function()
        Wait(propsDelay)
        local handBone <const> = GetPedBoneIndex(casterPed, 28422)
        local startCoords <const> = GetWorldPositionOfEntityBone(casterPed, handBone)

        local camCoords <const> = GetGameplayCamCoord()
        local camRot <const> = GetGameplayCamRot(2)
        local direction <const> = RotationToDirection(camRot)

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

        TriggerServerEvent('th_firepillar:broadcastPillar', finalTargetCoords, level or 0)

        Wait(cleanupDelay)
        RemoveWandParticles(casterPed)
    end)
end)

RegisterNetEvent('th_firepillar:otherPlayerCasting', function(sourceServerId)
    local myServerId <const> = GetPlayerServerId(PlayerId())

    if sourceServerId == myServerId then
        return
    end

    local casterPlayer <const> = GetPlayerFromServerId(sourceServerId)
    if casterPlayer == -1 then
        return
    end

    local casterPed <const> = GetPlayerPed(casterPlayer)
    if not DoesEntityExist(casterPed) then
        return
    end

    CreateWandParticles(casterPed, true)

    local _, _, animDuration = GetAnimationTimings()
    SetTimeout(animDuration, function()
        RemoveWandParticles(casterPed)
    end)
end)

RegisterNetEvent('th_firepillar:spawnPillar', function(sourceServerId, targetCoords, level)
    local casterPlayer <const> = GetPlayerFromServerId(sourceServerId)
    if casterPlayer == -1 then
        return
    end

    local casterPed <const> = GetPlayerPed(casterPlayer)
    if not DoesEntityExist(casterPed) then
        return
    end

    if not targetCoords then
        return
    end

    local handBone <const> = GetPedBoneIndex(casterPed, 28422)
    local startCoords <const> = GetWorldPositionOfEntityBone(casterPed, handBone)
    CreateFireProjectile(startCoords, targetCoords, sourceServerId, casterPed, level or 0)
end)

AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then
        return
    end

    for pillar, _ in pairs(activePillars) do
        CleanupPillar(pillar)
    end

    for propId, data in pairs(fireRayProps) do
        if type(data) == "table" and DoesEntityExist(data.prop) then
            DeleteEntity(data.prop)
            DeleteObject(data.prop)
        end
    end
    fireRayProps = {}

    for ped, handle in pairs(wandParticles) do
        RemoveParticleFx(handle, false)
    end
    wandParticles = {}

    for particleHandle, _ in pairs(allParticles) do
        StopParticleFxLooped(particleHandle, false)
        RemoveParticleFx(particleHandle, false)
    end
    allParticles = {}

    RemoveNamedPtfxAsset('core')
    RemoveNamedPtfxAsset('ns_ptfx')
end)
