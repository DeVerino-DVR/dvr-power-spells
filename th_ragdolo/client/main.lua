---@diagnostic disable: undefined-global, trailing-space, unused-local, param-type-mismatch, missing-parameter, deprecated
local ragdollProjectiles = {}
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
local SetPedToRagdoll = SetPedToRagdoll

local function HasProtheaShield()
    local hasShield = false

    if LocalPlayer and LocalPlayer.state then
        hasShield = LocalPlayer.state.protheaShield == true
    end

    if not hasShield and exports['th_prothea'] and exports['th_prothea'].hasLocalShield then
        local ok, result = pcall(function()
            return exports['th_prothea']:hasLocalShield()
        end)
        hasShield = ok and result == true
    end

    return hasShield
end

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

    local projectileDelay <const> = anim.projectileDelay or 2200
    local cleanupDelayCfg = anim.cleanupDelay
    local duration <const> = anim.duration or 3000

    local scaledProjectile <const> = math.floor(projectileDelay / speedMult)
    local scaledDuration = math.max(scaledProjectile, math.floor(duration / speedMult))
    local scaledCleanup

    if cleanupDelayCfg ~= nil then
        scaledCleanup = math.floor(math.max(0, cleanupDelayCfg) / speedMult)
    else
        scaledCleanup = math.max(0, scaledDuration - scaledProjectile)
    end

    if scaledDuration < scaledProjectile + scaledCleanup then
        scaledDuration = scaledProjectile + scaledCleanup
    end

    return scaledProjectile, scaledCleanup, scaledDuration
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

local function CleanupProjectile(propId)
    local data = ragdollProjectiles[propId]
    if not data then
        return
    end

    if data.trailHandle then
        StopParticleFxLooped(data.trailHandle, false)
        RemoveParticleFx(data.trailHandle, false)
        allParticles[data.trailHandle] = nil
        data.trailHandle = nil
    end

    if DoesEntityExist(propId) then
        SetEntityVisible(propId, false, false)
        SetEntityCoords(propId, 0.0, 0.0, -5000.0, false, false, false, false)
        DeleteEntity(propId)
        DeleteObject(propId)
    end

    ragdollProjectiles[propId] = nil
end

local function CreateRagdollProjectile(startCoords, targetCoords, sourceServerId, casterPed, targetId, level)
    local propModel <const> = GetHashKey("nib_accio_ray")
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

    ragdollProjectiles[rayProp] = {
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
        targetId = targetId or 0,
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

        for propId, data in pairs(ragdollProjectiles) do
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
                    if DoesEntityExist(data.prop) then
                        local propCoords <const> = GetEntityCoords(data.prop)
                        TriggerServerEvent('th_ragdolo:ragdollTarget', data.targetId or 0, data.level or 0)

                        SetEntityVisible(data.prop, false, false)
                        SetEntityCoords(data.prop, 0.0, 0.0, -5000.0, false, false, false, false)
                        Wait(50)
                        DeleteEntity(data.prop)
                        DeleteObject(data.prop)
                    end

                    CleanupProjectile(propId)
                end
            end
        end
    end
end)

local function GetRagdollDuration(level)
    local base = Config.Ragdoll.baseDuration or 2000
    local perLevel = Config.Ragdoll.perLevel or 0
    local max = Config.Ragdoll.maxDuration or 5000
    local lvl = tonumber(level) or 0
    local duration = base + (perLevel * lvl)
    return math.min(duration, max)
end

RegisterNetEvent('th_ragdolo:applyRagdoll', function(level)
    if HasProtheaShield() then
        print('[Ragdolo] Ragdoll ignoré (bouclier Prothea actif)')
        return
    end

    local duration <const> = GetRagdollDuration(level)
    SetPedToRagdoll(cache.ped, duration, duration, 0, false, false, false)
end)

RegisterNetEvent('th_ragdolo:prepareProjectile', function(targetId, level)
    local casterPed <const> = cache.ped
    local projectileDelay, cleanupDelay = GetAnimationTimings()

    CreateWandParticles(casterPed, true)

    CreateThread(function()
        Wait(projectileDelay)
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

        TriggerServerEvent('th_ragdolo:broadcastProjectile', finalTargetCoords, targetId or 0, level or 0)

        Wait(cleanupDelay)
        RemoveWandParticles(casterPed)
    end)
end)

RegisterNetEvent('th_ragdolo:otherPlayerCasting', function(sourceServerId)
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

RegisterNetEvent('th_ragdolo:spawnProjectile', function(sourceServerId, targetCoords, targetId, level)
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
    CreateRagdollProjectile(startCoords, targetCoords, sourceServerId, casterPed, targetId or 0, level or 0)
end)

AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then
        return
    end

    for propId, data in pairs(ragdollProjectiles) do
        if type(data) == "table" and DoesEntityExist(data.prop) then
            DeleteEntity(data.prop)
            DeleteObject(data.prop)
        end
    end
    ragdollProjectiles = {}

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
