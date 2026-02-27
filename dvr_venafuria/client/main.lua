---@diagnostic disable: undefined-global, trailing-space, unused-local, param-type-mismatch, missing-parameter
local venafuriaProjectiles = {}
local wandParticles = {}
local allParticles = {}
local activeLevitations = {}

local RequestNamedPtfxAsset = RequestNamedPtfxAsset
local HasNamedPtfxAssetLoaded = HasNamedPtfxAssetLoaded
local UseParticleFxAsset = UseParticleFxAsset
local UseParticleFxAssetNextCall = UseParticleFxAssetNextCall
local StartParticleFxLoopedOnEntity = StartParticleFxLoopedOnEntity
local StartParticleFxLoopedAtCoord = StartParticleFxLoopedAtCoord
local StartParticleFxNonLoopedAtCoord = StartParticleFxNonLoopedAtCoord
local SetParticleFxLoopedAlpha = SetParticleFxLoopedAlpha
local SetParticleFxLoopedColour = SetParticleFxLoopedColour
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
local SetEntityCoordsNoOffset = SetEntityCoordsNoOffset
local SetEntityRotation = SetEntityRotation
local SetEntityCollision = SetEntityCollision
local SetEntityAsMissionEntity = SetEntityAsMissionEntity
local SetEntityCompletelyDisableCollision = SetEntityCompletelyDisableCollision
local SetEntityVisible = SetEntityVisible
local SetEntityVelocity = SetEntityVelocity
local GetPlayerFromServerId = GetPlayerFromServerId
local GetPlayerPed = GetPlayerPed
local GetPlayerServerId = GetPlayerServerId
local PlayerId = PlayerId
local GetHashKey = GetHashKey
local CreateObject = CreateObject
local SetPedToRagdoll = SetPedToRagdoll
local SetPedCanRagdoll = SetPedCanRagdoll
local IsPedRagdoll = IsPedRagdoll
local ShakeGameplayCam = ShakeGameplayCam
local ApplyForceToEntity = ApplyForceToEntity
local FreezeEntityPosition = FreezeEntityPosition
local TaskPlayAnim = TaskPlayAnim
local ClearPedTasks = ClearPedTasks
local ClearPedTasksImmediately = ClearPedTasksImmediately
local StopAnimTask = StopAnimTask
local IsEntityPlayingAnim = IsEntityPlayingAnim
local DrawLightWithRange = DrawLightWithRange

local function HasProtheaShield()
    local hasShield = false
    if LocalPlayer and LocalPlayer.state then
        hasShield = LocalPlayer.state.protheaShield == true
    end
    if not hasShield and exports['dvr_prothea'] and exports['dvr_prothea'].hasLocalShield then
        local ok, result = pcall(function()
            return exports['dvr_prothea']:hasLocalShield()
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

local function CreateWandParticles(playerPed, isNetworked)
    local particleCfg <const> = Config.Effects and Config.Effects.particle
    if particleCfg then
        RequestNamedPtfxAsset(particleCfg.dict)
        while not HasNamedPtfxAssetLoaded(particleCfg.dict) do
            Wait(0)
        end

        UseParticleFxAsset(particleCfg.dict)
        UseParticleFxAssetNextCall(particleCfg.dict)

        local fx = StartParticleFxLoopedOnEntity(
            particleCfg.name, playerPed,
            particleCfg.offset.x, particleCfg.offset.y, particleCfg.offset.zstart or 0.0,
            particleCfg.rot.x, particleCfg.rot.y, particleCfg.rot.z,
            1.0, false, false, false
        )

        if fx then
            SetParticleFxLoopedAlpha(fx, particleCfg.alpha or 1.0)
            wandParticles[playerPed] = fx
            allParticles[fx] = {
                createdTime = GetGameTimer(),
                type = 'wandTrail'
            }
        end
    end
end

local function AttachRedProjectileTrail(rayProp)
    if not rayProp or not DoesEntityExist(rayProp) then
        return nil
    end

    local trailCfg = Config.Effects.projectile.trail
    RequestNamedPtfxAsset(trailCfg.asset)
    while not HasNamedPtfxAssetLoaded(trailCfg.asset) do
        Wait(0)
    end

    UseParticleFxAsset(trailCfg.asset)
    UseParticleFxAssetNextCall(trailCfg.asset)

    local trailHandle = StartParticleFxLoopedOnEntity(
        trailCfg.name, rayProp,
        0.0, 0.0, 0.0,
        0.0, 0.0, 0.0,
        trailCfg.scale or 0.8,
        false, false, false
    )

    if trailHandle then
        allParticles[trailHandle] = {
            createdTime = GetGameTimer(),
            type = 'projectileTrail'
        }
    end

    return trailHandle
end

local function SpawnImpactParticles(coords)
    local impactCfg = Config.Effects.impact
    RequestNamedPtfxAsset(impactCfg.asset)
    while not HasNamedPtfxAssetLoaded(impactCfg.asset) do
        Wait(0)
    end

    local handles = {}
    for _, effect in ipairs(impactCfg.effects) do
        UseParticleFxAssetNextCall(impactCfg.asset)
        local fx = StartParticleFxLoopedAtCoord(
            effect.name,
            coords.x, coords.y, coords.z + (effect.offset or 0.0),
            0.0, 0.0, 0.0,
            effect.scale or 1.0,
            false, false, false, false
        )
        if fx then
            handles[#handles + 1] = fx
            allParticles[fx] = { createdTime = GetGameTimer(), type = 'impact' }
        end
    end

    SetTimeout(2000, function()
        for _, fx in ipairs(handles) do
            StopParticleFxLooped(fx, false)
            RemoveParticleFx(fx, false)
            allParticles[fx] = nil
        end
    end)
end

local function SpawnBloodSplatter(coords)
    local bloodCfg = Config.Effects.bloodSplatter
    if not bloodCfg or not coords then return end

    local spreadRadius = bloodCfg.spreadRadius or 2.0

    for _, effect in ipairs(bloodCfg.effects) do
        local asset = effect.asset or 'core'

        RequestNamedPtfxAsset(asset)
        local timeout = 0
        while not HasNamedPtfxAssetLoaded(asset) and timeout < 100 do
            Wait(10)
            timeout = timeout + 1
        end

        if HasNamedPtfxAssetLoaded(asset) then
            local count = effect.count or 1

            for i = 1, count do
                -- Angle aléatoire autour du point d'impact
                local angle = math.random() * 2 * math.pi
                local distance = math.random() * spreadRadius * 0.5

                local offsetX = math.cos(angle) * distance
                local offsetY = math.sin(angle) * distance
                local offsetZ = 0.0 -- Au niveau du sol

                -- Rotation pour que le sang parte vers l'extérieur et le haut
                -- rotX incliné vers l'extérieur (entre -60 et -20 pour partir vers le haut)
                local rotX = math.random(-70, -30) * 1.0
                -- rotZ pointe dans la direction de l'angle (vers l'extérieur)
                local rotZ = math.deg(angle) + math.random(-30, 30)

                UseParticleFxAssetNextCall(asset)
                StartParticleFxNonLoopedAtCoord(
                    effect.name,
                    coords.x + offsetX, coords.y + offsetY, coords.z + offsetZ,
                    rotX, 0.0, rotZ,
                    effect.scale or 1.0,
                    false, false, false, false
                )
            end
        end
    end
end

local function CleanupProjectile(propId)
    local data = venafuriaProjectiles[propId]
    if not data then return end

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

    venafuriaProjectiles[propId] = nil
end

local function CreateVenaFuriaProjectile(startCoords, targetCoords, sourceServerId, casterPed, targetId, level)
    local projectileModel = GetHashKey(Config.Effects.projectile.model)
    lib.requestModel(projectileModel, 5000)

    local rayProp <const> = CreateObject(projectileModel, startCoords.x, startCoords.y, startCoords.z, false, false, false)
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

    StopWandTrail(casterPed)
    local trailHandle <const> = AttachRedProjectileTrail(rayProp)

    local duration <const> = (distance / (Config.Projectile.speed or 50.0)) * 1000.0
    local startTime <const> = GetGameTimer()
    local endTime <const> = startTime + duration

    venafuriaProjectiles[rayProp] = {
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

        for propId, data in pairs(venafuriaProjectiles) do
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

                    DrawLightWithRange(newPos.x, newPos.y, newPos.z, 255, 50, 50, 4.0, 8.0)
                end

                if currentTime >= data.endTime then
                    if DoesEntityExist(data.prop) then
                        local propCoords <const> = GetEntityCoords(data.prop)
                        local isLocalCaster = GetPlayerServerId(PlayerId()) == data.sourceServerId

                        if isLocalCaster then
                            TriggerServerEvent('dvr_venafuria:applyEffect', propCoords, data.targetId, data.level)
                        end

                        Wait(100)

                        SpawnImpactParticles(propCoords)

                        local shakeCfg = Config.Effects.shake
                        if shakeCfg then
                            local playerCoords = GetEntityCoords(cache.ped)
                            local dist = #(playerCoords - propCoords)
                            if dist < shakeCfg.maxDistance then
                                local intensity = shakeCfg.intensity * (1.0 - (dist / shakeCfg.maxDistance))
                                ShakeGameplayCam('SMALL_EXPLOSION_SHAKE', intensity)
                            end
                        end

                        if isLocalCaster then
                            local casterPed = cache.ped
                            if casterPed and DoesEntityExist(casterPed) then
                                RemoveWandParticles(casterPed)
                            end
                        end

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

CreateThread(function()
    while true do
        local hasLevitations = false
        for _ in pairs(activeLevitations) do
            hasLevitations = true
            break
        end

        if not hasLevitations then
            Wait(500)
        else
            Wait(1)
            local currentTime <const> = GetGameTimer()

            for targetId, levData in pairs(activeLevitations) do
                if DoesEntityExist(levData.ped) then
                    local isLocalTarget = (targetId == GetPlayerServerId(PlayerId()))
                    local currentPos = GetEntityCoords(levData.ped)

                    if levData.phase == 'rising' then
                        local elapsed = currentTime - levData.startTime
                        local riseTime = Config.Levitation.riseTime or 800

                        -- Activer le ragdoll au début de la montée (pour tous)
                        if not levData.ragdollStarted then
                            levData.ragdollStarted = true
                            SetPedCanRagdoll(levData.ped, true)
                            SetPedToRagdoll(levData.ped, 10000, 10000, 0, false, false, false)
                        end

                        if elapsed < riseTime then
                            local progress = elapsed / riseTime
                            local currentZ = levData.startZ + ((levData.targetZ - levData.startZ) * progress)
                            levData.currentZ = currentZ

                            -- Même logique pour tous les clients
                            local pedPos = GetEntityCoords(levData.ped)
                            local zDiff = currentZ - pedPos.z
                            local verticalVel = zDiff * 3.0
                            SetEntityVelocity(levData.ped, 0.0, 0.0, verticalVel)
                        else
                            levData.phase = 'holding'
                            levData.holdStartTime = currentTime
                            levData.currentZ = levData.targetZ
                        end

                    elseif levData.phase == 'holding' then
                        local currentZ = levData.targetZ

                        -- Même logique pour tous les clients
                        local pedPos = GetEntityCoords(levData.ped)
                        local zDiff = currentZ - pedPos.z
                        local verticalVel = zDiff * 3.0
                        SetEntityVelocity(levData.ped, 0.0, 0.0, verticalVel)

                        -- Maintenir le ragdoll
                        if not IsPedRagdoll(levData.ped) then
                            SetPedToRagdoll(levData.ped, 10000, 10000, 0, false, false, false)
                        end

                        local maxHoldTime = Config.Levitation.maxHoldTime or 5000
                        local holdElapsed = currentTime - levData.holdStartTime
                        if holdElapsed >= maxHoldTime then
                            levData.phase = 'falling'
                            levData.fallStartTime = currentTime
                            levData.fallInitialized = false
                        end

                    elseif levData.phase == 'falling' then
                        if not levData.fallInitialized then
                            levData.fallInitialized = true
                            levData.fallStartTime = levData.fallStartTime or currentTime

                            FreezeEntityPosition(levData.ped, false)

                            -- Appliquer à tous les clients
                            SetPedCanRagdoll(levData.ped, true)
                            local ragdollDuration = 800
                            if levData.isFinalSmash then
                                ragdollDuration = (Config.Ragdoll.baseDuration or 3000) + ((levData.level or 0) * (Config.Ragdoll.perLevel or 500))
                                ragdollDuration = math.min(ragdollDuration, Config.Ragdoll.maxDuration or 6000)
                            end
                            SetPedToRagdoll(levData.ped, ragdollDuration, ragdollDuration, 0, false, false, false)

                            local dropForce = Config.Levitation.dropForce or 30.0
                            SetEntityVelocity(levData.ped, 0.0, 0.0, -dropForce)
                            ApplyForceToEntity(levData.ped, 1, 0.0, 0.0, -dropForce * 0.5, 0.0, 0.0, 0.0, 0, false, true, true, false, true)
                        end

                        local fallElapsed = currentTime - levData.fallStartTime
                        if currentPos.z <= levData.startZ + 0.5 or fallElapsed > 800 then
                            if levData.isFinalSmash then
                                -- Dernier smash: explosion de sang et fin
                                if levData.auraFx then
                                    StopParticleFxLooped(levData.auraFx, false)
                                    RemoveParticleFx(levData.auraFx, false)
                                    allParticles[levData.auraFx] = nil
                                    levData.auraFx = nil
                                end

                                if isLocalTarget and not levData.bloodSpawned then
                                    levData.bloodSpawned = true
                                    local impactCoords = { x = currentPos.x, y = currentPos.y, z = currentPos.z }
                                    TriggerServerEvent('dvr_venafuria:bloodImpact', impactCoords)
                                end
                                activeLevitations[targetId] = nil
                            else
                                -- Pas le dernier smash: relever la cible
                                levData.phase = 'rising'
                                levData.startTime = currentTime
                                levData.startZ = currentPos.z
                                levData.targetZ = currentPos.z + (Config.Levitation.height or 3.0)
                                levData.currentZ = currentPos.z
                                levData.fallInitialized = false
                                levData.ragdollStarted = false
                            end
                        end
                    end

                    if levData and levData.phase ~= 'falling' then
                        local lightZ = levData.currentZ or levData.targetZ
                        DrawLightWithRange(levData.startX, levData.startY, lightZ + 0.5, 255, 50, 50, 5.0, 6.0)
                    end
                else
                    if levData.auraFx then
                        StopParticleFxLooped(levData.auraFx, false)
                        RemoveParticleFx(levData.auraFx, false)
                        allParticles[levData.auraFx] = nil
                    end
                    activeLevitations[targetId] = nil
                end
            end
        end
    end
end)

RegisterNetEvent('dvr_venafuria:startLevitation', function(level, casterId)
    if HasProtheaShield() then
        return
    end

    local playerPed = cache.ped
    local currentPos = GetEntityCoords(playerPed)
    local levHeight = Config.Levitation.height or 4.0
    local myServerId = GetPlayerServerId(PlayerId())

    local existingLev = activeLevitations[myServerId]
    if existingLev and existingLev.auraFx then
        StopParticleFxLooped(existingLev.auraFx, false)
        RemoveParticleFx(existingLev.auraFx, false)
    end

    local auraCfg = Config.Effects.liftAura
    local auraFx = nil
    if auraCfg then
        RequestNamedPtfxAsset(auraCfg.asset)
        while not HasNamedPtfxAssetLoaded(auraCfg.asset) do
            Wait(0)
        end
        UseParticleFxAsset(auraCfg.asset)
        auraFx = StartParticleFxLoopedOnEntity(
            auraCfg.effect, playerPed,
            0.0, 0.0, 0.0,
            0.0, 0.0, 0.0,
            auraCfg.scale or 1.5,
            false, false, false
        )
        if auraFx and auraCfg.color then
            SetParticleFxLoopedColour(auraFx, auraCfg.color.r / 255.0, auraCfg.color.g / 255.0, auraCfg.color.b / 255.0, false)
        end
        if auraFx then
            allParticles[auraFx] = { createdTime = GetGameTimer(), type = 'liftAura' }
        end
    end

    activeLevitations[myServerId] = {
        ped = playerPed,
        level = level or 0,
        startTime = GetGameTimer(),
        startX = currentPos.x,
        startY = currentPos.y,
        startZ = currentPos.z,
        targetZ = currentPos.z + levHeight,
        currentZ = currentPos.z,
        phase = 'rising',
        auraFx = auraFx,
        casterId = casterId or 0,
        currentSmash = 0,
        totalSmashes = #(Config.Levitation.smashTimings or { 1200, 2400, 3600 }),
        isFinalSmash = false,
        bloodSpawned = false
    }
end)

RegisterNetEvent('dvr_venafuria:syncLevitation', function(targetId, level, casterId)
    local myServerId = GetPlayerServerId(PlayerId())

    -- Si c'est moi la cible, vérifier le bouclier et créer les particules
    if targetId == myServerId then
        if HasProtheaShield() then
            return
        end

        local playerPed = cache.ped
        local currentPos = GetEntityCoords(playerPed)
        local levHeight = Config.Levitation.height or 4.0

        local existingLev = activeLevitations[targetId]
        if existingLev and existingLev.auraFx then
            StopParticleFxLooped(existingLev.auraFx, false)
            RemoveParticleFx(existingLev.auraFx, false)
        end

        local auraCfg = Config.Effects.liftAura
        local auraFx = nil
        if auraCfg then
            RequestNamedPtfxAsset(auraCfg.asset)
            while not HasNamedPtfxAssetLoaded(auraCfg.asset) do
                Wait(0)
            end
            UseParticleFxAsset(auraCfg.asset)
            auraFx = StartParticleFxLoopedOnEntity(
                auraCfg.effect, playerPed,
                0.0, 0.0, 0.0,
                0.0, 0.0, 0.0,
                auraCfg.scale or 1.5,
                false, false, false
            )
            if auraFx and auraCfg.color then
                SetParticleFxLoopedColour(auraFx, auraCfg.color.r / 255.0, auraCfg.color.g / 255.0, auraCfg.color.b / 255.0, false)
            end
            if auraFx then
                allParticles[auraFx] = { createdTime = GetGameTimer(), type = 'liftAura' }
            end
        end

        activeLevitations[targetId] = {
            ped = playerPed,
            level = level or 0,
            startTime = GetGameTimer(),
            startX = currentPos.x,
            startY = currentPos.y,
            startZ = currentPos.z,
            targetZ = currentPos.z + levHeight,
            currentZ = currentPos.z,
            phase = 'rising',
            auraFx = auraFx,
            casterId = casterId or 0,
            currentSmash = 0,
            totalSmashes = #(Config.Levitation.smashTimings or { 1200, 2400, 3600 }),
            isFinalSmash = false,
            bloodSpawned = false
        }
    else
        -- Pour les autres clients, tracker la lévitation de la cible distante
        local targetPlayer = GetPlayerFromServerId(targetId)
        if targetPlayer == -1 then return end

        local targetPed = GetPlayerPed(targetPlayer)
        if not DoesEntityExist(targetPed) then return end

        local currentPos = GetEntityCoords(targetPed)
        local levHeight = Config.Levitation.height or 4.0

        local existingLev = activeLevitations[targetId]
        if existingLev and existingLev.auraFx then
            StopParticleFxLooped(existingLev.auraFx, false)
            RemoveParticleFx(existingLev.auraFx, false)
        end

        -- Créer les particules sur le ped distant aussi
        local auraCfg = Config.Effects.liftAura
        local auraFx = nil
        if auraCfg then
            RequestNamedPtfxAsset(auraCfg.asset)
            while not HasNamedPtfxAssetLoaded(auraCfg.asset) do
                Wait(0)
            end
            UseParticleFxAsset(auraCfg.asset)
            auraFx = StartParticleFxLoopedOnEntity(
                auraCfg.effect, targetPed,
                0.0, 0.0, 0.0,
                0.0, 0.0, 0.0,
                auraCfg.scale or 1.5,
                false, false, false
            )
            if auraFx and auraCfg.color then
                SetParticleFxLoopedColour(auraFx, auraCfg.color.r / 255.0, auraCfg.color.g / 255.0, auraCfg.color.b / 255.0, false)
            end
            if auraFx then
                allParticles[auraFx] = { createdTime = GetGameTimer(), type = 'liftAura' }
            end
        end

        activeLevitations[targetId] = {
            ped = targetPed,
            level = level or 0,
            startTime = GetGameTimer(),
            startX = currentPos.x,
            startY = currentPos.y,
            startZ = currentPos.z,
            targetZ = currentPos.z + levHeight,
            currentZ = currentPos.z,
            phase = 'rising',
            auraFx = auraFx,
            casterId = casterId or 0,
            currentSmash = 0,
            totalSmashes = #(Config.Levitation.smashTimings or { 1200, 2400, 3600 }),
            isFinalSmash = false,
            bloodSpawned = false
        }
    end
end)

RegisterNetEvent('dvr_venafuria:dropTarget', function()
    local myServerId = GetPlayerServerId(PlayerId())
    local levData = activeLevitations[myServerId]

    if levData and (levData.phase == 'holding' or levData.phase == 'rising') then
        levData.phase = 'falling'
        levData.fallStartTime = GetGameTimer()
        levData.fallInitialized = false
    end
end)

RegisterNetEvent('dvr_venafuria:syncDrop', function(targetId)
    local levData = activeLevitations[targetId]

    if levData and (levData.phase == 'holding' or levData.phase == 'rising') then
        levData.phase = 'falling'
        levData.fallStartTime = GetGameTimer()
        levData.fallInitialized = false
    end
end)

RegisterNetEvent('dvr_venafuria:syncSmash', function(targetId, smashNumber, totalSmashes)
    local levData = activeLevitations[targetId]

    if levData and (levData.phase == 'holding' or levData.phase == 'rising') then
        levData.phase = 'falling'
        levData.fallStartTime = GetGameTimer()
        levData.fallInitialized = false
        levData.currentSmash = smashNumber
        levData.totalSmashes = totalSmashes
        levData.isFinalSmash = (smashNumber >= totalSmashes)
    end
end)

RegisterNetEvent('dvr_venafuria:syncBloodImpact', function(coords)
    if coords and coords.x and coords.y and coords.z then
        local impactPos = vector3(coords.x, coords.y, coords.z)
        SpawnBloodSplatter(impactPos)
    end
end)

local function PlayCastSound(coords)
    if not Config.Sounds or not Config.Sounds.cast then return end

    pcall(function()
        -- REPLACE WITH YOUR SOUND SYSTEM
        -- exports['lo_audio']:playSound({
        -- id = ('venafuria_cast_%s'):format(GetGameTimer()),
        -- url = Config.Sounds.cast.url,
        -- volume = Config.Sounds.cast.volume or 0.7,
        -- loop = false,
        -- spatial = true,
        -- distance = 10.0,
        -- pos = { x = coords.x, y = coords.y, z = coords.z }
        -- })
    end)
end

RegisterNetEvent('dvr_venafuria:prepareProjectile', function(targetId, level)
    local casterPed <const> = cache.ped

    CreateWandParticles(casterPed, true)
    local handBone <const> = GetPedBoneIndex(casterPed, 28422)
    local handPos <const> = GetWorldPositionOfEntityBone(casterPed, handBone)
    PlayCastSound(handPos)

    CreateThread(function()
        local shotTiming = Config.Projectile.shotTiming or 1100
        Wait(shotTiming)

        local camCoords <const> = GetGameplayCamCoord()
        local camRot <const> = GetGameplayCamRot(2)
        local direction <const> = RotationToDirection(camRot)

        local _, _, coords = lib.raycast.cam(1 | 2 | 4 | 8 | 16, 4, Config.Projectile.maxDistance or 100.0)
        local finalTargetCoords

        if coords and (coords.x ~= 0.0 or coords.y ~= 0.0 or coords.z ~= 0.0) then
            finalTargetCoords = coords
        else
            finalTargetCoords = vector3(
                camCoords.x + direction.x * (Config.Projectile.maxDistance or 100.0),
                camCoords.y + direction.y * (Config.Projectile.maxDistance or 100.0),
                camCoords.z + direction.z * (Config.Projectile.maxDistance or 100.0)
            )
        end

        local startCoords <const> = GetWorldPositionOfEntityBone(casterPed, handBone)
        TriggerServerEvent('dvr_venafuria:broadcastProjectile', finalTargetCoords, targetId or 0, level or 0)
    end)

    -- Déclencher les 3 smash aux timings configurés
    CreateThread(function()
        local smashTimings = Config.Levitation.smashTimings or { 1200, 2400, 3600 }
        local startTime = GetGameTimer()

        for i, timing in ipairs(smashTimings) do
            local waitTime = timing - (GetGameTimer() - startTime)
            if waitTime > 0 then
                Wait(waitTime)
            end
            -- Envoyer le numéro du smash (1, 2, 3) - le dernier déclenche le sang
            TriggerServerEvent('dvr_venafuria:triggerSmash', targetId or 0, i, #smashTimings)
        end
    end)
end)

RegisterNetEvent('dvr_venafuria:otherPlayerCasting', function(sourceServerId)
    local myServerId <const> = GetPlayerServerId(PlayerId())
    if sourceServerId == myServerId then return end

    local casterPlayer <const> = GetPlayerFromServerId(sourceServerId)
    if casterPlayer == -1 then return end

    local casterPed <const> = GetPlayerPed(casterPlayer)
    if not DoesEntityExist(casterPed) then return end

    CreateWandParticles(casterPed, true)
end)

RegisterNetEvent('dvr_venafuria:spawnProjectile', function(sourceServerId, targetCoords, targetId, level)
    local casterPlayer <const> = GetPlayerFromServerId(sourceServerId)
    if casterPlayer == -1 then return end

    local casterPed <const> = GetPlayerPed(casterPlayer)
    if not DoesEntityExist(casterPed) then return end

    if not targetCoords then return end

    local handBone <const> = GetPedBoneIndex(casterPed, 28422)
    local startCoords <const> = GetWorldPositionOfEntityBone(casterPed, handBone)
    CreateVenaFuriaProjectile(startCoords, targetCoords, sourceServerId, casterPed, targetId or 0, level or 0)
end)

AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end

    for propId, data in pairs(venafuriaProjectiles) do
        if type(data) == "table" and DoesEntityExist(data.prop) then
            DeleteEntity(data.prop)
            DeleteObject(data.prop)
        end
    end
    venafuriaProjectiles = {}

    for ped, handle in pairs(wandParticles) do
        RemoveParticleFx(handle, false)
    end
    wandParticles = {}

    for particleHandle, _ in pairs(allParticles) do
        StopParticleFxLooped(particleHandle, false)
        RemoveParticleFx(particleHandle, false)
    end
    allParticles = {}

    for targetId, levData in pairs(activeLevitations) do
        if levData.auraFx then
            StopParticleFxLooped(levData.auraFx, false)
            RemoveParticleFx(levData.auraFx, false)
        end
        if DoesEntityExist(levData.ped) then
            FreezeEntityPosition(levData.ped, false)
            ClearPedTasks(levData.ped)
        end
    end
    activeLevitations = {}

    RemoveNamedPtfxAsset('core')
end)
