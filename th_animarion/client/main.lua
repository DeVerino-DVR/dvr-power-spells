---@diagnostic disable: trailing-space, undefined-global, param-type-mismatch
local Config = require 'config'
local animagusRayProps = {}
local wandParticles = {}
local GetCurrentPedWeaponEntityIndex = GetCurrentPedWeaponEntityIndex
local DoesEntityExist = DoesEntityExist
local GetPedBoneIndex = GetPedBoneIndex
local GetWorldPositionOfEntityBone = GetWorldPositionOfEntityBone
local GetGameplayCamCoord = GetGameplayCamCoord
local GetGameplayCamRot = GetGameplayCamRot
local GetPlayerServerId = GetPlayerServerId
local GetPlayerFromServerId = GetPlayerFromServerId
local GetPlayerPed = GetPlayerPed
local SetTimeout = SetTimeout
local DeleteObject = DeleteObject
local DeleteEntity = DeleteEntity
local SetEntityAsMissionEntity = SetEntityAsMissionEntity
local SetEntityAlpha = SetEntityAlpha
local SetEntityCollision = SetEntityCollision
local SetEntityCompletelyDisableCollision = SetEntityCompletelyDisableCollision
local SetEntityCoords = SetEntityCoords
local SetEntityRotation = SetEntityRotation
local SetEntityHeading = SetEntityHeading
local SetPlayerModel = SetPlayerModel
local SetModelAsNoLongerNeeded = SetModelAsNoLongerNeeded
local RequestNamedPtfxAsset = RequestNamedPtfxAsset
local HasNamedPtfxAssetLoaded = HasNamedPtfxAssetLoaded
local UseParticleFxAsset = UseParticleFxAsset
local StartParticleFxLoopedOnEntity = StartParticleFxLoopedOnEntity
local SetParticleFxLoopedColour = SetParticleFxLoopedColour
local SetParticleFxLoopedAlpha = SetParticleFxLoopedAlpha
local StartParticleFxLoopedAtCoord = StartParticleFxLoopedAtCoord
local StopParticleFxLooped = StopParticleFxLooped
local RemoveParticleFx = RemoveParticleFx
local RemoveNamedPtfxAsset = RemoveNamedPtfxAsset
local StartNetworkedParticleFxLoopedOnEntity = StartNetworkedParticleFxLoopedOnEntity
local NetworkGetPlayerIndexFromPed = NetworkGetPlayerIndexFromPed
local IsPedAPlayer = IsPedAPlayer
local CreatePed = CreatePed
local SetPedAsNoLongerNeeded = SetPedAsNoLongerNeeded
local TaskWanderStandard = TaskWanderStandard
local NetworkRegisterEntityAsNetworked = NetworkRegisterEntityAsNetworked
local NetworkGetEntityIsNetworked = NetworkGetEntityIsNetworked
local SetPedFleeAttributes = SetPedFleeAttributes
local GetEntityHeading = GetEntityHeading
local GetEntityCoords = GetEntityCoords
local GetGameTimer = GetGameTimer
local GetHashKey = GetHashKey
local IsEntityAPed = IsEntityAPed

local function ResolveSpellLevel(spellId, sourceId, providedLevel)
    local numeric = tonumber(providedLevel)
    if numeric then
        return math.floor(numeric)
    end

    local cache = spellCastLevelCache
    if cache and cache[sourceId] and cache[sourceId][spellId] and cache[sourceId][spellId].level then
        return math.floor(tonumber(cache[sourceId][spellId].level) or 0)
    end

    return 0
end

local function CalculateTransformDuration(level)
    local maxDuration = Config.Animagus.duration or 30000
    local minDuration = math.floor(maxDuration * 0.2)
    local lvl = math.max(0, math.floor(tonumber(level) or 0))
    local ratio = math.min(lvl / 5.0, 1.0)

    return math.floor(minDuration + ((maxDuration - minDuration) * ratio))
end

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
    local weapon <const> = GetCurrentPedWeaponEntityIndex(playerPed)
    if not weapon or not DoesEntityExist(weapon) then 
        return 
    end
    
    RequestNamedPtfxAsset(Config.Effects.wandParticles.asset)
    while not HasNamedPtfxAssetLoaded(Config.Effects.wandParticles.asset) do
        Wait(0)
    end
    
    UseParticleFxAsset(Config.Effects.wandParticles.asset)
    local handle
    if isNetworked then
        handle = StartNetworkedParticleFxLoopedOnEntity(
            Config.Effects.wandParticles.name, 
            weapon, 
            0.95, 0.0, 0.1, 
            0.0, 0.0, 0.0, 
            Config.Effects.wandParticles.scale, 
            false, false, false
        )
    else
        handle = StartParticleFxLoopedOnEntity(
            Config.Effects.wandParticles.name, 
            weapon, 
            0.95, 0.0, 0.1, 
            0.0, 0.0, 0.0, 
            Config.Effects.wandParticles.scale, 
            false, false, false
        )
    end
    
    SetParticleFxLoopedColour(handle, 
        Config.Effects.wandParticles.color.r, 
        Config.Effects.wandParticles.color.g, 
        Config.Effects.wandParticles.color.b, 
        false
    )
    SetParticleFxLoopedAlpha(handle, 255.0)
    
    wandParticles[playerPed] = handle
    
    return handle
end

local function RemoveWandParticles(playerPed)
    if wandParticles[playerPed] then
        StopParticleFxLooped(wandParticles[playerPed], false)
        RemoveParticleFx(wandParticles[playerPed], false)
        wandParticles[playerPed] = nil
        RemoveNamedPtfxAsset(Config.Effects.wandParticles.asset)
    end
end

local function CreateAnimagusProjectile(startCoords, targetCoords, sourceServerId, targetEntity, level, duration)
    local propModel = GetHashKey(Config.Projectile.model)
    lib.requestModel(propModel, 5000)
    
    local rayProp = CreateObject(propModel, startCoords.x, startCoords.y, startCoords.z, false, false, false)
    SetEntityCollision(rayProp, false, false)
    SetEntityAsMissionEntity(rayProp, true, true)
    SetEntityCompletelyDisableCollision(rayProp, false, false)
    SetEntityAlpha(rayProp, 255, false)
    
    RequestNamedPtfxAsset(Config.Effects.projectileTrail.asset)
    while not HasNamedPtfxAssetLoaded(Config.Effects.projectileTrail.asset) do
        Wait(0)
    end
    
    UseParticleFxAsset(Config.Effects.projectileTrail.asset)
    local trailFx = StartParticleFxLoopedOnEntity(
        Config.Effects.projectileTrail.name,
        rayProp,
        0.0, 0.0, 0.0,
        0.0, 0.0, 0.0,
        Config.Effects.projectileTrail.scale,
        false, false, false
    )
    
    if trailFx then
        SetParticleFxLoopedColour(trailFx,
            Config.Effects.projectileTrail.color.r,
            Config.Effects.projectileTrail.color.g,
            Config.Effects.projectileTrail.color.b,
            false
        )
    end
    
    local direction = vector3(
        targetCoords.x - startCoords.x,
        targetCoords.y - startCoords.y,
        targetCoords.z - startCoords.z
    )
    local distance <const> = #direction
    direction = direction / distance
    
    local heading <const> = math.deg(math.atan(direction.y, direction.x)) + 90.0
    local pitch <const> = -math.deg(math.asin(direction.z))
    local roll <const> = 0.0
    
    SetEntityCoords(rayProp, startCoords.x, startCoords.y, startCoords.z, false, false, false, false)
    SetEntityRotation(rayProp, pitch, roll, heading, 2, true)
    
    local flightDuration <const> = Config.Projectile.duration or (distance / Config.Projectile.speed) * 1000.0
    local startTime <const> = GetGameTimer()
    local endTime <const> = startTime + flightDuration
    local spellLevel = math.max(0, math.floor(tonumber(level) or 0))
    local transformDuration = duration or CalculateTransformDuration(spellLevel)
    
    animagusRayProps[rayProp] = {
        prop = rayProp,
        startCoords = startCoords,
        targetCoords = targetCoords,
        direction = direction,
        distance = distance,
        startTime = startTime,
        endTime = endTime,
        targetEntity = targetEntity,
        trailFx = trailFx,
        level = spellLevel,
        transformDuration = transformDuration,
        sourceServerId = sourceServerId
    }
end

CreateThread(function()
    while true do
        Wait(1)
        
        local currentTime <const> = GetGameTimer()
        
        for propId, data in pairs(animagusRayProps) do
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
                    else
                        if DoesEntityExist(data.prop) then 
                            if data.trailFx then
                                StopParticleFxLooped(data.trailFx, 0)
                                RemoveParticleFx(data.trailFx, false)
                            end
                            RemoveNamedPtfxAsset(Config.Effects.projectileTrail.asset)
                            
                            if data.targetEntity and DoesEntityExist(data.targetEntity) then
                                if IsEntityAPed(data.targetEntity) then
                                    local transformDuration = data.transformDuration or CalculateTransformDuration(data.level or 0)

                                    if IsPedAPlayer(data.targetEntity) then
                                        local targetPlayer = NetworkGetPlayerIndexFromPed(data.targetEntity)
                                        local targetServerId = GetPlayerServerId(targetPlayer)
                                        TriggerServerEvent('th_animarion:transformPlayer', targetServerId)
                                    else
                                        local randomAnimal = Config.Animagus.animals[math.random(#Config.Animagus.animals)]
                                        TriggerEvent('th_animarion:transformPed', data.targetEntity, randomAnimal, transformDuration)
                                    end
                                end
                            end
                            
                            DeleteObject(data.prop)
                            SetEntityAsMissionEntity(data.prop, false, true)
                            DeleteEntity(data.prop)
                        end
                        
                        animagusRayProps[propId] = nil
                    end
                else
                    animagusRayProps[propId] = nil
                end
            end
        end
    end
end)

RegisterNetEvent('th_animarion:prepareProjectile', function()
    local casterPed = cache.ped
    
    CreateWandParticles(casterPed, true)
    
    CreateThread(function()
        Wait(Config.Animation.propsDelay)
        local camCoords = GetGameplayCamCoord()
        local camRot = GetGameplayCamRot(2)
        local direction = RotationToDirection(camRot)
        
        local _, entityHit, coords = lib.raycast.cam(1 | 2 | 4 | 8 | 16, 4, 1000)
        local finalTargetCoords
        local targetEntity = nil
        
        if coords and (coords.x ~= 0.0 or coords.y ~= 0.0 or coords.z ~= 0.0) then
            finalTargetCoords = coords
            if entityHit and DoesEntityExist(entityHit) and IsEntityAPed(entityHit) then
                targetEntity = entityHit
            end
        else
            finalTargetCoords = vector3(
                camCoords.x + direction.x * 1000.0,
                camCoords.y + direction.y * 1000.0,
                camCoords.z + direction.z * 1000.0
            )
        end
        
        TriggerServerEvent('th_animarion:broadcastProjectile', finalTargetCoords, targetEntity)
        
        Wait(800)
        RemoveWandParticles(casterPed)
    end)
end)

RegisterNetEvent('th_animarion:otherPlayerCasting', function(sourceServerId)
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

RegisterNetEvent('th_animarion:fireProjectile', function(sourceServerId, targetCoords, targetEntity, level, duration)
    local casterPlayer = GetPlayerFromServerId(sourceServerId)
    if casterPlayer == -1 then 
        return 
    end
    
    local casterPed = GetPlayerPed(casterPlayer)
    if not DoesEntityExist(casterPed) then 
        return 
    end

    local spellLevel = ResolveSpellLevel('animarion', sourceServerId, level)
    local transformDuration = duration or CalculateTransformDuration(spellLevel)
    local handBone = GetPedBoneIndex(casterPed, Config.Projectile.handBone)
    local startCoords = GetWorldPositionOfEntityBone(casterPed, handBone)
    
    CreateAnimagusProjectile(startCoords, targetCoords, sourceServerId, targetEntity, spellLevel, transformDuration)
end)

RegisterNetEvent('th_animarion:applyTransform', function(animalModel, duration)
    local playerPed = cache.ped
    local playerCoords = GetEntityCoords(playerPed)
    local playerHeading = GetEntityHeading(playerPed)
    local transformDuration = duration or Config.Animagus.duration
    
    RequestNamedPtfxAsset(Config.Effects.transformEffect.asset)
    while not HasNamedPtfxAssetLoaded(Config.Effects.transformEffect.asset) do
        Wait(0)
    end
    
    UseParticleFxAsset(Config.Effects.transformEffect.asset)
    local transformFx = StartParticleFxLoopedAtCoord(
        Config.Effects.transformEffect.name,
        playerCoords.x, playerCoords.y, playerCoords.z,
        0.0, 0.0, 0.0,
        Config.Effects.transformEffect.scale,
        false, false, false, false
    )
    
    RequestNamedPtfxAsset(Config.Effects.smokeEffect.asset)
    while not HasNamedPtfxAssetLoaded(Config.Effects.smokeEffect.asset) do
        Wait(0)
    end
    
    UseParticleFxAsset(Config.Effects.smokeEffect.asset)
    local smokeFx = StartParticleFxLoopedAtCoord(
        Config.Effects.smokeEffect.name,
        playerCoords.x, playerCoords.y, playerCoords.z,
        0.0, 0.0, 0.0,
        Config.Effects.smokeEffect.scale,
        false, false, false, false
    )
    
    if smokeFx then
        SetParticleFxLoopedColour(smokeFx,
            Config.Effects.smokeEffect.color.r,
            Config.Effects.smokeEffect.color.g,
            Config.Effects.smokeEffect.color.b,
            false
        )
    end
    
    Wait(500)
    
    lib.requestModel(animalModel, 5000)
    SetPlayerModel(PlayerId(), GetHashKey(animalModel))
    SetModelAsNoLongerNeeded(GetHashKey(animalModel))
    
    SetEntityCoords(playerPed, playerCoords.x, playerCoords.y, playerCoords.z, false, false, false, false)
    SetEntityHeading(playerPed, playerHeading)
    
    Wait(1000)
    
    if transformFx then
        StopParticleFxLooped(transformFx, 0)
        RemoveParticleFx(transformFx, false)
    end
    if smokeFx then
        StopParticleFxLooped(smokeFx, 0)
        RemoveParticleFx(smokeFx, false)
    end
    RemoveNamedPtfxAsset(Config.Effects.transformEffect.asset)
    RemoveNamedPtfxAsset(Config.Effects.smokeEffect.asset)
    
    SetTimeout(transformDuration, function()
        TriggerServerEvent('th_animarion:revertTransform')
    end)
end)

RegisterNetEvent('th_animarion:revertToHuman', function()
    local playerPed <const> = cache.ped
    local currentCoords = GetEntityCoords(playerPed)
    local currentHeading = GetEntityHeading(playerPed)
    
    RequestNamedPtfxAsset(Config.Effects.transformEffect.asset)
    while not HasNamedPtfxAssetLoaded(Config.Effects.transformEffect.asset) do
        Wait(0)
    end
    
    UseParticleFxAsset(Config.Effects.transformEffect.asset)
    local transformFx = StartParticleFxLoopedAtCoord(
        Config.Effects.transformEffect.name,
        currentCoords.x, currentCoords.y, currentCoords.z,
        0.0, 0.0, 0.0,
        Config.Effects.transformEffect.scale,
        false, false, false, false
    )
    
    Wait(500)
    
    TriggerServerEvent('rcore_clothing:reloadSkin')  
    SetEntityCoords(playerPed, currentCoords.x, currentCoords.y, currentCoords.z, false, false, false, false)
    SetEntityHeading(playerPed, currentHeading)
    
    Wait(1000)
    
    if transformFx then
        StopParticleFxLooped(transformFx, 0)
        RemoveParticleFx(transformFx, false)
    end
    RemoveNamedPtfxAsset(Config.Effects.transformEffect.asset)
end)

RegisterNetEvent('th_animarion:transformPed', function(pedEntity, animalModel, duration)
    if not DoesEntityExist(pedEntity) or not IsEntityAPed(pedEntity) then
        return
    end

    local transformDuration = duration or CalculateTransformDuration(0)
    local pedCoords = GetEntityCoords(pedEntity)
    local pedHeading = GetEntityHeading(pedEntity)
    
    RequestNamedPtfxAsset(Config.Effects.transformEffect.asset)
    while not HasNamedPtfxAssetLoaded(Config.Effects.transformEffect.asset) do
        Wait(0)
    end
    
    UseParticleFxAsset(Config.Effects.transformEffect.asset)
    local transformFx = StartParticleFxLoopedAtCoord(
        Config.Effects.transformEffect.name,
        pedCoords.x, pedCoords.y, pedCoords.z,
        0.0, 0.0, 0.0,
        Config.Effects.transformEffect.scale,
        false, false, false, false
    )
    
    RequestNamedPtfxAsset(Config.Effects.smokeEffect.asset)
    while not HasNamedPtfxAssetLoaded(Config.Effects.smokeEffect.asset) do
        Wait(0)
    end
    
    UseParticleFxAsset(Config.Effects.smokeEffect.asset)
    local smokeFx = StartParticleFxLoopedAtCoord(
        Config.Effects.smokeEffect.name,
        pedCoords.x, pedCoords.y, pedCoords.z,
        0.0, 0.0, 0.0,
        Config.Effects.smokeEffect.scale,
        false, false, false, false
    )
    
    if smokeFx then
        SetParticleFxLoopedColour(smokeFx,
            Config.Effects.smokeEffect.color.r,
            Config.Effects.smokeEffect.color.g,
            Config.Effects.smokeEffect.color.b,
            false
        )
    end
    
    Wait(500)
    
    DeleteEntity(pedEntity)
    
    lib.requestModel(animalModel, 5000)
    local animalPed = CreatePed(4, GetHashKey(animalModel), pedCoords.x, pedCoords.y, pedCoords.z, pedHeading, true, false)
    SetEntityAsMissionEntity(animalPed, true, true)
    SetPedAsNoLongerNeeded(animalPed)
    SetModelAsNoLongerNeeded(GetHashKey(animalModel))
    SetPedFleeAttributes(animalPed, 0, 0)
    TaskWanderStandard(animalPed, 10.0, 10)
    
    NetworkRegisterEntityAsNetworked(animalPed)
    while not NetworkGetEntityIsNetworked(animalPed) do
        NetworkRegisterEntityAsNetworked(animalPed)
        Wait(1)
    end

    Wait(1000)
    
    if transformFx then
        StopParticleFxLooped(transformFx, 0)
        RemoveParticleFx(transformFx, false)
    end
    if smokeFx then
        StopParticleFxLooped(smokeFx, 0)
        RemoveParticleFx(smokeFx, false)
    end
    RemoveNamedPtfxAsset(Config.Effects.transformEffect.asset)
    RemoveNamedPtfxAsset(Config.Effects.smokeEffect.asset)
    
    SetTimeout(transformDuration, function()
        if DoesEntityExist(animalPed) then
            DeleteEntity(animalPed)
        end
    end)
end)

AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    
    for _, data in pairs(animagusRayProps) do
        if type(data) == "table" and DoesEntityExist(data.prop) then
            if data.trailFx then
                StopParticleFxLooped(data.trailFx, 0)
                RemoveParticleFx(data.trailFx, false)
            end
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
    
    animagusRayProps = {}
    wandParticles = {}
end)
