---@diagnostic disable: undefined-global, trailing-space, unused-local, deprecated, param-type-mismatch, missing-parameter
local basicRayProps = {}
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

    SetParticleFxLoopedColour(handle, 0.0, 1.0, 0.0, false)
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


local function CreateBasicProjectile(startCoords, targetCoords, sourceServerId, casterPed)
    
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
    
    local duration <const> = (distance / Config.Projectile.speed) * 1000.0
    local startTime <const> = GetGameTimer()
    local endTime <const> = startTime + duration
    
    basicRayProps[rayProp] = {
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
        
        for propId, data in pairs(basicRayProps) do
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
                        AddExplosion(propCoords.x, propCoords.y, propCoords.z, 1, 0.001, false, false, 0.3)
                        
                        local playerCoords <const> = GetEntityCoords(cache.ped)
                        local distance = #(playerCoords - propCoords)
                        
                        if distance < 15.0 then
                            local intensity = math.max(0.05, 0.15 - (distance / 15.0))
                            ShakeGameplayCam('SMALL_EXPLOSION_SHAKE', intensity)
                        end
                        
                        RequestNamedPtfxAsset('ns_ptfx')
                        while not HasNamedPtfxAssetLoaded('ns_ptfx') do
                            Wait(0)
                        end
                        
                        local effects <const> = {}
                    
                        for i = 1, 3 do
                            UseParticleFxAssetNextCall('ns_ptfx')
                            local fx = StartParticleFxLoopedAtCoord('fire', propCoords.x, propCoords.y, propCoords.z - 0.3 + (i * 0.15), 0.0, 0.0, 0.0, 1.5, false, false, false, false)
                            SetParticleFxLoopedColour(fx, 1.0, 0.0, 0.0, 1.0)
                            table.insert(effects, fx)
                            allParticles[fx] = {
                                createdTime = GetGameTimer(),
                                type = 'explosion'
                            }
                        end
                        
                        for angle = 0, 360, 90 do
                            local rad <const> = math.rad(angle)
                            local offsetX <const> = math.cos(rad) * 0.5
                            local offsetY <const> = math.sin(rad) * 0.5
                            
                            UseParticleFxAssetNextCall('ns_ptfx')
                            local fx <const> = StartParticleFxLoopedAtCoord('fire', propCoords.x + offsetX, propCoords.y + offsetY, propCoords.z + 0.2, 0.0, 0.0, 0.0, 1.2, false, false, false, false)
                            SetParticleFxLoopedColour(fx, 1.0, 0.0, 0.0, 1.0)
                            table.insert(effects, fx)
                            allParticles[fx] = {
                                createdTime = GetGameTimer(),
                                type = 'explosion'
                            }
                        end
                        
                        RequestNamedPtfxAsset('core')
                        while not HasNamedPtfxAssetLoaded('core') do
                            Wait(0)
                        end
                        
                        for i = 1, 2 do
                            UseParticleFxAssetNextCall('core')
                            local smoke = StartParticleFxLoopedAtCoord('exp_grd_bzgas_smoke', propCoords.x, propCoords.y, propCoords.z + (i * 0.3), 0.0, 0.0, 0.0, 0.8, false, false, false, false)
                            table.insert(effects, smoke)
                            allParticles[smoke] = {
                                createdTime = GetGameTimer(),
                                type = 'smoke'
                            }
                        end
                        
                        SetTimeout(1500, function()
                            for _, fx in ipairs(effects) do
                                StopParticleFxLooped(fx, 0)
                                allParticles[fx] = nil
                            end
                            RemoveNamedPtfxAsset('ns_ptfx')
                            RemoveNamedPtfxAsset('core')
                        end)
                        
                        SetEntityVisible(data.prop, false, false)
                        SetEntityCoords(data.prop, 0.0, 0.0, -5000.0, false, false, false, false)
                        Wait(50)
                        DeleteEntity(data.prop)
                        DeleteObject(data.prop)
                    end
                    
                    basicRayProps[propId] = nil
                end
            end
        end
    end
end)

RegisterNetEvent('dvr_basic:prepareProjectile', function()
    local casterPed <const> = cache.ped
    
    CreateWandParticles(casterPed, true)
    
    CreateThread(function()
        local castDelay = Config.Animation and Config.Animation.duration and math.floor((Config.Animation.duration or 1200) * 0.55) or 660
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
        
        TriggerServerEvent('dvr_basic:broadcastProjectile', finalTargetCoords)
        
        Wait(800)
        RemoveWandParticles(casterPed)
    end)
end)

RegisterNetEvent('dvr_basic:otherPlayerCasting', function(sourceServerId)
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

RegisterNetEvent('dvr_basic:fireProjectile', function(sourceServerId, targetCoords)
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
    
    CreateBasicProjectile(startCoords, targetCoords, sourceServerId, casterPed)
end)

RegisterNetEvent('dvr_basic:removeHealth', function(level)
    local targetPed <const> = GetPlayerPed(GetPlayerFromServerId(PlayerPedId()))
    if not DoesEntityExist(targetPed) then
        return
    end
    
    local damage = math.floor(GetEntityHealth(targetPed) * 0.1)
    if damage <= 0 then
        damage = 1
    end
    
    SetEntityHealth(targetPed, GetEntityHealth(targetPed) - damage)
end)


AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    
    for propId, data in pairs(basicRayProps) do
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
    RemoveNamedPtfxAsset('ns_ptfx')
end)
