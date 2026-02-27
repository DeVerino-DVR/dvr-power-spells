---@diagnostic disable: undefined-global, trailing-space, unused-local, param-type-mismatch, missing-parameter, deprecated
local bleedState = { active = false }
local projectiles = {}
local wandParticles = {}
local bleedThread = nil
local ragdollThread = nil
local otherPlayersBleedFx = {}

local RequestNamedPtfxAsset = RequestNamedPtfxAsset
local HasNamedPtfxAssetLoaded = HasNamedPtfxAssetLoaded
local UseParticleFxAsset = UseParticleFxAsset
local UseParticleFxAssetNextCall = UseParticleFxAssetNextCall
local StartNetworkedParticleFxLoopedOnEntity = StartNetworkedParticleFxLoopedOnEntity
local StartParticleFxLoopedOnEntity = StartParticleFxLoopedOnEntity
local StartParticleFxNonLoopedOnEntity = StartParticleFxNonLoopedOnEntity
local StartNetworkedParticleFxNonLoopedOnEntity = StartNetworkedParticleFxNonLoopedOnEntity
local StartNetworkedParticleFxNonLoopedOnEntityBone = StartNetworkedParticleFxNonLoopedOnEntityBone
local StartNetworkedParticleFxNonLoopedAtCoord = StartNetworkedParticleFxNonLoopedAtCoord
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
local ApplyDamageToPed = ApplyDamageToPed
local SetPedToRagdoll = SetPedToRagdoll
local IsPedRagdoll = IsPedRagdoll

local UPPER_BODY_BONES <const> = {
    31086, -- SKEL_HEAD
    39317, -- SKEL_NECK_1
    24818, -- SKEL_SPINE3
    24817, -- SKEL_SPINE2
    24816, -- SKEL_SPINE1
    64729, -- SKEL_L_CLAVICLE
    10706, -- SKEL_R_CLAVICLE
    45509, -- SKEL_L_UPPERARM
    61163  -- SKEL_R_UPPERARM
}

local function LoadPtfx(asset)
    if not asset then
        return false
    end

    RequestNamedPtfxAsset(asset)
    while not HasNamedPtfxAssetLoaded(asset) do
        Wait(0)
    end
    return true
end

local function PlayFxOnUpperBodyBones(entity, effectName, scale, asset)
    if not entity or not DoesEntityExist(entity) then
        return
    end

    local fxAsset = asset or 'core'
    if not LoadPtfx(fxAsset) then
        return
    end
    UseParticleFxAsset(fxAsset)

    for _, boneId in ipairs(UPPER_BODY_BONES) do
        local boneIndex = GetPedBoneIndex(entity, boneId)
        if boneIndex and boneIndex ~= -1 then
            UseParticleFxAssetNextCall(fxAsset)
            StartNetworkedParticleFxNonLoopedOnEntityBone(
                effectName,
                entity,
                0.0, 0.0, 0.02,
                0.0, 0.0, 0.0,
                boneIndex,
                scale or 1.0,
                true, true, true
            )
        end
    end
end

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
        wandParticles[playerPed] = nil
    end
end

local function RemoveWandParticles(playerPed)
    StopWandTrail(playerPed)
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

local function GetAnimationTimings()
    local anim = Config.Animation or {}
    local speedMult = anim.speedMultiplier or 1.0
    if speedMult <= 0.0 then
        speedMult = 1.0
    end

    local propsDelay = anim.propsDelay or 2200
    local duration = anim.duration or 3000

    local scaledProps = math.floor(propsDelay / speedMult)
    local scaledDuration = math.max(scaledProps, math.floor(duration / speedMult))
    local cleanupDelay = math.max(0, scaledDuration - scaledProps)

    return scaledProps, cleanupDelay, scaledDuration
end

local function CreateWandParticles(playerPed, isNetworked)
    local weapon = GetCurrentPedWeaponEntityIndex and GetCurrentPedWeaponEntityIndex(playerPed)
    if not weapon or not DoesEntityExist(weapon) then
        return nil
    end
    if not LoadPtfx('core') then
        return nil
    end
    UseParticleFxAsset('core')
    local handle
    if isNetworked then
        handle = StartNetworkedParticleFxLoopedOnEntity('veh_light_clear', weapon, 0.95, 0.0, 0.1, 0.0, 0.0, 0.0, 0.55, false, false, false)
    else
        handle = StartParticleFxLoopedOnEntity('veh_light_clear', weapon, 0.95, 0.0, 0.1, 0.0, 0.0, 0.0, 0.55, false, false, false)
    end
    SetParticleFxLoopedColour(handle, 0.6, 0.0, 0.0, false)
    SetParticleFxLoopedAlpha(handle, 220)
    wandParticles[playerPed] = handle
    return handle
end

local function AttachProjectileTrail(rayProp, casterPed)
    if not rayProp or not DoesEntityExist(rayProp) then
        return
    end
    if not LoadPtfx('core') then
        return
    end
    UseParticleFxAsset('core')

    local targetPed = (casterPed and DoesEntityExist(casterPed)) and casterPed or nil
    if targetPed then
        PlayFxOnUpperBodyBones(targetPed, 'trail_splash_blood', 0.6, 'core')
    end

    -- Fallback on the projectile entity (non-bone) to keep a short trail at launch.
    UseParticleFxAssetNextCall('core')
    StartNetworkedParticleFxNonLoopedOnEntity('trail_splash_blood', rayProp, 0.0, 0.0, 0.1, 0.0, 0.0, 0.0)
end

local function CleanupProjectile(propId)
    local data = projectiles[propId]
    if not data then return end
    if DoesEntityExist(propId) then
        SetEntityVisible(propId, false, false)
        SetEntityCoords(propId, 0.0, 0.0, -5000.0, false, false, false, false)
        DeleteEntity(propId)
        DeleteObject(propId)
    end
    projectiles[propId] = nil
end

local function CreateSanguirisProjectile(startCoords, targetCoords, sourceServerId, casterPed, targetId, level)
    local propModel = GetHashKey("nib_accio_ray")
    lib.requestModel(propModel, 5000)
    local rayProp = CreateObject(propModel, startCoords.x, startCoords.y, startCoords.z, false, false, false)
    SetEntityCollision(rayProp, false, false)
    SetEntityAsMissionEntity(rayProp, true, true)
    SetEntityCompletelyDisableCollision(rayProp, true, false)

    local direction = vector3(targetCoords.x - startCoords.x, targetCoords.y - startCoords.y, targetCoords.z - startCoords.z)
    local distance = #direction
    if distance <= 0.001 then distance = 0.001 end
    direction = direction / distance

    local heading = math.deg(math.atan2(direction.y, direction.x)) + 90.0
    local pitch = -math.deg(math.asin(direction.z))
    local roll = 0.0

    SetEntityCoords(rayProp, startCoords.x, startCoords.y, startCoords.z, false, false, false, false)
    SetEntityRotation(rayProp, pitch, roll, heading, 2, true)

    AttachProjectileTrail(rayProp, casterPed)

    local duration = (distance / (Config.Projectile.speed or 30.0)) * 1000.0
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
        sourceServerId = sourceServerId,
        targetId = targetId or 0,
        level = level or 0
    }
end

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
                end
                if currentTime >= data.endTime then
                    if DoesEntityExist(data.prop) then
                        local propCoords = GetEntityCoords(data.prop)
                        TriggerServerEvent('th_sanguiris:applyBleed', data.targetId or 0, data.level or 0)
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

local function PlayFxAtPed(ped, fx)
    if not ped or not DoesEntityExist(ped) or not fx then return end
    if not fx.asset or not fx.name then return end
    RequestNamedPtfxAsset(fx.asset)
    while not HasNamedPtfxAssetLoaded(fx.asset) do Wait(0) end
    UseParticleFxAssetNextCall(fx.asset)
    StartParticleFxNonLoopedOnEntity(fx.name, ped, 0.0, 0.0, 0.05, 0.0, 0.0, 0.0, fx.scale or 1.0, false, false, false)
end

local function PlayGroundFxAtPed(ped, fx)
    if not ped or not DoesEntityExist(ped) or not fx then return end
    if not fx.asset or not fx.name then return end
    local coords = GetEntityCoords(ped)
    RequestNamedPtfxAsset(fx.asset)
    while not HasNamedPtfxAssetLoaded(fx.asset) do Wait(0) end
    UseParticleFxAsset(fx.asset)
    local handle = StartParticleFxLoopedOnEntity(
        fx.name, ped,
        0.0, 0.0, (fx.offset or -0.9),
        0.0, 0.0, 0.0,
        fx.scale or 1.0,
        false, false, false
    )
    if fx.lifetime then
        SetTimeout(fx.lifetime, function()
            if handle then
                StopParticleFxLooped(handle, false)
                RemoveParticleFx(handle, false)
            end
        end)
    end
end

RegisterNetEvent('th_sanguiris:startBleed', function(tickDamage, tickInterval, maxDuration, fx)
    if HasProtheaShield() then return end
    if bleedState.active then return end

    bleedState.active = true
    local startedAt = GetGameTimer()
    local untilAt = startedAt + (maxDuration or 20000)

    PlayFxAtPed(cache.ped, fx and fx.impact)
    PlayGroundFxAtPed(cache.ped, fx and fx.ground)

    if fx and fx.loop then
        if bleedState.loopThread then
            bleedState.loopFxActive = false
            Wait(0)
        end

        bleedState.loopFxActive = true
        bleedState.loopThread = CreateThread(function()
            while bleedState.active and bleedState.loopFxActive do
                PlayUpperBodyFx(cache.ped, fx.loop)
                Wait(200)
            end
            bleedState.loopThread = nil
        end)
    end

    bleedThread = CreateThread(function()
        while bleedState.active do
            local now = GetGameTimer()
            if now >= untilAt then
                break
            end

            ApplyDamageToPed(cache.ped, tickDamage or 5, false)

            if fx and fx.ground then
                PlayGroundFxAtPed(cache.ped, fx.ground)
            end

            if fx and fx.impact then
                PlayFxAtPed(cache.ped, fx.impact)
            end
            Wait(tickInterval or 2000)
        end

        bleedState.loopFxActive = false

        bleedState.active = false
        if ragdollThread then
            ragdollThread = nil
        end
    end)

    lib.notify({
        title = 'Sanguiris',
        description = 'Vous saignez abondamment !',
        type = 'error'
    })
end)

RegisterNetEvent('th_sanguiris:ragdoll', function(duration)
    if HasProtheaShield() then return end
    local t = duration or 20000
    
    ragdollThread = CreateThread(function()
        local startTime = GetGameTimer()
        local endTime = startTime + t
        
        while GetGameTimer() < endTime and bleedState.active do
            if not IsPedRagdoll(cache.ped) then
                SetPedToRagdoll(cache.ped, 2000, 2000, 0, false, false, false)
            end
            Wait(100)
        end
        ragdollThread = nil
    end)
    
    SetPedToRagdoll(cache.ped, 2000, 2000, 0, false, false, false)
end)

RegisterNetEvent('th_sanguiris:stopBleed', function()
    bleedState.loopFxActive = false
    bleedState.active = false
    if bleedState.loopThread then
        bleedState.loopThread = nil
    end
    if ragdollThread then
        ragdollThread = nil
    end
end)

RegisterNetEvent('th_sanguiris:bleedImpactFx', function(victimId, fx)
    local me = GetPlayerServerId(PlayerId())
    if victimId == me then return end
    local player = GetPlayerFromServerId(victimId)
    if player == -1 then return end
    local ped = GetPlayerPed(player)
    if not DoesEntityExist(ped) then return end
    PlayFxAtPed(ped, fx and fx.impact)
    PlayGroundFxAtPed(ped, fx and fx.ground)
end)

RegisterNetEvent('th_sanguiris:bleedRecurrentFx', function(victimId, fx)
    local me = GetPlayerServerId(PlayerId())
    if victimId == me then return end
    local player = GetPlayerFromServerId(victimId)
    if player == -1 then return end
    local ped = GetPlayerPed(player)
    if not DoesEntityExist(ped) then return end
    if fx and fx.ground then
        PlayGroundFxAtPed(ped, fx.ground)
    end
    if fx and fx.impact then
        PlayFxAtPed(ped, fx.impact)
    end
end)

RegisterNetEvent('th_sanguiris:stopBleedFx', function(victimId)
    if otherPlayersBleedFx[victimId] then
        for _, handle in pairs(otherPlayersBleedFx[victimId]) do
            if handle then
                StopParticleFxLooped(handle, false)
                RemoveParticleFx(handle, false)
            end
        end
        otherPlayersBleedFx[victimId] = nil
    end
end)

RegisterNetEvent('th_sanguiris:applyBleedClient', function(level)
    if HasProtheaShield() then return end
    TriggerServerEvent('th_sanguiris:applyBleed', GetPlayerServerId(PlayerId()), level or 0)
end)

RegisterNetEvent('th_sanguiris:prepareProjectile', function(targetId, level)
    local casterPed = cache.ped
    local propsDelay, cleanupDelay = GetAnimationTimings()
    CreateWandParticles(casterPed, true)
    CreateThread(function()
        Wait(propsDelay)
        local handBone = GetPedBoneIndex(casterPed, 28422)
        local startCoords = GetWorldPositionOfEntityBone(casterPed, handBone)
        local camCoords = GetGameplayCamCoord()
        local camRot = GetGameplayCamRot(2)
        local direction = RotationToDirection(camRot)
        local hit, entityHit, coords = lib.raycast.cam(1 | 2 | 4 | 8 | 16, 4, Config.Projectile.maxDistance or 900.0)
        local finalTargetCoords
        if coords and (coords.x ~= 0.0 or coords.y ~= 0.0 or coords.z ~= 0.0) then
            finalTargetCoords = coords
        else
            finalTargetCoords = vector3(
                camCoords.x + direction.x * (Config.Projectile.maxDistance or 900.0),
                camCoords.y + direction.y * (Config.Projectile.maxDistance or 900.0),
                camCoords.z + direction.z * (Config.Projectile.maxDistance or 900.0)
            )
        end
        TriggerServerEvent('th_sanguiris:broadcastProjectile', finalTargetCoords, targetId or 0, level or 0)
        Wait(cleanupDelay)
        RemoveWandParticles(casterPed)
    end)
end)

RegisterNetEvent('th_sanguiris:otherPlayerCasting', function(sourceServerId)
    local myServerId = GetPlayerServerId(PlayerId())
    if sourceServerId == myServerId then return end
    local casterPlayer = GetPlayerFromServerId(sourceServerId)
    if casterPlayer == -1 then return end
    local casterPed = GetPlayerPed(casterPlayer)
    if not DoesEntityExist(casterPed) then return end
    CreateWandParticles(casterPed, true)
    local _, _, animDuration = GetAnimationTimings()
    SetTimeout(animDuration, function()
        RemoveWandParticles(casterPed)
    end)
end)

RegisterNetEvent('th_sanguiris:spawnProjectile', function(sourceServerId, targetCoords, targetId, level)
    local casterPlayer = GetPlayerFromServerId(sourceServerId)
    if casterPlayer == -1 then return end
    local casterPed = GetPlayerPed(casterPlayer)
    if not DoesEntityExist(casterPed) then return end
    if not targetCoords then return end
    local handBone = GetPedBoneIndex(casterPed, 28422)
    local startCoords = GetWorldPositionOfEntityBone(casterPed, handBone)
    CreateSanguirisProjectile(startCoords, targetCoords, sourceServerId, casterPed, targetId or 0, level or 0)
end)

AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    for propId, data in pairs(projectiles) do
        if type(data) == "table" and DoesEntityExist(data.prop) then
            DeleteEntity(data.prop)
            DeleteObject(data.prop)
        end
    end
    projectiles = {}
    for ped, handle in pairs(wandParticles) do
        RemoveParticleFx(handle, false)
    end
    wandParticles = {}
    RemoveNamedPtfxAsset('core')
end)
