---@diagnostic disable: trailing-space, undefined-global, param-type-mismatch
local cruoraxRayProps = {}
local wandParticles = {}
local allParticles = {}
local cruoraxAffectedPlayers = {}

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
local UseParticleFxAssetNextCall = UseParticleFxAssetNextCall
local SetEntityVisible = SetEntityVisible
local StartParticleFxNonLoopedOnEntity = StartParticleFxNonLoopedOnEntity
local StartNetworkedParticleFxNonLoopedOnEntity = StartNetworkedParticleFxNonLoopedOnEntity

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

local function CalculateCruoraxDuration(level)
    local maxDuration = Config.Cruorax.duration or 20000
    local minDuration = math.min(10000, maxDuration)
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

local function CreateWandParticles(playerPed, isNetworked)
    local weapon = GetCurrentPedWeaponEntityIndex and GetCurrentPedWeaponEntityIndex(playerPed)
    if not weapon or not DoesEntityExist(weapon) then
        return nil
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
    SetParticleFxLoopedAlpha(handle, 220)

    wandParticles[playerPed] = handle
    allParticles[handle] = {
        createdTime = GetGameTimer(),
        type = 'wandTrail'
    }

    return handle
end

local function AttachProjectileTrail(rayProp, isNetworked)
    if not rayProp or not DoesEntityExist(rayProp) then
        return
    end

    RequestNamedPtfxAsset(Config.Effects.projectileTrail.asset)
    while not HasNamedPtfxAssetLoaded(Config.Effects.projectileTrail.asset) do
        Wait(0)
    end

    UseParticleFxAsset(Config.Effects.projectileTrail.asset)
    UseParticleFxAssetNextCall(Config.Effects.projectileTrail.asset)

    if isNetworked then
        StartNetworkedParticleFxNonLoopedOnEntity(
            Config.Effects.projectileTrail.name,
            rayProp,
            0.35, 0.0, 0.1,
            0.0, 0.0, 0.0
        )
    else
        StartParticleFxNonLoopedOnEntity(
            Config.Effects.projectileTrail.name,
            rayProp,
            0.35, 0.0, 0.1,
            0.0, 0.0, 0.0
        )
    end

    local trailHandle
    if isNetworked then
        trailHandle = StartNetworkedParticleFxLoopedOnEntity(
            Config.Effects.projectileTrail.name,
            rayProp,
            0.35, 0.0, 0.1,
            0.0, 0.0, 0.0,
            Config.Effects.projectileTrail.scale,
            false, false, false
        )
    else
        trailHandle = StartParticleFxLoopedOnEntity(
            Config.Effects.projectileTrail.name,
            rayProp,
            0.35, 0.0, 0.1,
            0.0, 0.0, 0.0,
            Config.Effects.projectileTrail.scale,
            false, false, false
        )
    end

    SetParticleFxLoopedEvolution(trailHandle, 'speed', 1.0, false)
    SetParticleFxLoopedColour(trailHandle,
        Config.Effects.projectileTrail.color.r,
        Config.Effects.projectileTrail.color.g,
        Config.Effects.projectileTrail.color.b,
        false
    )
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

local function CreateBloodCircle(coords)
    local circleConfig = Config.Effects.bloodCircle
    if not circleConfig then return end

    local radius = circleConfig.radius or 2.5
    local pointCount = circleConfig.pointCount or 24
    local scale = circleConfig.scale or 3.5
    local duration = circleConfig.duration or 5000
    local spawnDelay = circleConfig.spawnDelay or 40
    local waves = circleConfig.waves or 3
    local waveDelay = circleConfig.waveDelay or 800

    local groundZ = coords.z - 1.0
    local success, actualGroundZ = GetGroundZFor_3dCoord(coords.x, coords.y, coords.z + 2.0, false)
    if success then
        groundZ = actualGroundZ
    end

    local baseZ = groundZ + 0.1

    CreateThread(function()
        RequestNamedPtfxAsset(circleConfig.asset)
        while not HasNamedPtfxAssetLoaded(circleConfig.asset) do
            Wait(0)
        end

        for wave = 1, waves do
            local angleStep = (2 * math.pi) / pointCount

            for i = 1, pointCount do
                local angle = (i - 1) * angleStep
                local x = coords.x + radius * math.cos(angle)
                local y = coords.y + radius * math.sin(angle)

                local rotX = math.random(-60, 60) * 1.0
                local rotY = math.random(-60, 60) * 1.0
                local rotZ = math.deg(angle) + math.random(-30, 30)

                local particleScale = scale * (0.8 + math.random() * 0.4)

                UseParticleFxAssetNextCall(circleConfig.asset)
                StartParticleFxNonLoopedAtCoord(
                    circleConfig.name,
                    x, y, baseZ,
                    rotX, rotY, rotZ,
                    particleScale,
                    false, false, false
                )

                if wave == 1 then
                    UseParticleFxAssetNextCall(circleConfig.asset)
                    StartParticleFxNonLoopedAtCoord(
                        circleConfig.name,
                        x, y, baseZ,
                        -90.0 + math.random(-20, 20),
                        0.0,
                        math.random(0, 360) * 1.0,
                        particleScale * 1.2,
                        false, false, false
                    )
                end

                if spawnDelay > 0 then
                    Wait(spawnDelay)
                end
            end

            if wave < waves then
                Wait(waveDelay)
            end
        end
    end)
end

local function CreateImpactExplosion(coords)
    local impactConfig = Config.Effects.impactExplosion
    if not impactConfig then return end

    local count = impactConfig.count or 30
    local scale = impactConfig.scale or 5.0
    local radius = impactConfig.radius or 3.0
    local waves = impactConfig.waves or 5
    local waveDelay = impactConfig.waveDelay or 150

    local groundZ = coords.z - 1.0
    local success, actualGroundZ = GetGroundZFor_3dCoord(coords.x, coords.y, coords.z + 2.0, false)
    if success then
        groundZ = actualGroundZ
    end

    local baseZ = groundZ + 0.1

    CreateThread(function()
        RequestNamedPtfxAsset(impactConfig.asset)
        while not HasNamedPtfxAssetLoaded(impactConfig.asset) do
            Wait(0)
        end

        for wave = 1, waves do
            local waveScale = scale * (1.0 - (wave - 1) * 0.1)
            local waveCount = math.floor(count / waves)

            for i = 1, waveCount do
                local angle = math.random() * math.pi * 2
                local dist = math.random(0, math.floor(radius * 100)) / 100.0
                local offsetX = math.cos(angle) * dist
                local offsetY = math.sin(angle) * dist

                local rotX = math.random(-180, 180) * 1.0
                local rotY = math.random(-180, 180) * 1.0
                local rotZ = math.random(0, 360) * 1.0

                local particleScale = waveScale * (0.8 + math.random() * 0.8)

                UseParticleFxAssetNextCall(impactConfig.asset)
                StartParticleFxNonLoopedAtCoord(
                    impactConfig.name,
                    coords.x + offsetX,
                    coords.y + offsetY,
                    baseZ,
                    rotX, rotY, rotZ,
                    particleScale,
                    false, false, false
                )
            end

            for i = 1, math.floor(waveCount / 2) do
                local angle = math.random() * math.pi * 2
                local elevAngle = math.random(30, 80) * math.pi / 180
                local dist = math.random(50, math.floor(radius * 150)) / 100.0

                local offsetX = math.cos(angle) * dist * math.cos(elevAngle)
                local offsetY = math.sin(angle) * dist * math.cos(elevAngle)
                local offsetZ = dist * math.sin(elevAngle)

                local rotX = math.random(-180, 180) * 1.0
                local rotY = math.random(-180, 180) * 1.0
                local rotZ = math.random(0, 360) * 1.0

                UseParticleFxAssetNextCall(impactConfig.asset)
                StartParticleFxNonLoopedAtCoord(
                    impactConfig.name,
                    coords.x + offsetX,
                    coords.y + offsetY,
                    baseZ + offsetZ,
                    rotX, rotY, rotZ,
                    waveScale * (1.0 + math.random() * 0.5),
                    false, false, false
                )
            end

            if wave == 1 then
                for i = 1, 5 do
                    UseParticleFxAssetNextCall(impactConfig.asset)
                    StartParticleFxNonLoopedAtCoord(
                        impactConfig.name,
                        coords.x,
                        coords.y,
                        baseZ,
                        math.random(-30, 30) * 1.0,
                        math.random(-30, 30) * 1.0,
                        math.random(0, 360) * 1.0,
                        scale * 2.0,
                        false, false, false
                    )
                end
            end

            if wave < waves then
                Wait(waveDelay)
            end
        end
    end)
end

local function CreateCruoraxProjectile(startCoords, targetCoords, sourceServerId, casterPed, spellLevel, cruoraxDuration, targetServerId, projectileType)
    local propModel = GetHashKey(Config.Projectile.model)
    lib.requestModel(propModel, 5000)

    local rayProp = CreateObject(propModel, startCoords.x, startCoords.y, startCoords.z, false, false, false)
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

    local heading = math.deg(math.atan2(direction.y, direction.x)) + 90.0
    local pitch = -math.deg(math.asin(direction.z))
    local roll = 0.0

    SetEntityCoords(rayProp, startCoords.x, startCoords.y, startCoords.z, false, false, false, false)
    SetEntityRotation(rayProp, pitch, roll, heading, 2, true)

    local trailHandle = TransferWandTrailToProjectile(casterPed, rayProp)

    local speed = Config.Projectile.speed or 80.0
    local duration = (distance / speed) * 1000.0
    local startTime = GetGameTimer()
    local endTime = startTime + duration

    cruoraxRayProps[rayProp] = {
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
        spellLevel = spellLevel or 0,
        cruoraxDuration = cruoraxDuration or CalculateCruoraxDuration(spellLevel),
        targetServerId = targetServerId,
        projectileType = projectileType or 1
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

        local currentTime = GetGameTimer()

        for propId, data in pairs(cruoraxRayProps) do
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
                    if data.projectileType == 1 then
                        CreateImpactExplosion(data.targetCoords)

                        local myServerId = GetPlayerServerId(PlayerId())
                        if data.sourceServerId == myServerId and data.targetServerId and data.targetServerId > 0 then
                            TriggerServerEvent('th_cruorax:applyEffect', data.targetServerId, data.spellLevel)
                        end
                    elseif data.projectileType == 2 then
                        CreateBloodCircle(data.targetCoords)
                    end

                    if data.trailHandle then
                        StopParticleFxLooped(data.trailHandle, false)
                        RemoveParticleFx(data.trailHandle, false)
                        allParticles[data.trailHandle] = nil
                        data.trailHandle = nil
                    end

                    if DoesEntityExist(data.prop) then
                        SetEntityVisible(data.prop, false, false)
                        SetEntityCoords(data.prop, 0.0, 0.0, -5000.0, false, false, false, false)
                        Wait(50)
                        DeleteEntity(data.prop)
                        DeleteObject(data.prop)
                    end

                    cruoraxRayProps[propId] = nil
                end
            end
        end
    end
end)

RegisterNetEvent('th_cruorax:prepareProjectile', function(spellLevel)
    local casterPed = cache.ped

    CreateWandParticles(casterPed, true)

    local duration = Config.Animation.duration or 2000
    local speed = Config.Animation.speedMultiplier or 1.5
    local realDuration = duration / speed
    local effectPercent = Config.Animation.effectPercent or 0.30
    local projectilePercent = Config.Animation.projectilePercent or 0.70
    local effectDelay = math.floor(realDuration * effectPercent)
    local projectileDelay = math.floor(realDuration * projectilePercent)

    local finalTargetCoords = nil
    local targetServerId = nil

    CreateThread(function()
        if effectDelay > 0 then Wait(effectDelay) end

        local camCoords = GetGameplayCamCoord()
        local camRot = GetGameplayCamRot(2)
        local direction = RotationToDirection(camRot)

        local hit, entityHit, coords = lib.raycast.cam(1 | 2 | 4 | 8 | 16, 4, 1000)

        if coords and (coords.x ~= 0.0 or coords.y ~= 0.0 or coords.z ~= 0.0) then
            finalTargetCoords = coords
            if entityHit and DoesEntityExist(entityHit) and IsEntityAPed(entityHit) and IsPedAPlayer(entityHit) then
                local targetPlayer = NetworkGetPlayerIndexFromPed(entityHit)
                targetServerId = GetPlayerServerId(targetPlayer)
            end
        else
            finalTargetCoords = vector3(
                camCoords.x + direction.x * 1000.0,
                camCoords.y + direction.y * 1000.0,
                camCoords.z + direction.z * 1000.0
            )
        end
    end)

    CreateThread(function()
        if projectileDelay > 0 then Wait(projectileDelay) end

        local handBone = GetPedBoneIndex(casterPed, Config.Projectile.handBone)
        local startCoords = GetWorldPositionOfEntityBone(casterPed, handBone)

        if not finalTargetCoords then
            local camCoords = GetGameplayCamCoord()
            local camRot = GetGameplayCamRot(2)
            local direction = RotationToDirection(camRot)
            local hit, entityHit, coords = lib.raycast.cam(1 | 2 | 4 | 8 | 16, 4, 1000)

            if coords and (coords.x ~= 0.0 or coords.y ~= 0.0 or coords.z ~= 0.0) then
                finalTargetCoords = coords
                if entityHit and DoesEntityExist(entityHit) and IsEntityAPed(entityHit) and IsPedAPlayer(entityHit) then
                    local targetPlayer = NetworkGetPlayerIndexFromPed(entityHit)
                    targetServerId = GetPlayerServerId(targetPlayer)
                end
            else
                finalTargetCoords = vector3(
                    camCoords.x + direction.x * 1000.0,
                    camCoords.y + direction.y * 1000.0,
                    camCoords.z + direction.z * 1000.0
                )
            end
        end

        TriggerServerEvent('th_cruorax:broadcastProjectile', finalTargetCoords, spellLevel, targetServerId, 1)

        RemoveWandParticles(casterPed)

        local anim2Duration = Config.Animation2.duration or 1200
        local anim2Speed = Config.Animation2.speedMultiplier or 12.0
        local anim2RealDuration = anim2Duration / anim2Speed
        local anim2ProjectilePercent = Config.Animation2.projectilePercent or 0.90
        local anim2ProjectileDelay = math.floor(anim2RealDuration * anim2ProjectilePercent)

        Wait(500)
        CreateWandParticles(casterPed, true)

        TriggerServerEvent('th_cruorax:playSecondAnimation')

        Wait(anim2ProjectileDelay)

        local handBone2 = GetPedBoneIndex(casterPed, Config.Projectile.handBone)
        local startCoords2 = GetWorldPositionOfEntityBone(casterPed, handBone2)

        TriggerServerEvent('th_cruorax:broadcastProjectile', finalTargetCoords, spellLevel, targetServerId, 2)

        Wait(math.floor(anim2RealDuration - anim2ProjectileDelay) + 200)
        RemoveWandParticles(casterPed)
    end)
end)

RegisterNetEvent('th_cruorax:otherPlayerCasting', function(sourceServerId)
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

    local duration = Config.Animation.duration or 2000
    local speed = Config.Animation.speedMultiplier or 1.5
    local realDuration = duration / speed

    SetTimeout(math.floor(realDuration), function()
        RemoveWandParticles(casterPed)
    end)
end)

RegisterNetEvent('th_cruorax:playSecondAnim', function()
    local casterPed = cache.ped
    local speedMult = Config.Animation2.speedMultiplier or 12.0

    lib.requestAnimDict(Config.Animation2.dict)
    TaskPlayAnim(
        casterPed,
        Config.Animation2.dict,
        Config.Animation2.name,
        8.0 * speedMult, 8.0,
        -1,
        Config.Animation2.flag,
        0, false, false, false
    )

    CreateThread(function()
        for i = 1, 8 do
            SetEntityAnimSpeed(casterPed, Config.Animation2.dict, Config.Animation2.name, speedMult)
            Wait(90)
        end
    end)
end)

RegisterNetEvent('th_cruorax:otherPlayerSecondAnim', function(sourceServerId)
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

    local speedMult = Config.Animation2.speedMultiplier or 12.0

    lib.requestAnimDict(Config.Animation2.dict)
    TaskPlayAnim(
        casterPed,
        Config.Animation2.dict,
        Config.Animation2.name,
        8.0 * speedMult, 8.0,
        -1,
        Config.Animation2.flag,
        0, false, false, false
    )

    CreateThread(function()
        for i = 1, 8 do
            if DoesEntityExist(casterPed) then
                SetEntityAnimSpeed(casterPed, Config.Animation2.dict, Config.Animation2.name, speedMult)
            end
            Wait(90)
        end
    end)

    local anim2Duration = Config.Animation2.duration or 1200
    local anim2RealDuration = anim2Duration / speedMult

    SetTimeout(math.floor(anim2RealDuration + 300), function()
        RemoveWandParticles(casterPed)
    end)
end)

RegisterNetEvent('th_cruorax:fireProjectile', function(sourceServerId, targetCoords, targetServerId, level, duration, projectileType)
    local casterPlayer = GetPlayerFromServerId(sourceServerId)
    if casterPlayer == -1 then
        return
    end

    local casterPed = GetPlayerPed(casterPlayer)
    if not DoesEntityExist(casterPed) then
        return
    end

    local spellLevel = ResolveSpellLevel('cruorax', sourceServerId, level)
    local cruoraxDuration = duration or CalculateCruoraxDuration(spellLevel)
    local handBone = GetPedBoneIndex(casterPed, Config.Projectile.handBone)
    local startCoords = GetWorldPositionOfEntityBone(casterPed, handBone)

    CreateCruoraxProjectile(startCoords, targetCoords, sourceServerId, casterPed, spellLevel, cruoraxDuration, targetServerId, projectileType or 1)
end)

RegisterNetEvent('th_cruorax:applySurrender', function(duration, level)
    local hasShield = false
    if LocalPlayer and LocalPlayer.state then
        hasShield = LocalPlayer.state.protheaShield == true
    end

    if not hasShield then
        local ok, result = pcall(function()
            return exports['th_prothea'] and exports['th_prothea'].hasLocalShield and exports['th_prothea']:hasLocalShield()
        end)
        hasShield = ok and result == true
    end

    if hasShield then
        print('[Cruorax] Soumission ignorée (bouclier Prothea actif)')
        return
    end

    if LocalPlayer and LocalPlayer.state then
        LocalPlayer.state:set('cruorax', true, true)
    end

    local playerPed = cache.ped
    local playerCoords = GetEntityCoords(playerPed)
    local lockToken = GetGameTimer()
    local effectDuration = math.floor(duration or CalculateCruoraxDuration(level))

    -- REPLACE WITH YOUR EMOTE SYSTEM (e.g. scully_emotemenu, dpemotes, rpemotes)
    local emoteCommand = Config.Cruorax.emoteCommand or 'surrender'
    local scullyOk, scullyErr = pcall(function()
        exports['scully_emotemenu']:playEmoteByCommand(emoteCommand)
    end)

    if not scullyOk then
        ExecuteCommand('e ' .. emoteCommand)
    end

    Wait(500)

    cruoraxAffectedPlayers[playerPed] = true

    CreateThread(function()
        while lockToken and lockToken + effectDuration > GetGameTimer() and cruoraxAffectedPlayers[playerPed] do
            DisableControlAction(0, 21, true)
            DisableControlAction(0, 22, true)
            DisableControlAction(0, 24, true)
            DisableControlAction(0, 25, true)
            DisableControlAction(0, 32, true)
            DisableControlAction(0, 33, true)
            DisableControlAction(0, 34, true)
            DisableControlAction(0, 35, true)
            DisableControlAction(0, 36, true)
            DisableControlAction(0, 37, true)
            DisableControlAction(0, 44, true)
            DisableControlAction(0, 45, true)
            DisableControlAction(0, 140, true)
            DisableControlAction(0, 141, true)
            DisableControlAction(0, 142, true)
            DisableControlAction(0, 143, true)
            DisablePlayerFiring(cache.playerId, true)
            Wait(0)
        end
    end)

    lib.notify({
        title = 'Cruorax',
        description = 'Vous êtes forcé de vous rendre !',
        type = 'error',
        icon = 'hands',
        duration = 5000
    })
end)

RegisterNetEvent('th_cruorax:removeSurrender', function()
    local playerPed = cache.ped
    if LocalPlayer and LocalPlayer.state then
        LocalPlayer.state:set('cruorax', false, true)
    end

    local scullyOk, scullyErr = pcall(function()
        exports['scully_emotemenu']:cancelEmote()
    end)

    if not scullyOk then
        ExecuteCommand('e c')
    end

    if cruoraxAffectedPlayers[playerPed] then
        cruoraxAffectedPlayers[playerPed] = nil
    end

    lib.notify({
        title = 'Cruorax',
        description = 'Vous êtes libéré de la soumission !',
        type = 'success',
        icon = 'heart',
        duration = 3000
    })
end)

AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    if LocalPlayer and LocalPlayer.state then
        LocalPlayer.state:set('cruorax', false, true)
    end

    for propId, data in pairs(cruoraxRayProps) do
        if type(data) == "table" then
            if data.trailHandle then
                StopParticleFxLooped(data.trailHandle, false)
                RemoveParticleFx(data.trailHandle, false)
            end
            if DoesEntityExist(data.prop) then
                DeleteObject(data.prop)
                DeleteEntity(data.prop)
            end
        end
    end

    for ped, handle in pairs(wandParticles) do
        if handle then
            StopParticleFxLooped(handle, false)
            RemoveParticleFx(handle, false)
        end
    end

    for particleHandle, particleData in pairs(allParticles) do
        StopParticleFxLooped(particleHandle, false)
        RemoveParticleFx(particleHandle, false)
    end

    cruoraxRayProps = {}
    wandParticles = {}
    allParticles = {}
    cruoraxAffectedPlayers = {}

    RemoveNamedPtfxAsset('core')
end)
