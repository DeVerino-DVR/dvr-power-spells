---@diagnostic disable: undefined-global, trailing-space, unused-local, param-type-mismatch, missing-parameter, deprecated

local projectiles = {}
local wandParticles = {}

local RequestNamedPtfxAsset = RequestNamedPtfxAsset
local HasNamedPtfxAssetLoaded = HasNamedPtfxAssetLoaded
local UseParticleFxAsset = UseParticleFxAsset
local UseParticleFxAssetNextCall = UseParticleFxAssetNextCall
local StartNetworkedParticleFxLoopedOnEntity = StartNetworkedParticleFxLoopedOnEntity
local StartParticleFxLoopedOnEntity = StartParticleFxLoopedOnEntity
local StopParticleFxLooped = StopParticleFxLooped
local RemoveParticleFx = RemoveParticleFx
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
local DeleteObject = DeleteObject
local DeleteEntity = DeleteEntity
local DoesEntityExist = DoesEntityExist
local PlayerPedId = PlayerPedId

local function RotationToDirection(rotation)
    local adjustedRotation = {
        x = (math.pi / 180) * rotation.x,
        y = (math.pi / 180) * rotation.y,
        z = (math.pi / 180) * rotation.z
    }
    local direction = {
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

local function RemoveWandParticles(playerPed)
    local handle = wandParticles[playerPed]
    if handle then
        StopParticleFxLooped(handle, false)
        RemoveParticleFx(handle, false)
        wandParticles[playerPed] = nil
    end
end

local function CleanupProjectile(propId)
    local data = projectiles[propId]
    if not data then return end
    if DoesEntityExist(data.prop) then
        SetEntityVisible(data.prop, false, false)
        SetEntityCoords(data.prop, 0.0, 0.0, -5000.0, false, false, false, false)
        DeleteEntity(data.prop)
        DeleteObject(data.prop)
    end
    projectiles[propId] = nil
end

local function CreateCoagulisProjectile(startCoords, targetCoords, sourceServerId)
    local propModel = GetHashKey(Config.Projectile.model)
    lib.requestModel(propModel, 5000)
    local rayProp = CreateObject(propModel, startCoords.x, startCoords.y, startCoords.z, false, false, false)
    SetEntityCollision(rayProp, false, false)
    SetEntityAsMissionEntity(rayProp, true, true)
    SetEntityCompletelyDisableCollision(rayProp, true, false)
    SetEntityAlpha(rayProp, 255, false)

    local direction = vector3(targetCoords.x - startCoords.x, targetCoords.y - startCoords.y, targetCoords.z - startCoords.z)
    local distance = #direction
    if distance <= 0.001 then distance = 0.001 end
    direction = direction / distance

    local heading = math.deg(math.atan2(direction.y, direction.x)) + 90.0
    local pitch = -math.deg(math.asin(direction.z))
    local roll = 0.0

    SetEntityCoords(rayProp, startCoords.x, startCoords.y, startCoords.z, false, false, false, false)
    SetEntityRotation(rayProp, pitch, roll, heading, 2, true)

    local duration = (distance / (Config.Projectile.speed or 80.0)) * 1000.0
    local startTime = GetGameTimer()
    local endTime = startTime + duration

    projectiles[rayProp] = {
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
        sourceServerId = sourceServerId
    }
end

-- Move projectiles
CreateThread(function()
    while true do
        Wait(1)
        local currentTime = GetGameTimer()
        for propId, data in pairs(projectiles) do
            if type(data) == "table" then
                if currentTime < data.endTime and DoesEntityExist(data.prop) then
                    local progress = (currentTime - data.startTime) / (data.endTime - data.startTime)
                    progress = math.min(progress, 1.0)
                    local newPos = vector3(
                        data.startCoords.x + (data.direction.x * data.distance * progress),
                        data.startCoords.y + (data.direction.y * data.distance * progress),
                        data.startCoords.z + (data.direction.z * data.distance * progress)
                    )
                    SetEntityCoords(data.prop, newPos.x, newPos.y, newPos.z, false, false, false, false)
                    if data.heading and data.pitch and data.roll then
                        SetEntityRotation(data.prop, data.pitch, data.roll, data.heading, 2, true)
                    end
                    
                    -- Check for player collision
                    local propCoords = GetEntityCoords(data.prop)
                    local myPed = (cache and cache.ped) or PlayerPedId()
                    if DoesEntityExist(myPed) then
                        local myCoords = GetEntityCoords(myPed)
                        local dist = #(propCoords - myCoords)
                        if dist < 1.5 then
                            TriggerServerEvent('th_coagulis:stopBleedServer', GetPlayerServerId(PlayerId()))
                            CleanupProjectile(propId)
                            goto continue
                        end
                    end
                end
                if currentTime >= data.endTime then
                    CleanupProjectile(propId)
                end
            end
            ::continue::
        end
    end
end)

RegisterNetEvent('th_coagulis:stopBleedRemote', function(targetId)
    local me = GetPlayerServerId(PlayerId())
    if targetId == 0 or targetId == me then
        TriggerEvent('th_sanguiris:stopBleed')
        lib.notify({
            title = 'Coagulis',
            description = 'Le saignement est stoppé.',
            type = 'success'
        })
    end
end)

RegisterNetEvent('th_coagulis:prepareProjectile', function()
    local casterPed = (cache and cache.ped) or PlayerPedId()
    
    CreateWandParticles(casterPed, true)
    
    CreateThread(function()
        Wait(Config.Animation.propsDelay or 1500)
        local camCoords = GetGameplayCamCoord()
        local camRot = GetGameplayCamRot(2)
        local direction = RotationToDirection(camRot)
        
        local _, _, coords = lib.raycast.cam(1 | 2 | 4 | 8 | 16, 4, Config.Projectile.maxDistance or 1000.0)
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
        
        TriggerServerEvent('th_coagulis:broadcastProjectile', finalTargetCoords)
        
        Wait(800)
        RemoveWandParticles(casterPed)
    end)
end)

RegisterNetEvent('th_coagulis:otherPlayerCasting', function(sourceServerId)
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
    
    SetTimeout(2000, function()
        RemoveWandParticles(casterPed)
    end)
end)

RegisterNetEvent('th_coagulis:fireProjectile', function(sourceServerId, targetCoords)
    local casterPlayer = GetPlayerFromServerId(sourceServerId)
    if casterPlayer == -1 then
        return
    end
    
    local casterPed = GetPlayerPed(casterPlayer)
    if not DoesEntityExist(casterPed) then
        return
    end
    
    if not targetCoords then
        return
    end
    
    local handBone = GetPedBoneIndex(casterPed, Config.Projectile.handBone)
    local startCoords = GetWorldPositionOfEntityBone(casterPed, handBone)
    
    CreateCoagulisProjectile(startCoords, targetCoords, sourceServerId)
end)

AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then
        return
    end
    
    for propId, data in pairs(projectiles) do
        if type(data) == "table" and DoesEntityExist(data.prop) then
            DeleteObject(data.prop)
            DeleteEntity(data.prop)
        end
    end
    
    for _, handle in pairs(wandParticles) do
        if handle then
            StopParticleFxLooped(handle, false)
            RemoveParticleFx(handle, false)
        end
    end
    
    projectiles = {}
    wandParticles = {}
end)
