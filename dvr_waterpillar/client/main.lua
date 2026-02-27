---@diagnostic disable: undefined-global, trailing-space, unused-local, param-type-mismatch, missing-parameter, deprecated
local pillarProjectiles = {}
local wandParticles = {}
local allParticles = {}

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
local math_floor = math.floor
local math_max = math.max

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
    local adjustedRotation<const> = {
        x = (math.pi / 180) * rotation.x,
        y = (math.pi / 180) * rotation.y,
        z = (math.pi / 180) * rotation.z
    }
    local direction<const> = {
        x = -math.sin(adjustedRotation.z) * math.abs(math.cos(adjustedRotation.x)),
        y = math.cos(adjustedRotation.z) * math.abs(math.cos(adjustedRotation.x)),
        z = math.sin(adjustedRotation.x)
    }
    return direction
end

local function GetAnimationTimings()
    local anim = Config.Animation or {}
    local speedMult = anim.speedMultiplier or 1.0
    if speedMult <= 0.0 then
        speedMult = 1.0
    end

    local projectileDelay = anim.projectileDelay or 2200
    local cleanupDelay = anim.cleanupDelay or 800
    local duration = anim.duration or 3000

    local scaledProjectile = math_floor(projectileDelay / speedMult)
    local scaledCleanup = math_floor(math_max(0, cleanupDelay) / speedMult)
    local scaledDuration = math_floor(duration / speedMult)

    if scaledDuration < scaledProjectile then
        scaledDuration = scaledProjectile
    end

    return scaledProjectile, scaledCleanup, scaledDuration
end

local function CreateWandParticles(playerPed, isNetworked)
    local wandFx = Config.Effects and Config.Effects.wand
    if not wandFx then
        return
    end

    RequestNamedPtfxAsset(wandFx.dict)
    while not HasNamedPtfxAssetLoaded(wandFx.dict) do
        Wait(0)
    end

    UseParticleFxAsset(wandFx.dict)
    UseParticleFxAssetNextCall(wandFx.dict)

    local fx
    if isNetworked then
        fx = StartNetworkedParticleFxLoopedOnEntity(
            wandFx.name,
            playerPed,
            wandFx.offset.x,
            wandFx.offset.y,
            wandFx.offset.zstart or 0.0,
            wandFx.rot.x,
            wandFx.rot.y,
            wandFx.rot.z,
            1.0,
            false, false, false
        )
    else
        fx = StartParticleFxLoopedOnEntity(
            wandFx.name,
            playerPed,
            wandFx.offset.x,
            wandFx.offset.y,
            wandFx.offset.zstart or 0.0,
            wandFx.rot.x,
            wandFx.rot.y,
            wandFx.rot.z,
            1.0,
            false, false, false
        )
    end

    if fx then
        wandParticles[playerPed] = fx
        allParticles[fx] = { createdTime = GetGameTimer(), type = 'wandTrail' }
    end
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
        StartNetworkedParticleFxNonLoopedOnEntity('veh_light_blue_trail', rayProp, 0.35, 0.0, 0.1, 0.0, 0.0, 0.0)
    else
        StartParticleFxNonLoopedOnEntity('veh_light_blue_trail', rayProp, 0.35, 0.0, 0.1, 0.0, 0.0, 0.0)
    end

    local trailHandle
    if isNetworked then
        trailHandle = StartNetworkedParticleFxLoopedOnEntity('veh_light_blue_trail', rayProp, 0.35, 0.0, 0.1, 0.0, 0.0, 0.0, 0.55, false, false, false)
    else
        trailHandle = StartParticleFxLoopedOnEntity('veh_light_blue_trail', rayProp, 0.35, 0.0, 0.1, 0.0, 0.0, 0.0, 0.55, false, false, false)
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

local function AttachPillarParticles(coords, heading)
    local handles = {}
    local fxCfg = Config.Effects and Config.Effects.pillar
    if not fxCfg then
        return handles
    end

    RequestNamedPtfxAsset('core')
    while not HasNamedPtfxAssetLoaded('core') do
        Wait(0)
    end

    local function addFx(name, offsetZ, scale)
        UseParticleFxAssetNextCall('core')
        local fx = StartParticleFxLoopedAtCoord(name, coords.x, coords.y, coords.z + offsetZ, 0.0, 0.0, heading or 0.0, scale or 1.0, false, false, false, false)
        if fx then
            handles[#handles + 1] = fx
            allParticles[fx] = { createdTime = GetGameTimer(), type = 'pillar' }
        end
    end

    addFx(fxCfg.bubble or 'ent_amb_tnl_bubbles_sml', -0.5, 1.0)
    addFx(fxCfg.splash or 'veh_air_turbulance_water', 0.0, 1.5)

    UseParticleFxAssetNextCall('core')
    local endFx = StartParticleFxLoopedAtCoord(fxCfg.splash2 or 'exp_water', coords.x, coords.y, coords.z + 0.2, 0.0, 0.0, heading or 0.0, 1.1, false, false, false, false)
    if endFx then
        handles[#handles + 1] = endFx
        allParticles[endFx] = { createdTime = GetGameTimer(), type = 'pillar' }
    end

    return handles
end

local function TriggerWaterPillarDamage(coords, level, sourceServerId)
    if not coords then
        return
    end

    -- Notify server BEFORE creating visual effects to protect players
    local myServerId = GetPlayerServerId(PlayerId())
    if sourceServerId == myServerId then
        TriggerServerEvent('dvr_waterpillar:applyPillarDamage', coords, level)
    end
    
    -- Wait for protection to activate
    Wait(50)
end

local function CreateWaterPillar(spawnCoords, baseHeading, sourceServerId, level)
    -- Apply damage before visual effects
    TriggerWaterPillarDamage(spawnCoords, level, sourceServerId)
    
    local handles = AttachPillarParticles(spawnCoords, baseHeading or 0.0)
    SetTimeout(Config.Pillar.duration or 6000, function()
        for _, handle in ipairs(handles or {}) do
            StopParticleFxLooped(handle, false)
            RemoveParticleFx(handle, false)
            allParticles[handle] = nil
        end
    end)
end

local function CreateWaterProjectile(startCoords, targetCoords, sourceServerId, casterPed, level)
    local propModel <const> = GetHashKey(Config.Projectile.model or "nib_diffindo_prop")
    lib.requestModel(propModel, 5000)

    local rayProp <const> = CreateObject(propModel, startCoords.x, startCoords.y, startCoords.z, false, false, false)
    SetEntityCollision(rayProp, false, false)
    SetEntityAsMissionEntity(rayProp, true, true)
    SetEntityCompletelyDisableCollision(rayProp, true, false)
    SetEntityNoCollisionEntity(rayProp, casterPed, false)

    local direction = vector3(targetCoords.x - startCoords.x, targetCoords.y - startCoords.y, targetCoords.z - startCoords.z)
    local distance = #direction
    if distance <= 0.001 then
        distance = 0.001
    end
    direction = direction / distance

    local heading<const> = math.deg(math.atan2(direction.y, direction.x)) + 90.0
    local pitch<const> = -math.deg(math.asin(direction.z))
    local roll<const> = 0.0

    SetEntityCoords(rayProp, startCoords.x, startCoords.y, startCoords.z, false, false, false, false)
    SetEntityRotation(rayProp, pitch, roll, heading, 2, true)

    local trailHandle<const> = TransferWandTrailToProjectile(casterPed, rayProp)

    local duration<const> = (distance / (Config.Projectile.speed or 28.0)) * 1000.0
    local startTime<const> = GetGameTimer()
    local endTime<const> = startTime + duration

    pillarProjectiles[rayProp] = {
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

        local currentTime<const> = GetGameTimer()

        for propId, data in pairs(pillarProjectiles) do
            if type(data) == "table" then
                if currentTime < data.endTime and DoesEntityExist(data.prop) then
                    local progress = (currentTime - data.startTime) / (data.endTime - data.startTime)
                    progress = math.min(progress, 1.0)

                    local newPos<const> = vector3(
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
                        local propCoords<const> = GetEntityCoords(data.prop)
                        CreateWaterPillar(propCoords, data.heading, data.sourceServerId, data.level)
                        SetEntityVisible(data.prop, false, false)
                        SetEntityCoords(data.prop, 0.0, 0.0, -5000.0, false, false, false, false)
                        Wait(50)
                        DeleteEntity(data.prop)
                        DeleteObject(data.prop)
                    end

                    pillarProjectiles[propId] = nil
                end
            end
        end
    end
end)

RegisterNetEvent('dvr_waterpillar:preparePillar', function(level)
    local casterPed<const> = cache.ped
    CreateWandParticles(casterPed, true)
    local projectileDelay, cleanupDelay = GetAnimationTimings()

    CreateThread(function()
        Wait(math_max(0, projectileDelay))
        local handBone<const> = GetPedBoneIndex(casterPed, 28422)
        local startCoords<const> = GetWorldPositionOfEntityBone(casterPed, handBone)

        local camCoords<const> = GetGameplayCamCoord()
        local camRot<const> = GetGameplayCamRot(2)
        local direction<const> = RotationToDirection(camRot)

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

        TriggerServerEvent('dvr_waterpillar:broadcastProjectile', finalTargetCoords, level or 0)

        Wait(math_max(0, cleanupDelay))
        RemoveWandParticles(casterPed)
    end)
end)

RegisterNetEvent('dvr_waterpillar:otherPlayerCasting', function(sourceServerId)
    local myServerId<const> = GetPlayerServerId(PlayerId())
    if sourceServerId == myServerId then
        return
    end

    local casterPlayer<const> = GetPlayerFromServerId(sourceServerId)
    if casterPlayer == -1 then
        return
    end

    local casterPed<const> = GetPlayerPed(casterPlayer)
    if not DoesEntityExist(casterPed) then
        return
    end

    CreateWandParticles(casterPed, true)

    local _, _, animDuration = GetAnimationTimings()
    SetTimeout(animDuration, function()
        RemoveWandParticles(casterPed)
    end)
end)

RegisterNetEvent('dvr_waterpillar:spawnPillar', function(sourceServerId, targetCoords, level)
    local casterPlayer<const> = GetPlayerFromServerId(sourceServerId)
    if casterPlayer == -1 then
        return
    end

    local casterPed<const> = GetPlayerPed(casterPlayer)
    if not DoesEntityExist(casterPed) then
        return
    end

    if not targetCoords then
        return
    end

    local handBone<const> = GetPedBoneIndex(casterPed, 28422)
    local startCoords<const> = GetWorldPositionOfEntityBone(casterPed, handBone)
    CreateWaterProjectile(startCoords, targetCoords, sourceServerId, casterPed, level or 0)
end)

AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then
        return
    end

    for propId, data in pairs(pillarProjectiles) do
        if type(data) == "table" and DoesEntityExist(data.prop) then
            DeleteEntity(data.prop)
            DeleteObject(data.prop)
        end
    end
    pillarProjectiles = {}

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
