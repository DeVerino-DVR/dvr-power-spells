---@diagnostic disable: undefined-global, trailing-space, unused-local, deprecated, param-type-mismatch, missing-parameter
local signalisRayProps = {}
local wandParticles = {}
local allParticles = {}
local RequestNamedPtfxAsset = RequestNamedPtfxAsset
local HasNamedPtfxAssetLoaded = HasNamedPtfxAssetLoaded
local UseParticleFxAsset = UseParticleFxAsset
local StartNetworkedParticleFxLoopedOnEntity = StartNetworkedParticleFxLoopedOnEntity
local StartParticleFxLoopedOnEntity = StartParticleFxLoopedOnEntity
local SetParticleFxLoopedEvolution = SetParticleFxLoopedEvolution
local SetParticleFxLoopedColour = SetParticleFxLoopedColour
local SetParticleFxLoopedAlpha = SetParticleFxLoopedAlpha
local StopParticleFxLooped = StopParticleFxLooped
local RemoveParticleFx = RemoveParticleFx
local RemoveNamedPtfxAsset = RemoveNamedPtfxAsset
local DeleteObject = DeleteObject
local DeleteEntity = DeleteEntity
local DoesEntityExist = DoesEntityExist
local AddExplosion = AddExplosion
local ShakeGameplayCam = ShakeGameplayCam
local GetGameTimer = GetGameTimer
local GetGameplayCamCoord = GetGameplayCamCoord
local GetGameplayCamRot = GetGameplayCamRot
local GetPedBoneIndex = GetPedBoneIndex
local GetWorldPositionOfEntityBone = GetWorldPositionOfEntityBone
local GetEntityCoords = GetEntityCoords
local GetEntityHeading = GetEntityHeading
local GetEntityRotation = GetEntityRotation
local SetEntityCoords = SetEntityCoords
local SetEntityRotation = SetEntityRotation
local SetEntityAlpha = SetEntityAlpha
local SetEntityCollision = SetEntityCollision
local SetEntityAsMissionEntity = SetEntityAsMissionEntity
local SetEntityCompletelyDisableCollision = SetEntityCompletelyDisableCollision
local UseParticleFxAssetNextCall = UseParticleFxAssetNextCall
local StartParticleFxLoopedAtCoord = StartParticleFxLoopedAtCoord
local StartParticleFxNonLoopedAtCoord = StartParticleFxNonLoopedAtCoord
local StartNetworkedParticleFxNonLoopedAtCoord = StartNetworkedParticleFxNonLoopedAtCoord
local GetGroundZFor_3dCoord = GetGroundZFor_3dCoord
local SetEntityVisible = SetEntityVisible
local StartParticleFxNonLoopedOnEntity = StartParticleFxNonLoopedOnEntity
local StartNetworkedParticleFxNonLoopedOnEntity = StartNetworkedParticleFxNonLoopedOnEntity

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

local function EnsurePtfxAssetLoaded(asset)
    if not asset or asset == '' then
        return false
    end
    RequestNamedPtfxAsset(asset)
    while not HasNamedPtfxAssetLoaded(asset) do
        Wait(0)
    end
    return true
end

local function StartFlare(coords)
    local flareCfg = Config.Effects and Config.Effects.flare
    if not flareCfg or not coords then
        return
    end

    if not EnsurePtfxAssetLoaded(flareCfg.asset) then
        return
    end

    UseParticleFxAssetNextCall(flareCfg.asset)
    local flare = StartParticleFxLoopedAtCoord(flareCfg.name, coords.x, coords.y, coords.z, 0.0, 0.0, 0.0, flareCfg.scale or 1.0, false, false, false, false)
    SetParticleFxLoopedColour(flare, 1.0, 0.0, 0.0, 1.0)

    allParticles[flare] = {
        createdTime = GetGameTimer(),
        type = 'flare'
    }

    local duration = flareCfg.duration or 6000
    SetTimeout(duration, function()
        StopParticleFxLooped(flare, false)
        RemoveParticleFx(flare, false)
        allParticles[flare] = nil
    end)

    RemoveNamedPtfxAsset(flareCfg.asset)
end

local function StartSmoke(coords)
    local smokeCfg = Config.Effects and Config.Effects.smoke
    if not smokeCfg or not coords then
        return
    end

    if not EnsurePtfxAssetLoaded(smokeCfg.asset) then
        return
    end

    local heightOffset = smokeCfg.heightOffset or 2.0

    UseParticleFxAssetNextCall(smokeCfg.asset)
    local smoke = StartParticleFxLoopedAtCoord(smokeCfg.name, coords.x, coords.y, coords.z + heightOffset, 0.0, 0.0, 0.0, smokeCfg.scale or 4.0, false, false, false, false)
    SetParticleFxLoopedColour(smoke, 1.0, 0.0, 0.0, 1.0)
    SetParticleFxLoopedEvolution(smoke, 'size', 1.0, false)

    allParticles[smoke] = {
        createdTime = GetGameTimer(),
        type = 'smoke'
    }

    local duration = smokeCfg.duration or 18000
    SetTimeout(duration, function()
        StopParticleFxLooped(smoke, false)
        RemoveParticleFx(smoke, false)
        allParticles[smoke] = nil
    end)

    RemoveNamedPtfxAsset(smokeCfg.asset)
end

local function ClampSkyTarget(startCoords, targetCoords)
    local maxDistance = (Config.Projectile and Config.Projectile.maxDistance) or 200.0
    local maxHeight = (Config.Projectile and Config.Projectile.maxHeightAboveGround) or 200.0

    local delta = vector3(
        targetCoords.x - startCoords.x,
        targetCoords.y - startCoords.y,
        targetCoords.z - startCoords.z
    )

    local distance = #delta
    if distance < 0.001 then
        return startCoords
    end

    local clampedDist = math.min(distance, maxDistance)
    local direction = delta / distance
    local clamped = vector3(
        startCoords.x + direction.x * clampedDist,
        startCoords.y + direction.y * clampedDist,
        startCoords.z + direction.z * clampedDist
    )

    local foundGround, groundZ = GetGroundZFor_3dCoord(clamped.x, clamped.y, clamped.z + 200.0, false)
    local baseZ = foundGround and groundZ or startCoords.z
    local maxZ = baseZ + maxHeight
    if clamped.z > maxZ then
        clamped = vector3(clamped.x, clamped.y, maxZ)
    end

    return clamped
end

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
        handle = StartNetworkedParticleFxLoopedOnEntity('veh_light_red_trail', weapon, 0.95, 0.0, 0.1, 0.0, 0.0, 0.0, 0.55, false, false, false)
    else
        handle = StartParticleFxLoopedOnEntity('veh_light_red_trail', weapon, 0.95, 0.0, 0.1, 0.0, 0.0, 0.0, 0.55, false, false, false)
    end
    
    UseParticleFxAssetNextCall('core')
    if isNetworked then
        StartNetworkedParticleFxNonLoopedOnEntity('veh_light_red_trail', weapon, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 1.0, false, false, false)
    else
        StartParticleFxNonLoopedOnEntity('veh_light_red_trail', weapon, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 1.0, false, false, false)
    end

    SetParticleFxLoopedColour(handle, 1.0, 0.0, 0.0, false)
    SetParticleFxLoopedAlpha(handle, 220)

    wandParticles[playerPed] = handle
    return handle
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

    local trailName = Config.Effects.projectileTrail.name
    local scale = Config.Effects.projectileTrail.scale

    if isNetworked then
        StartNetworkedParticleFxNonLoopedOnEntity(trailName, rayProp, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, scale, false, false, false)
    else
        StartParticleFxNonLoopedOnEntity(trailName, rayProp, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, scale, false, false, false)
    end

    local trailHandle
    if isNetworked then
        trailHandle = StartNetworkedParticleFxLoopedOnEntity(trailName, rayProp, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, scale, false, false, false)
    else
        trailHandle = StartParticleFxLoopedOnEntity(trailName, rayProp, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, scale, false, false, false)
    end

    SetParticleFxLoopedEvolution(trailHandle, 'speed', 1.0, false)
    SetParticleFxLoopedColour(trailHandle, 1.0, 0.0, 0.0, false)
    SetParticleFxLoopedAlpha(trailHandle, 255.0)

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


local function CreateSignalisProjectile(startCoords, targetCoords, sourceServerId, casterPed)
    local propModel <const> = GetHashKey("nib_magic_ray_basic")
    lib.requestModel(propModel, 5000)
    
    local rayProp <const> = CreateObject(propModel, startCoords.x, startCoords.y, startCoords.z, false, false, false)
    
    if not DoesEntityExist(rayProp) then
        return
    end
    
    SetEntityCollision(rayProp, false, false)
    SetEntityAsMissionEntity(rayProp, true, true)
    SetEntityCompletelyDisableCollision(rayProp, true, false)

    local direction = vector3(
        targetCoords.x - startCoords.x,
        targetCoords.y - startCoords.y,
        targetCoords.z - startCoords.z
    )
    local distance = #direction
    direction = direction / distance
    
    local heading <const> = math.deg(math.atan2(direction.y, direction.x)) + 90.0
    local pitch <const> = -math.deg(math.asin(direction.z))
    local roll <const> = 0.0
    
    SetEntityCoords(rayProp, startCoords.x, startCoords.y, startCoords.z, false, false, false, false)
    SetEntityRotation(rayProp, pitch, roll, heading, 2, true)
    -- SetEntityVisible(rayProp, false, false)
    
    local trailHandle <const> = TransferWandTrailToProjectile(casterPed, rayProp)
    
    local duration <const> = (distance / Config.Projectile.speed) * 1000.0
    local startTime <const> = GetGameTimer()
    local endTime <const> = startTime + duration
    
    signalisRayProps[rayProp] = {
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
        trailHandle = trailHandle
    }
end

CreateThread(function()
    while true do
        Wait(30000)

        local currentTime = GetGameTimer()
        local particlesToRemove = {}

        for particleHandle, particleData in pairs(allParticles) do
            if currentTime - particleData.createdTime > 15000 then
                table.insert(particlesToRemove, particleHandle)
            end
        end

        for _, particleHandle in ipairs(particlesToRemove) do
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
        
        for propId, data in pairs(signalisRayProps) do
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
                    
                    if progress >= 1.0 and not data.exploded then
                        data.exploded = true
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

                        StartFlare(propCoords)
                        StartSmoke(propCoords)

                        SetEntityVisible(data.prop, false, false)
                        SetEntityCoords(data.prop, 0.0, 0.0, -5000.0, false, false, false, false)
                        Wait(50)
                        DeleteEntity(data.prop)
                        DeleteObject(data.prop)
                    end
                    
                    signalisRayProps[propId] = nil
                end
            end
        end
    end
end)

RegisterNetEvent('th_signalis:prepareProjectile', function()
    local casterPed <const> = cache.ped
    
    CreateWandParticles(casterPed, true)
    
    CreateThread(function()
        local castDelay = 600
        Wait(castDelay)
        local handBone <const> = GetPedBoneIndex(casterPed, 28422)
        local startCoords <const> = GetWorldPositionOfEntityBone(casterPed, handBone)
        
        local camCoords <const> = GetGameplayCamCoord()
        local camRot <const> = GetGameplayCamRot(2)
        local direction <const> = RotationToDirection(camRot)
        
        local hit, entityHit, coords = lib.raycast.cam(1 | 2 | 4 | 8 | 16, 4, Config.Projectile.maxDistance)
        local finalTargetCoords
        
        if hit and coords and (coords.x ~= 0.0 or coords.y ~= 0.0 or coords.z ~= 0.0) then
            finalTargetCoords = coords
        else
            local noHitTarget = vector3(
                camCoords.x + direction.x * Config.Projectile.maxDistance,
                camCoords.y + direction.y * Config.Projectile.maxDistance,
                camCoords.z + direction.z * Config.Projectile.maxDistance
            )
            finalTargetCoords = ClampSkyTarget(startCoords, noHitTarget)
        end
        
        TriggerServerEvent('th_signalis:broadcastProjectile', finalTargetCoords)
        
        Wait(800)
        RemoveWandParticles(casterPed)
    end)
end)

RegisterNetEvent('th_signalis:otherPlayerCasting', function(sourceServerId)
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
    
    SetTimeout(3000, function()
        RemoveWandParticles(casterPed)
    end)
end)

RegisterNetEvent('th_signalis:fireProjectile', function(sourceServerId, targetCoords)
    local casterPlayer <const> = GetPlayerFromServerId(sourceServerId)
    if casterPlayer == -1 then 
        return 
    end
    
    local casterPed <const> = GetPlayerPed(casterPlayer)
    if not DoesEntityExist(casterPed) then 
        return 
    end
    
    local isLocalPlayer = (casterPlayer == PlayerId())
    local handBone <const> = GetPedBoneIndex(casterPed, 28422)
    local startCoords <const> = GetWorldPositionOfEntityBone(casterPed, handBone)
    
    CreateSignalisProjectile(startCoords, targetCoords, sourceServerId, casterPed)
end)

AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    
    for propId, data in pairs(signalisRayProps) do
        if type(data) == "table" and DoesEntityExist(data.prop) then
            RemoveParticleFxFromEntity(data.prop)
            DeleteEntity(data.prop)
            DeleteObject(data.prop)
        end
    end
    
    for ped, handle in pairs(wandParticles) do
        RemoveParticleFx(handle, false)
    end
    wandParticles = {}
    
    for particleHandle, particleData in pairs(allParticles) do
        StopParticleFxLooped(particleHandle, false)
        RemoveParticleFx(particleHandle, false)
    end
    allParticles = {}

    RemoveNamedPtfxAsset('core')
end)
