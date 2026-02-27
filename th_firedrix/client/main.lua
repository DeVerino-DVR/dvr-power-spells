---@diagnostic disable: undefined-global, trailing-space, unused-local, deprecated, param-type-mismatch
local RequestNamedPtfxAsset = RequestNamedPtfxAsset
local HasNamedPtfxAssetLoaded = HasNamedPtfxAssetLoaded
local UseParticleFxAsset = UseParticleFxAsset
local StartNetworkedParticleFxLoopedOnEntity = StartNetworkedParticleFxLoopedOnEntity
local StartParticleFxLoopedOnEntity = StartParticleFxLoopedOnEntity
local StartParticleFxLoopedOnPedBone = StartParticleFxLoopedOnPedBone
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
local PlayerPedId = PlayerPedId
local StartScreenEffect = StartScreenEffect
local StopScreenEffect = StopScreenEffect
local GetCurrentPedWeaponEntityIndex = GetCurrentPedWeaponEntityIndex
local GetPlayerFromServerId = GetPlayerFromServerId
local GetPlayerPed = GetPlayerPed
local GetPlayerServerId = GetPlayerServerId
local PlayerId = PlayerId
local CreateObject = CreateObject
local GetHashKey = GetHashKey

local activeFires = {}
local playerFireHandle = nil
local playerFireEndTime = 0
local wandParticles = {}
local firedrixProjectiles = {}
local projectileFx = {}

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
    local animConfig = Config.Animation or {}
    local speedMult = animConfig.speedMultiplier or 1.0
    if speedMult <= 0.0 then
        speedMult = 1.0
    end

    local propsDelay = animConfig.propsDelay or 700
    local duration = animConfig.duration or 3000
    local scaledDelay = math.floor(propsDelay / speedMult)
    local scaledDuration = math.max(scaledDelay, math.floor(duration / speedMult))
    local cleanupDelay = math.max(0, scaledDuration - scaledDelay)

    return scaledDelay, cleanupDelay, scaledDuration
end

local function StopWandParticles(playerPed)
    local handles = wandParticles[playerPed]
    if not handles then return end

    if handles.beam then
        StopParticleFxLooped(handles.beam, false)
        RemoveParticleFx(handles.beam, false)
    end
    if handles.aura then
        StopParticleFxLooped(handles.aura, false)
        RemoveParticleFx(handles.aura, false)
    end
    wandParticles[playerPed] = nil
end

local function CreateWandParticles(playerPed, isNetworked)
    local weapon = GetCurrentPedWeaponEntityIndex(playerPed)
    if not weapon or not DoesEntityExist(weapon) then
        return nil
    end

    RequestNamedPtfxAsset('core')
    while not HasNamedPtfxAssetLoaded('core') do
        Wait(0)
    end
    UseParticleFxAsset('core')

    local wandCfg = Config.WandParticle or {}
    local ptfxName = wandCfg.name or 'ent_amb_torch_fire'
    local offset = wandCfg.offset or { x = 0.85, y = 0.0, z = 0.05 }
    local rot = wandCfg.rot or { x = 0.0, y = 0.0, z = 0.0 }
    local scale = wandCfg.scale or 0.4
    local color = wandCfg.color or { r = 1.0, g = 0.5, b = 0.0 }

    local beamHandle
    if isNetworked then
        beamHandle = StartNetworkedParticleFxLoopedOnEntity(ptfxName, weapon, offset.x, offset.y, offset.z, rot.x, rot.y, rot.z, scale, false, false, false)
    else
        beamHandle = StartParticleFxLoopedOnEntity(ptfxName, weapon, offset.x, offset.y, offset.z, rot.x, rot.y, rot.z, scale, false, false, false)
    end

    if beamHandle then
        SetParticleFxLoopedColour(beamHandle, color.r, color.g, color.b, false)
        SetParticleFxLoopedAlpha(beamHandle, wandCfg.alpha or 1.0)
    end

    local auraHandle
    local auraCfg = Config.WandAura
    if auraCfg then
        UseParticleFxAssetNextCall('core')
        if isNetworked then
            auraHandle = StartNetworkedParticleFxLoopedOnEntity(auraCfg.name or 'veh_light_red_trail', weapon, auraCfg.offset.x, auraCfg.offset.y, auraCfg.offset.z, 0.0, 0.0, 0.0, auraCfg.scale or 0.5, false, false, false)
        else
            auraHandle = StartParticleFxLoopedOnEntity(auraCfg.name or 'veh_light_red_trail', weapon, auraCfg.offset.x, auraCfg.offset.y, auraCfg.offset.z, 0.0, 0.0, 0.0, auraCfg.scale or 0.5, false, false, false)
        end
        if auraHandle then
            SetParticleFxLoopedColour(auraHandle, auraCfg.color.r, auraCfg.color.g, auraCfg.color.b, false)
            SetParticleFxLoopedAlpha(auraHandle, auraCfg.alpha or 200)
        end
    end

    wandParticles[playerPed] = {
        beam = beamHandle,
        aura = auraHandle
    }

    return beamHandle
end

local function StartProjectileTrail(prop)
    if not prop or not DoesEntityExist(prop) then return end

    local trailCfg = Config.ProjectileTrail or {}

    RequestNamedPtfxAsset('core')
    while not HasNamedPtfxAssetLoaded('core') do
        Wait(0)
    end
    UseParticleFxAsset('core')

    local trail = StartNetworkedParticleFxLoopedOnEntity(
        trailCfg.name or 'veh_light_red_trail',
        prop,
        0.0, 0.0, 0.0,
        0.0, 0.0, 0.0,
        trailCfg.scale or 0.6,
        false, false, false
    )

    if trail then
        SetParticleFxLoopedEvolution(trail, 'speed', 1.2, false)
        local color = trailCfg.color or { r = 1.0, g = 0.4, b = 0.0 }
        SetParticleFxLoopedColour(trail, color.r, color.g, color.b, false)
        SetParticleFxLoopedAlpha(trail, trailCfg.alpha or 255)
    end

    projectileFx[prop] = { trail = trail }
end

local function CleanupProjectileFx(prop)
    local fxHandles = projectileFx[prop]
    if fxHandles then
        if fxHandles.trail then
            StopParticleFxLooped(fxHandles.trail, false)
            RemoveParticleFx(fxHandles.trail, false)
        end
    end
    projectileFx[prop] = nil
end

local function PlayImpactSound(coords)
    local soundCfg = Config.ImpactSound
    if not soundCfg or not soundCfg.url then return end

    -- REPLACE WITH YOUR SOUND SYSTEM
    -- exports['lo_audio']:playSound({
    -- id = ('th_firedrix_impact_%s'):format(GetGameTimer()),
    -- url = soundCfg.url,
    -- volume = soundCfg.volume or 1.0,
    -- loop = false,
    -- spatial = true,
    -- distance = 10.0,
    -- pos = {
    -- x = coords.x,
    -- y = coords.y,
    -- z = coords.z
    -- }
    -- })
end

local function ClearFire(fire)
    if not fire or not fire.flames then
        return
    end

    for _, flame in ipairs(fire.flames) do
        if flame then
            StopParticleFxLooped(flame, 0)
            RemoveParticleFx(flame, false)
        end
    end

    if fire.centerFlame then
        StopParticleFxLooped(fire.centerFlame, 0)
        RemoveParticleFx(fire.centerFlame, false)
    end

    RemoveNamedPtfxAsset('core')
end

local function SpawnFireCircle(coords, radius, duration)
    RequestNamedPtfxAsset('core')
    while not HasNamedPtfxAssetLoaded('core') do
        Wait(0)
    end

    local flames = {}
    local centerFlame

    for i = 1, Config.FireCircle.outerFlames do
        local angle = (i / Config.FireCircle.outerFlames) * 2 * math.pi
        local x = coords.x + (math.cos(angle) * radius)
        local y = coords.y + (math.sin(angle) * radius)
        local z = coords.z + 0.05

        UseParticleFxAssetNextCall('core')
        local flame = StartParticleFxLoopedAtCoord('ent_amb_torch_fire', x, y, z, 0.0, 0.0, 0.0, Config.FireCircle.outerScale, false, false, false, false)
        SetParticleFxLoopedAlpha(flame, 1.0)

        flames[#flames + 1] = flame
    end

    for i = 1, Config.FireCircle.middleFlames do
        local angle = (i / Config.FireCircle.middleFlames) * 2 * math.pi
        local x = coords.x + (math.cos(angle) * (radius * 0.6))
        local y = coords.y + (math.sin(angle) * (radius * 0.6))
        local z = coords.z + 0.05

        UseParticleFxAssetNextCall('core')
        local flame = StartParticleFxLoopedAtCoord('ent_amb_torch_fire', x, y, z, 0.0, 0.0, 0.0, Config.FireCircle.middleScale, false, false, false, false)
        SetParticleFxLoopedAlpha(flame, 1.0)

        flames[#flames + 1] = flame
    end

    for i = 1, Config.FireCircle.innerFlames do
        local angle = (i / Config.FireCircle.innerFlames) * 2 * math.pi
        local x = coords.x + (math.cos(angle) * (radius * 0.3))
        local y = coords.y + (math.sin(angle) * (radius * 0.3))
        local z = coords.z + 0.05

        UseParticleFxAssetNextCall('core')
        local flame = StartParticleFxLoopedAtCoord('ent_amb_torch_fire', x, y, z, 0.0, 0.0, 0.0, Config.FireCircle.innerScale, false, false, false, false)
        SetParticleFxLoopedAlpha(flame, 1.0)

        flames[#flames + 1] = flame
    end

    local centerPtfx = Config.FireCircle.centerPtfx
    if centerPtfx and centerPtfx ~= '' then
        local offsetZ = Config.FireCircle.centerOffsetZ or 0.0
        local scale = Config.FireCircle.centerScale or 1.5
        local alpha = Config.FireCircle.centerAlpha or 1.0

        UseParticleFxAssetNextCall('core')
        centerFlame = StartParticleFxLoopedAtCoord(centerPtfx, coords.x, coords.y, coords.z + offsetZ, 0.0, 0.0, 0.0, scale, false, false, false, false)
        if centerFlame then
            SetParticleFxLoopedAlpha(centerFlame, alpha)
        end
    end

    local fireId = 'fire_' .. GetGameTimer()
    activeFires[fireId] = { flames = flames, centerFlame = centerFlame }

    SetTimeout(duration, function()
        ClearFire(activeFires[fireId])
        activeFires[fireId] = nil
    end)
end

local function CreateFiredrixProjectile(startCoords, targetCoords, sourceServerId, radius, duration)
    local projCfg = Config.Projectile or {}
    local propModel = GetHashKey(projCfg.model or 'nib_accio_ray')
    lib.requestModel(propModel, 5000)

    local rayProp = CreateObject(propModel, startCoords.x, startCoords.y, startCoords.z, false, false, false)
    SetEntityCollision(rayProp, false, false)
    SetEntityAsMissionEntity(rayProp, true, true)
    SetEntityCompletelyDisableCollision(rayProp, false, false)
    SetEntityAlpha(rayProp, 255, false)

    local direction = vector3(
        targetCoords.x - startCoords.x,
        targetCoords.y - startCoords.y,
        targetCoords.z - startCoords.z
    )
    local distance = #direction
    if distance < 0.01 then distance = 0.01 end
    direction = direction / distance

    local heading = math.deg(math.atan2(direction.y, direction.x)) + 90.0
    local pitch = -math.deg(math.asin(direction.z))
    local roll = 0.0

    SetEntityCoords(rayProp, startCoords.x, startCoords.y, startCoords.z, false, false, false, false)
    SetEntityRotation(rayProp, pitch, roll, heading, 2, true)

    StartProjectileTrail(rayProp)

    local speed = projCfg.speed or 80.0
    local projDuration = (distance / speed) * 1000.0
    local startTime = GetGameTimer()
    local endTime = startTime + projDuration

    firedrixProjectiles[rayProp] = {
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
        fireRadius = radius,
        fireDuration = duration
    }
end

CreateThread(function()
    while true do
        Wait(1)

        local currentTime = GetGameTimer()

        for propId, data in pairs(firedrixProjectiles) do
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
                        SetEntityRotation(data.prop, data.pitch, data.roll, data.heading, 2, true)
                    else
                        local propCoords = GetEntityCoords(data.prop)

                        PlayImpactSound(propCoords)
                        SpawnFireCircle(propCoords, data.fireRadius or 4.0, data.fireDuration or 5000)

                        CleanupProjectileFx(data.prop)
                        SetEntityVisible(data.prop, false, false)
                        SetEntityCoords(data.prop, 0.0, 0.0, -5000.0, false, false, false, false)
                        Wait(50)
                        DeleteEntity(data.prop)
                        DeleteObject(data.prop)

                        firedrixProjectiles[propId] = nil
                    end
                else
                    CleanupProjectileFx(data.prop)
                    firedrixProjectiles[propId] = nil
                end
            end
        end
    end
end)

RegisterNetEvent('th_firedrix:prepareCast', function(radius, duration)
    local casterPed = cache.ped

    CreateWandParticles(casterPed, true)

    local propsDelay, cleanupDelay, totalDuration = GetAnimationTimings()

    CreateThread(function()
        Wait(propsDelay)

        local handBone = GetPedBoneIndex(casterPed, Config.Projectile.handBone or 28422)
        local startCoords = GetWorldPositionOfEntityBone(casterPed, handBone)

        local camCoords = GetGameplayCamCoord()
        local camRot = GetGameplayCamRot(2)
        local direction = RotationToDirection(camRot)

        local _, _, coords = lib.raycast.cam(1 | 2 | 4 | 8 | 16, 4, 100)
        local finalTargetCoords

        if coords and (coords.x ~= 0.0 or coords.y ~= 0.0 or coords.z ~= 0.0) then
            finalTargetCoords = coords
        else
            finalTargetCoords = vector3(
                camCoords.x + direction.x * 100.0,
                camCoords.y + direction.y * 100.0,
                camCoords.z + direction.z * 100.0
            )
        end

        TriggerServerEvent('th_firedrix:broadcastProjectile', finalTargetCoords, radius, duration)

        Wait(cleanupDelay)
        StopWandParticles(casterPed)
    end)
end)

RegisterNetEvent('th_firedrix:otherPlayerCasting', function(sourceServerId)
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

    local _, _, totalDuration = GetAnimationTimings()
    SetTimeout(totalDuration, function()
        StopWandParticles(casterPed)
    end)
end)

RegisterNetEvent('th_firedrix:fireProjectile', function(sourceServerId, targetCoords, radius, duration)
    local casterPlayer = GetPlayerFromServerId(sourceServerId)
    if casterPlayer == -1 then
        return
    end

    local casterPed = GetPlayerPed(casterPlayer)
    if not DoesEntityExist(casterPed) then
        return
    end

    local handBone = GetPedBoneIndex(casterPed, Config.Projectile.handBone or 28422)
    local startCoords = GetWorldPositionOfEntityBone(casterPed, handBone)

    CreateFiredrixProjectile(startCoords, targetCoords, sourceServerId, radius, duration)
end)

RegisterNetEvent('th_incendrix:setPlayerOnFire', function(duration)
    local ped = PlayerPedId()
    local now = GetGameTimer()

    playerFireEndTime = math.max(playerFireEndTime, now + (duration or 3000))

    if playerFireHandle then
        return
    end

    CreateThread(function()
        RequestNamedPtfxAsset('core')
        while not HasNamedPtfxAssetLoaded('core') do
            Wait(0)
        end

        UseParticleFxAssetNextCall('core')
        playerFireHandle = StartParticleFxLoopedOnPedBone('ent_amb_torch_fire', ped, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, GetPedBoneIndex(ped, 0), 0.8, false, false, false)

        while GetGameTimer() < playerFireEndTime do
            ShakeGameplayCam('SMALL_EXPLOSION_SHAKE', 0.1)
            StartScreenEffect('RaceTurbo', 100, false)
            Wait(500)
        end

        if playerFireHandle then
            StopParticleFxLooped(playerFireHandle, 0)
            RemoveParticleFx(playerFireHandle, false)
            playerFireHandle = nil
        end

        StopScreenEffect('RaceTurbo')
    end)
end)

AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end

    if playerFireHandle then
        StopParticleFxLooped(playerFireHandle, 0)
        RemoveParticleFx(playerFireHandle, false)
        playerFireHandle = nil
    end
    StopScreenEffect('RaceTurbo')

    for id, fire in pairs(activeFires) do
        ClearFire(fire)
        activeFires[id] = nil
    end

    for ped, handles in pairs(wandParticles) do
        if handles.beam then
            StopParticleFxLooped(handles.beam, false)
            RemoveParticleFx(handles.beam, false)
        end
        if handles.aura then
            StopParticleFxLooped(handles.aura, false)
            RemoveParticleFx(handles.aura, false)
        end
    end
    wandParticles = {}

    for prop, data in pairs(firedrixProjectiles) do
        if type(data) == "table" and DoesEntityExist(data.prop) then
            CleanupProjectileFx(data.prop)
            DeleteEntity(data.prop)
            DeleteObject(data.prop)
        end
    end
    firedrixProjectiles = {}

    for prop, fxHandles in pairs(projectileFx) do
        if fxHandles.trail then
            StopParticleFxLooped(fxHandles.trail, false)
            RemoveParticleFx(fxHandles.trail, false)
        end
    end
    projectileFx = {}
end)
