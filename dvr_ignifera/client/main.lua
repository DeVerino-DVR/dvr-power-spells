---@diagnostic disable: undefined-global, trailing-space, unused-local, deprecated, param-type-mismatch, missing-parameter
local igniferaRayProps = {}
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
        handle = StartNetworkedParticleFxLoopedOnEntity('veh_light_clear', weapon, 0.95, 0.0, 0.1, 0.0, 0.0, 0.0, 0.55, false, false, false)
    else
        handle = StartParticleFxLoopedOnEntity('veh_light_clear', weapon, 0.95, 0.0, 0.1, 0.0, 0.0, 0.0, 0.55, false, false, false)
    end

    -- Orange color for Ignifera (R: 1.0, G: 0.5, B: 0.0)
    SetParticleFxLoopedColour(handle, 1.0, 0.5, 0.0, false)
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

    SetParticleFxLoopedEvolution(trailHandle, 'speed', 1.0, false)
    -- Intense Orange/Red for the projectile
    SetParticleFxLoopedColour(trailHandle, 1.0, 0.4, 0.0, false)
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


local function CreateIgniferaProjectile(startCoords, targetCoords, sourceServerId, casterPed, spellLevel)
    
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
    direction = direction / distance
    
    local heading <const> = math.deg(math.atan2(direction.y, direction.x)) + 90.0
    local pitch <const> = -math.deg(math.asin(direction.z))
    local roll <const> = 0.0
    
    SetEntityCoords(rayProp, startCoords.x, startCoords.y, startCoords.z, false, false, false, false)
    SetEntityRotation(rayProp, pitch, roll, heading, 2, true)
    
    local trailHandle <const> = TransferWandTrailToProjectile(casterPed, rayProp)
    
    -- Speed from Config
    local speed = Config.Projectile and Config.Projectile.speed or 65.0
    local duration <const> = (distance / speed) * 1000.0
    local startTime <const> = GetGameTimer()
    local endTime <const> = startTime + duration
    
    igniferaRayProps[rayProp] = {
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
        spellLevel = spellLevel or 1
    }
end

CreateThread(function()
    while true do
        Wait(30000)
        
        local currentTime = GetGameTimer()
        local particlesToRemove = {}
        
        for particleHandle, particleData in pairs(allParticles) do
            if currentTime - particleData.createdTime > 10000 then
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
        
        for propId, data in pairs(igniferaRayProps) do
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
                        local level = data.spellLevel or 1
                        
                        -- IMPORTANT: Notify server BEFORE explosion to protect players
                        local myServerId = GetPlayerServerId(PlayerId())
                        if data.sourceServerId == myServerId then
                            TriggerServerEvent('dvr_ignifera:applyExplosionDamage', propCoords, level)
                        end
                        
                        -- Delay to let server protect players before explosion (increased for reliability)
                        Wait(200)
                        
                        -- Explosion scaling based on spell level (visual only)
                        local baseScale = 0.01 + (level * 0.02)
                        AddExplosion(propCoords.x, propCoords.y, propCoords.z, 2, baseScale, true, false, 0.3)
                        
                        local visualScale = 0.08 + (level * 0.04)
                        AddExplosion(propCoords.x, propCoords.y, propCoords.z, 82, visualScale, true, false, 0.3)
                        
                        if level >= 3 then
                             AddExplosion(propCoords.x, propCoords.y, propCoords.z, 82, visualScale * 0.5, true, false, 0.2)
                        end
                        
                        if level >= 5 then
                             AddExplosion(propCoords.x, propCoords.y, propCoords.z, 82, visualScale * 0.8, true, false, 0.2)
                             AddExplosion(propCoords.x, propCoords.y, propCoords.z, 2, 0.15, true, false, 0.2)
                        end
                        
                        local playerCoords <const> = GetEntityCoords(cache.ped)
                        local distance = #(playerCoords - propCoords)
                        
                        -- Dynamic shake range and intensity - reduced
                        local shakeRange = 15.0 + (level * 5.0)
                        if distance < shakeRange then
                            local maxIntensity = 0.05 + (level * 0.05) -- Much gentler shake
                            local intensity = math.max(0.03, maxIntensity * (1.0 - (distance / shakeRange)))
                            ShakeGameplayCam('SMALL_EXPLOSION_SHAKE', intensity)
                        end
                        
                        -- Fire particles scaling - smaller flames
                        RequestNamedPtfxAsset('core')
                        if HasNamedPtfxAssetLoaded('core') then
                             UseParticleFxAssetNextCall('core')
                             local fireScale = 0.3 + (level * 0.15)
                             local fire = StartParticleFxLoopedAtCoord('ent_ray_heli_aprtmnt_l_fire', propCoords.x, propCoords.y, propCoords.z, 0.0, 0.0, 0.0, fireScale, false, false, false, false)
                             allParticles[fire] = {
                                createdTime = GetGameTimer(),
                                type = 'fire'
                             }
                             
                             SetTimeout(2000 + (level * 300), function()
                                StopParticleFxLooped(fire, false)
                                allParticles[fire] = nil
                             end)
                        end

                        SetEntityVisible(data.prop, false, false)
                        SetEntityCoords(data.prop, 0.0, 0.0, -5000.0, false, false, false, false)
                        Wait(50)
                        DeleteEntity(data.prop)
                        DeleteObject(data.prop)
                    end
                    
                    igniferaRayProps[propId] = nil
                end
            end
        end
    end
end)

RegisterNetEvent('dvr_ignifera:prepareProjectile', function(spellLevel)
    local casterPed <const> = cache.ped
    
    CreateWandParticles(casterPed, true)
    
    CreateThread(function()
        -- Recalculate delay based on speedMultiplier
        local duration = Config.Animation.duration or 3000
        local speed = Config.Animation.speedMultiplier or 1.0
        local realDuration = duration / speed
        
        -- Trigger projectile earlier (around 30-35% of the animation)
        local castDelay = math.floor(realDuration * 0.55)
        
        if castDelay < 0 then castDelay = 0 end
        Wait(castDelay)
        local handBone <const> = GetPedBoneIndex(casterPed, 28422)
        local startCoords <const> = GetWorldPositionOfEntityBone(casterPed, handBone)
        
        local camCoords <const> = GetGameplayCamCoord()
        local camRot <const> = GetGameplayCamRot(2)
        local direction <const> = RotationToDirection(camRot)
        
        local hit, entityHit, coords = lib.raycast.cam(1 | 2 | 4 | 8 | 16, 4, 1000)
        local finalTargetCoords
        
        if coords and (coords.x ~= 0.0 or coords.y ~= 0.0 or coords.z ~= 0.0) then
            finalTargetCoords = coords
        else
            finalTargetCoords = vector3(
                camCoords.x + direction.x * 1000.0,
                camCoords.y + direction.y * 1000.0,
                camCoords.z + direction.z * 1000.0
            )
        end
        
        TriggerServerEvent('dvr_ignifera:broadcastProjectile', finalTargetCoords, spellLevel)
        
        Wait(800)
        RemoveWandParticles(casterPed)
    end)
end)

RegisterNetEvent('dvr_ignifera:otherPlayerCasting', function(sourceServerId)
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

RegisterNetEvent('dvr_ignifera:fireProjectile', function(sourceServerId, targetCoords, spellLevel)
    local casterPlayer <const> = GetPlayerFromServerId(sourceServerId)
    if casterPlayer == -1 then 
        return 
    end
    
    local casterPed <const> = GetPlayerPed(casterPlayer)
    if not DoesEntityExist(casterPed) then 
        return 
    end
    
    local handBone <const> = GetPedBoneIndex(casterPed, 28422)
    local startCoords <const> = GetWorldPositionOfEntityBone(casterPed, handBone)
    
    CreateIgniferaProjectile(startCoords, targetCoords, sourceServerId, casterPed, spellLevel)
end)

AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    
    for propId, data in pairs(igniferaRayProps) do
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
