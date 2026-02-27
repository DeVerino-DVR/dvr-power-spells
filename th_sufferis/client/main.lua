---@diagnostic disable: undefined-global, trailing-space, unused-local, param-type-mismatch, missing-parameter, deprecated
local ragdollProjectiles = {}
local wandParticles = {}
local allParticles = {}
local isRagdolled = false
local RequestNamedPtfxAsset = RequestNamedPtfxAsset
local HasNamedPtfxAssetLoaded = HasNamedPtfxAssetLoaded
local UseParticleFxAssetNextCall = UseParticleFxAssetNextCall
local StartParticleFxLoopedOnEntity = StartParticleFxLoopedOnEntity
local StartNetworkedParticleFxLoopedOnEntity = StartNetworkedParticleFxLoopedOnEntity
local StartParticleFxLoopedAtCoord = StartParticleFxLoopedAtCoord
local StopParticleFxLooped = StopParticleFxLooped
local RemoveParticleFx = RemoveParticleFx
local RemoveNamedPtfxAsset = RemoveNamedPtfxAsset
local DeleteObject = DeleteObject
local DeleteEntity = DeleteEntity
local DoesEntityExist = DoesEntityExist
local GetGameTimer = GetGameTimer
local GetEntityCoords = GetEntityCoords
local SetEntityCoords = SetEntityCoords
local SetEntityRotation = SetEntityRotation
local SetEntityCollision = SetEntityCollision
local SetEntityAsMissionEntity = SetEntityAsMissionEntity
local SetEntityCompletelyDisableCollision = SetEntityCompletelyDisableCollision
local SetEntityVisible = SetEntityVisible
local GetPlayerFromServerId = GetPlayerFromServerId
local GetPlayerPed = GetPlayerPed
local CreateObject = CreateObject
local SetPedToRagdoll = SetPedToRagdoll
local SetPedCanRagdoll = SetPedCanRagdoll
local IsPedRagdoll = IsPedRagdoll
local ShakeGameplayCam = ShakeGameplayCam
local GetHashKey = GetHashKey

local function SpawnEntityWithConfig(model, coords, offsetZ, duration)
    local modelHash = GetHashKey(model)
    lib.requestModel(modelHash, 5000)
    local obj = CreateObject(modelHash, coords.x, coords.y, coords.z + offsetZ, true, true, false)

    if DoesEntityExist(obj) then
        SetEntityCollision(obj, false, false)
        SetEntityAsMissionEntity(obj, true, true)
        SetEntityCompletelyDisableCollision(obj, true, false)
        SetEntityRotation(obj, 0.0, 0.0, 0.0, 2, true)
        SetEntityVisible(obj, true, false)
        FreezeEntityPosition(obj, true)

        SetTimeout(duration, function()
            if DoesEntityExist(obj) then
                SetEntityVisible(obj, false, false)
                DeleteEntity(obj)
                DeleteObject(obj)
            end
        end)
    end

    return obj
end

local function SpawnLightningAtCoord(coords)
    local props = Config.Lightning and Config.Lightning.props or {}
    local duration = 12500

    if props.main then SpawnEntityWithConfig(props.main, coords, -0.7, duration) end
    if props.sub then SpawnEntityWithConfig(props.sub, coords, -0.3, duration) end
    if props.boltSmall then SpawnEntityWithConfig(props.boltSmall, coords, -1.1, duration) end
end

local function AddParticleFx(asset, name, coords, offsetZ, scale, handles)
    UseParticleFxAssetNextCall(asset)
    local fx = StartParticleFxLoopedAtCoord(name, coords.x, coords.y, coords.z + offsetZ, 0.0, 0.0, 0.0, scale, false, false, false, false)
    if fx then
        handles[#handles + 1] = fx
        allParticles[fx] = { createdTime = GetGameTimer(), type = 'impact' }
    end
end

local function SpawnImpactParticles(coords)
    RequestNamedPtfxAsset('scr_carrier_heist')
    RequestNamedPtfxAsset('core')
    while not HasNamedPtfxAssetLoaded('scr_carrier_heist') or not HasNamedPtfxAssetLoaded('core') do
        Wait(0)
    end

    local handles = {}
    local scales = {3.5, 3.0, 2.5, 2.0, 2.5, 3.0}
    local offsets = {-0.3, -0.2, -0.1, 0.0, 0.1, 0.2}

    for i = 1, #scales do
        AddParticleFx('scr_carrier_heist', 'scr_heist_carrier_elec_fire', coords, offsets[i], scales[i], handles)
        AddParticleFx('core', 'ent_ray_prologue_elec_crackle', coords, offsets[i], scales[i], handles)
    end

    SetTimeout(12500, function()
        for _, fx in ipairs(handles) do
            StopParticleFxLooped(fx, false)
            RemoveParticleFx(fx, false)
            allParticles[fx] = nil
        end
        RemoveNamedPtfxAsset('scr_carrier_heist')
        RemoveNamedPtfxAsset('core')
    end)
end

local function ApplyBloodScreenEffect(duration)
    local playerPed = cache.ped
    local startTime = GetGameTimer()
    local endTime = startTime + duration
    local fadeInTime = Config.BloodEffect.fadeInTime or 500
    local fadeOutTime = Config.BloodEffect.fadeOutTime or 2000
    local maxIntensity = Config.BloodEffect.intensity or 0.8

    RequestNamedPtfxAsset('scr_solomon3')
    while not HasNamedPtfxAssetLoaded('scr_solomon3') do
        Wait(0)
    end

    CreateThread(function()
        UseParticleFxAssetNextCall('scr_solomon3')
        local bloodEffectHandle = StartParticleFxLoopedOnEntity('scr_solomon3_blood_impact', playerPed, 0.0, 0.0, 0.6, 0.0, 0.0, 0.0, 2.0, false, false, false)

        while GetGameTimer() < endTime do
            local currentTime = GetGameTimer()
            local elapsed = currentTime - startTime
            local remaining = endTime - currentTime
            local alpha = maxIntensity

            if elapsed < fadeInTime then
                alpha = (elapsed / fadeInTime) * maxIntensity
            elseif remaining < fadeOutTime then
                alpha = (remaining / fadeOutTime) * maxIntensity
            end

            if bloodEffectHandle then
                SetParticleFxLoopedAlpha(bloodEffectHandle, alpha * 255)
            end
            Wait(0)
        end

        if bloodEffectHandle then
            StopParticleFxLooped(bloodEffectHandle, false)
            RemoveParticleFx(bloodEffectHandle, false)
        end
        RemoveNamedPtfxAsset('scr_solomon3')
    end)

    CreateThread(function()
        while GetGameTimer() < endTime do
            AnimpostfxPlay('DeathFailMPDark', 0, true)
            Wait(0)
        end
        AnimpostfxStop('DeathFailMPDark')
    end)
end

local function StopWandTrail(playerPed)
    local handles = wandParticles[playerPed]
    if not handles then return end

    if handles.beam then
        StopParticleFxLooped(handles.beam, false)
        RemoveParticleFx(handles.beam, false)
        allParticles[handles.beam] = nil
    end

    if handles.aura then
        StopParticleFxLooped(handles.aura, false)
        RemoveParticleFx(handles.aura, false)
        allParticles[handles.aura] = nil
    end

    wandParticles[playerPed] = nil
    RemoveNamedPtfxAsset('core')
end

local function RotationToDirection(rotation)
    local rad = math.pi / 180
    local adjustedRotation = {
        x = rad * rotation.x,
        y = rad * rotation.y,
        z = rad * rotation.z
    }
    return {
        x = -math.sin(adjustedRotation.z) * math.abs(math.cos(adjustedRotation.x)),
        y = math.cos(adjustedRotation.z) * math.abs(math.cos(adjustedRotation.x)),
        z = math.sin(adjustedRotation.x)
    }
end

local function CreateParticleOnEntity(asset, name, entity, x, y, z, scale, isNetworked)
    local handle
    if isNetworked then
        handle = StartNetworkedParticleFxLoopedOnEntity(name, entity, x, y, z, 0.0, 0.0, 0.0, scale, false, false, false)
    else
        handle = StartParticleFxLoopedOnEntity(name, entity, x, y, z, 0.0, 0.0, 0.0, scale, false, false, false)
    end
    return handle
end

local function CreateWandParticles(playerPed, isNetworked)
    local weapon = GetCurrentPedWeaponEntityIndex(playerPed)
    if not weapon or not DoesEntityExist(weapon) then return end

    RequestNamedPtfxAsset('core')
    while not HasNamedPtfxAssetLoaded('core') do
        Wait(0)
    end

    UseParticleFxAsset('core')

    local beamHandle = CreateParticleOnEntity('core', 'veh_light_clear', weapon, 0.95, 0.0, 0.1, 0.55, isNetworked)
    if beamHandle then
        SetParticleFxLoopedColour(beamHandle, 0.8, 0.0, 0.0, false)
        SetParticleFxLoopedAlpha(beamHandle, 220)
    end

    local auraHandle = CreateParticleOnEntity('core', 'ent_amb_elec_crackle_sp', weapon, 0.6, 0.0, 0.15, 0.7, isNetworked)
    if auraHandle then
        SetParticleFxLoopedColour(auraHandle, 0.8, 0.0, 0.0, false)
        SetParticleFxLoopedAlpha(auraHandle, 180)
    end

    wandParticles[playerPed] = { beam = beamHandle, aura = auraHandle }
    return beamHandle
end

local function AttachProjectileTrail(rayProp)
    if not rayProp or not DoesEntityExist(rayProp) then return end

    RequestNamedPtfxAsset('core')
    while not HasNamedPtfxAssetLoaded('core') do
        Wait(0)
    end

    UseParticleFxAssetNextCall('core')
    local trailHandle = StartParticleFxLoopedOnEntity('veh_light_red_trail', rayProp, 0.35, 0.0, 0.1, 0.0, 0.0, 0.0, 0.55, false, false, false)

    if trailHandle then
        allParticles[trailHandle] = { createdTime = GetGameTimer(), type = 'projectileTrail' }
    end

    return trailHandle
end

local function CleanupProjectile(propId)
    local data = ragdollProjectiles[propId]
    if not data then return end

    if data.trailHandle then
        StopParticleFxLooped(data.trailHandle, false)
        RemoveParticleFx(data.trailHandle, false)
        allParticles[data.trailHandle] = nil
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
    local propModel = GetHashKey("nib_accio_ray")
    lib.requestModel(propModel, 5000)

    local rayProp = CreateObject(propModel, startCoords.x, startCoords.y, startCoords.z, false, false, false)
    SetEntityCollision(rayProp, false, false)
    SetEntityAsMissionEntity(rayProp, true, true)
    SetEntityCompletelyDisableCollision(rayProp, true, false)
    SetEntityLodDist(rayProp, 2000)

    if SetEntityDistanceCullingRadius then
        SetEntityDistanceCullingRadius(rayProp, 2000.0)
    end

    local direction = vector3(
        targetCoords.x - startCoords.x,
        targetCoords.y - startCoords.y,
        targetCoords.z - startCoords.z
    )
    local distance = #direction
    if distance <= 0.001 then distance = 0.001 end
    direction = direction / distance

    local heading = math.deg(math.atan2(direction.y, direction.x)) + 90.0
    local pitch = -math.deg(math.asin(direction.z))

    SetEntityCoords(rayProp, startCoords.x, startCoords.y, startCoords.z, false, false, false, false)
    SetEntityRotation(rayProp, pitch, 0.0, heading, 2, true)

    StopWandTrail(casterPed)
    local trailHandle = AttachProjectileTrail(rayProp)

    local duration = (distance / (Config.Projectile.speed or 30.0)) * 1000.0
    local startTime = GetGameTimer()

    ragdollProjectiles[rayProp] = {
        prop = rayProp,
        startCoords = startCoords,
        direction = direction,
        distance = distance,
        startTime = startTime,
        endTime = startTime + duration,
        heading = heading,
        pitch = pitch,
        trailHandle = trailHandle,
        targetId = targetId or 0,
        level = level or 0
    }
end

-- Nettoyage des particules anciennes
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

-- Animation des projectiles
CreateThread(function()
    while true do
        Wait(1)
        local currentTime = GetGameTimer()

        for propId, data in pairs(ragdollProjectiles) do
            if type(data) == "table" and DoesEntityExist(data.prop) then
                if currentTime < data.endTime then
                    local progress = math.min((currentTime - data.startTime) / (data.endTime - data.startTime), 1.0)
                    local newPos = vector3(
                        data.startCoords.x + (data.direction.x * data.distance * progress),
                        data.startCoords.y + (data.direction.y * data.distance * progress),
                        data.startCoords.z + (data.direction.z * data.distance * progress)
                    )

                    SetEntityCoords(data.prop, newPos.x, newPos.y, newPos.z, false, false, false, false)
                    SetEntityRotation(data.prop, data.pitch, 0.0, data.heading, 2, true)
                else
                    local propCoords = GetEntityCoords(data.prop)
                    SpawnImpactParticles(propCoords)

                    local playerCoords = GetEntityCoords(cache.ped)
                    local distance = #(playerCoords - propCoords)
                    if distance < 50.0 then
                        ShakeGameplayCam('GAMEPLAY_EXPLOSION_SHAKE', 0.45 * (1.0 - (distance / 50.0)))
                    end

                    SetTimeout(2000, function() SpawnImpactParticles(propCoords) end)

                    if data.targetId and data.targetId > 0 then
                        TriggerServerEvent('th_sufferis:ragdollTarget', data.targetId, data.level or 0)
                    end

                    SetEntityVisible(data.prop, false, false)
                    SetEntityCoords(data.prop, 0.0, 0.0, -5000.0, false, false, false, false)
                    Wait(50)
                    DeleteEntity(data.prop)
                    DeleteObject(data.prop)
                    CleanupProjectile(propId)
                end
            end
        end
    end
end)

local function GetRagdollDuration(level)
    local base = Config.Ragdoll.baseDuration or 10000
    local perLevel = Config.Ragdoll.perLevel or 0
    local max = Config.Ragdoll.maxDuration or 10000
    return math.min(base + (perLevel * (tonumber(level) or 0)), max)
end

-- Maintien du ragdoll
CreateThread(function()
    while true do
        if isRagdolled then
            local playerPed = cache.ped
            if not IsPedRagdoll(playerPed) then
                SetPedToRagdoll(playerPed, 1000, 1000, 0, false, false, false)
            end
            DisableControlAction(0, 32, true)
            DisableControlAction(0, 33, true)
            DisableControlAction(0, 34, true)
            DisableControlAction(0, 35, true)
            DisableControlAction(0, 22, true)
            Wait(0)
        else
            Wait(100)
        end
    end
end)

RegisterNetEvent('th_sufferis:applyRagdoll', function(level)
    local duration = GetRagdollDuration(level)
    local playerPed = cache.ped
    local pedCoords = GetEntityCoords(playerPed)

    isRagdolled = true
    SpawnImpactParticles(pedCoords)

    local shakeCfg = Config.Lightning and Config.Lightning.shake
    if shakeCfg then
        ShakeGameplayCam('GAMEPLAY_EXPLOSION_SHAKE', (shakeCfg.intensity or 0.6) * 0.75)
        SetTimeout(2000, function() SpawnImpactParticles(GetEntityCoords(playerPed)) end)
    end

    SetPedCanRagdoll(playerPed, true)
    SetPedToRagdoll(playerPed, duration, duration, 0, false, false, false)
    ApplyBloodScreenEffect(duration)

    CreateThread(function()
        local endTime = GetGameTimer() + duration
        while GetGameTimer() < endTime do
            if not IsPedRagdoll(playerPed) then
                local remaining = endTime - GetGameTimer()
                if remaining > 0 then
                    SetPedToRagdoll(playerPed, remaining, remaining, 0, false, false, false)
                end
            end
            Wait(100)
        end
        isRagdolled = false
    end)
end)

RegisterNetEvent('th_sufferis:prepareProjectile', function(targetId, level)
    local casterPed = cache.ped
    CreateWandParticles(casterPed, true)

    CreateThread(function()
        local speedMult = (Config.Animation and Config.Animation.speedMultiplier) or 1.0
        local delay = (Config.Animation and Config.Animation.projectileDelay) or 2200
        Wait(math.floor(delay / math.max(speedMult, 0.1)))
        local handBone = GetPedBoneIndex(casterPed, 28422)
        local startCoords = GetWorldPositionOfEntityBone(casterPed, handBone)
        local camCoords = GetGameplayCamCoord()
        local camRot = GetGameplayCamRot(2)
        local direction = RotationToDirection(camRot)

        local hit, entityHit, coords = lib.raycast.cam(1 | 2 | 4 | 8 | 16, 4, Config.Projectile.maxDistance or 1000.0)
        local finalTargetCoords = coords and (coords.x ~= 0.0 or coords.y ~= 0.0 or coords.z ~= 0.0) and coords or vector3(
            camCoords.x + direction.x * (Config.Projectile.maxDistance or 1000.0),
            camCoords.y + direction.y * (Config.Projectile.maxDistance or 1000.0),
            camCoords.z + direction.z * (Config.Projectile.maxDistance or 1000.0)
        )

        TriggerServerEvent('th_sufferis:broadcastProjectile', finalTargetCoords, targetId or 0, level or 0)
        Wait(800)
        StopWandTrail(casterPed)
    end)
end)

RegisterNetEvent('th_sufferis:otherPlayerCasting', function(sourceServerId)
    if sourceServerId == GetPlayerServerId(PlayerId()) then return end

    local casterPlayer = GetPlayerFromServerId(sourceServerId)
    if casterPlayer == -1 then return end

    local casterPed = GetPlayerPed(casterPlayer)
    if not DoesEntityExist(casterPed) then return end

    CreateWandParticles(casterPed, true)
    SetTimeout(3000, function() StopWandTrail(casterPed) end)
end)

RegisterNetEvent('th_sufferis:spawnProjectile', function(sourceServerId, targetCoords, targetId, level)
    local casterPlayer = GetPlayerFromServerId(sourceServerId)
    if casterPlayer == -1 then return end

    local casterPed = GetPlayerPed(casterPlayer)
    if not DoesEntityExist(casterPed) or not targetCoords then return end

    local handBone = GetPedBoneIndex(casterPed, 28422)
    local startCoords = GetWorldPositionOfEntityBone(casterPed, handBone)
    CreateRagdollProjectile(startCoords, targetCoords, sourceServerId, casterPed, targetId or 0, level or 0)
end)

AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end

    for propId, data in pairs(ragdollProjectiles) do
        if type(data) == "table" and DoesEntityExist(data.prop) then
            DeleteEntity(data.prop)
            DeleteObject(data.prop)
        end
    end

    for ped, handle in pairs(wandParticles) do
        if handle.beam then RemoveParticleFx(handle.beam, false) end
        if handle.aura then RemoveParticleFx(handle.aura, false) end
    end

    for particleHandle, _ in pairs(allParticles) do
        StopParticleFxLooped(particleHandle, false)
        RemoveParticleFx(particleHandle, false)
    end

    RemoveNamedPtfxAsset('core')
    RemoveNamedPtfxAsset('ns_ptfx')
    RemoveNamedPtfxAsset('scr_solomon3')
    RemoveNamedPtfxAsset('scr_carrier_heist')

    ragdollProjectiles = {}
    wandParticles = {}
    allParticles = {}
    isRagdolled = false
end)
