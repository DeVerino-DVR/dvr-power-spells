---@diagnostic disable: undefined-global, trailing-space, unused-local, param-type-mismatch, missing-parameter, deprecated
local GetGameTimer = GetGameTimer
local GetPlayerFromServerId = GetPlayerFromServerId
local GetPlayerPed = GetPlayerPed
local GetEntityCoords = GetEntityCoords
local DoesEntityExist = DoesEntityExist
local SetEntityVelocity = SetEntityVelocity
local FreezeEntityPosition = FreezeEntityPosition
local SetEntityCoordsNoOffset = SetEntityCoordsNoOffset
local IsEntityPlayingAnim = IsEntityPlayingAnim
local TaskPlayAnim = TaskPlayAnim
local ClearPedTasks = ClearPedTasks
local ClearPedTasksImmediately = ClearPedTasksImmediately
local SetPedCanRagdoll = SetPedCanRagdoll
local StopAnimTask = StopAnimTask
local RequestNamedPtfxAsset = RequestNamedPtfxAsset
local HasNamedPtfxAssetLoaded = HasNamedPtfxAssetLoaded
local UseParticleFxAssetNextCall = UseParticleFxAssetNextCall
local UseParticleFxAsset = UseParticleFxAsset
local StartParticleFxNonLoopedAtCoord = StartParticleFxNonLoopedAtCoord
local StartParticleFxLoopedOnEntity = StartParticleFxLoopedOnEntity
local StopParticleFxLooped = StopParticleFxLooped
local SetParticleFxLoopedColour = SetParticleFxLoopedColour
local SetParticleFxLoopedAlpha = SetParticleFxLoopedAlpha
local DrawLightWithRange = DrawLightWithRange
local GetPedBoneIndex = GetPedBoneIndex
local GetWorldPositionOfEntityBone = GetWorldPositionOfEntityBone
local GetPlayerServerId = GetPlayerServerId
local PlayerId = PlayerId
local NetworkRequestControlOfEntity = NetworkRequestControlOfEntity
local StartNetworkedParticleFxLoopedOnEntity = StartNetworkedParticleFxLoopedOnEntity
local RemoveParticleFx = RemoveParticleFx
local ShakeGameplayCam = ShakeGameplayCam
local SetParticleFxLoopedEvolution = SetParticleFxLoopedEvolution
local StartParticleFxNonLoopedOnEntity = StartParticleFxNonLoopedOnEntity
local GetHashKey = GetHashKey
local CreateObject = CreateObject
local DeleteEntity = DeleteEntity
local DeleteObject = DeleteObject
local SetEntityCoords = SetEntityCoords
local SetEntityRotation = SetEntityRotation
local SetEntityCollision = SetEntityCollision
local SetEntityAsMissionEntity = SetEntityAsMissionEntity
local SetEntityCompletelyDisableCollision = SetEntityCompletelyDisableCollision
local SetEntityVisible = SetEntityVisible
local ApplyPedDamagePack = ApplyPedDamagePack
local math_sin = math.sin
local math_pi = math.pi
local vector3 = vector3

local activeLevitations = {}
local wandParticles = {}

local function EnsureAsset(asset)
    if not asset then return false end
    RequestNamedPtfxAsset(asset)
    while not HasNamedPtfxAssetLoaded(asset) do
        Wait(0)
    end
    return true
end

local function PulseLight(coords, settings, startTime)
    if not coords or not settings or not settings.color then return end
    local now <const> = GetGameTimer()
    local period <const> = settings.period or 1800
    local phase = ((now - (startTime or now)) % period) / period
    local wave <const> = 0.6 + 0.4 * math_sin(phase * 2.0 * math_pi)

    DrawLightWithRange(
        coords.x, coords.y, coords.z,
        settings.color.r,
        settings.color.g,
        settings.color.b,
        settings.radius or 6.0,
        (settings.intensity or 9.0) * wave
    )
end

local function StartAura(entity, cfg)
    if not cfg or not DoesEntityExist(entity) then return nil end
    if not EnsureAsset(cfg.asset) then return nil end

    UseParticleFxAssetNextCall(cfg.asset)
    local fxHandle = StartNetworkedParticleFxLoopedOnEntity(
        cfg.effect,
        entity,
        cfg.offset and cfg.offset.x or 0.0,
        cfg.offset and cfg.offset.y or 0.0,
        cfg.offset and cfg.offset.z or 0.0,
        0.0, 0.0, 0.0,
        cfg.scale or 1.0,
        false, false, false
    )

    if cfg.color then
        local r, g, b = cfg.color.r, cfg.color.g, cfg.color.b
        if r > 1.0 or g > 1.0 or b > 1.0 then
            r, g, b = r / 255.0, g / 255.0, b / 255.0
        end
        SetParticleFxLoopedColour(fxHandle, r, g, b, false)
    end

    if cfg.alpha then
        SetParticleFxLoopedAlpha(fxHandle, cfg.alpha)
    end

    return fxHandle
end

local function StopAura(handle)
    if handle then
        StopParticleFxLooped(handle, false)
    end
end

local function StopLevitation(levitationId)
    local levData = activeLevitations[levitationId]
    if not levData then return end

    if DoesEntityExist(levData.ped) then
        FreezeEntityPosition(levData.ped, false)
        StopAnimTask(levData.ped, Config.Levitation.playerAnimDict, Config.Levitation.playerAnimName, 1.0)
        ClearPedTasks(levData.ped)
        ClearPedTasksImmediately(levData.ped)
        SetPedCanRagdoll(levData.ped, true)
    end

    if levData.auraFx then
        StopAura(levData.auraFx)
        levData.auraFx = nil
    end

    activeLevitations[levitationId] = nil
end

local function AttachProjectileTrail(rayProp)
    if not rayProp or not DoesEntityExist(rayProp) then return nil end
    if not EnsureAsset('core') then return nil end

    UseParticleFxAsset('core')
    UseParticleFxAssetNextCall('core')
    StartParticleFxNonLoopedOnEntity('veh_light_red_trail', rayProp, 0.35, 0.0, 0.1, 0.0, 0.0, 0.0)

    local trailHandle = StartParticleFxLoopedOnEntity('veh_light_red_trail', rayProp, 0.35, 0.0, 0.1, 0.0, 0.0, 0.0, 0.55, false, false, false)
    SetParticleFxLoopedEvolution(trailHandle, 'speed', 1.0, false)
    SetParticleFxLoopedColour(trailHandle, 0.5, 0.0, 0.0, false)
    SetParticleFxLoopedAlpha(trailHandle, 255.0)

    return trailHandle
end

local function CreateWandParticles(playerPed)
    local weapon = GetCurrentPedWeaponEntityIndex and GetCurrentPedWeaponEntityIndex(playerPed)
    if not weapon or not DoesEntityExist(weapon) then return nil end

    if not EnsureAsset('core') then return nil end

    UseParticleFxAssetNextCall('core')
    local handle = StartNetworkedParticleFxLoopedOnEntity('veh_light_clear', weapon, 0.95, 0.0, 0.1, 0.0, 0.0, 0.0, 0.7, false, false, false)

    local wandCfg = Config.Effects and Config.Effects.wand
    if wandCfg and wandCfg.color then
        SetParticleFxLoopedColour(handle, wandCfg.color.r, wandCfg.color.g, wandCfg.color.b, false)
    else
        SetParticleFxLoopedColour(handle, 0.8, 0.0, 0.0, false)
    end
    SetParticleFxLoopedAlpha(handle, 255)

    wandParticles[playerPed] = handle
    return handle
end

local function StopWandTrail(playerPed)
    local handle = wandParticles[playerPed]
    if handle then
        StopParticleFxLooped(handle, false)
        RemoveParticleFx(handle, false)
        wandParticles[playerPed] = nil
    end
end

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

            for levitationId, levData in pairs(activeLevitations) do
                if DoesEntityExist(levData.ped) then
                    local currentZ = levData.coords.z
                    local isLocalPlayer <const> = (levitationId == GetPlayerServerId(PlayerId()))

                    if levData.isRising then
                        local elapsed <const> = currentTime - levData.startTime
                        if elapsed < Config.Levitation.riseTime then
                            local progress <const> = elapsed / Config.Levitation.riseTime
                            currentZ = levData.startZ + ((levData.targetZ - levData.startZ) * progress)
                        else
                            currentZ = levData.targetZ
                            levData.isRising = false
                        end
                    else
                        currentZ = levData.targetZ
                    end

                    levData.coords = vector3(levData.coords.x, levData.coords.y, currentZ)

                    local pulseCfg = Config.Effects and Config.Effects.pulseLight
                    if pulseCfg then
                        PulseLight(vector3(levData.coords.x, levData.coords.y, currentZ + 0.6), pulseCfg, levData.pulseStart)
                    end

                    if isLocalPlayer then
                        local currentPos <const> = GetEntityCoords(levData.ped)
                        local zDiff <const> = currentZ - currentPos.z
                        local verticalVel = zDiff * 3.0
                        SetEntityVelocity(levData.ped, 0.0, 0.0, verticalVel)
                    else
                        SetEntityVelocity(levData.ped, 0.0, 0.0, 0.0)
                        FreezeEntityPosition(levData.ped, true)
                        SetEntityCoordsNoOffset(levData.ped, levData.coords.x, levData.coords.y, currentZ, false, false, false)
                        FreezeEntityPosition(levData.ped, false)
                    end

                    if not levData.lastAnimTime or (currentTime - levData.lastAnimTime) > 100 then
                        if not IsEntityPlayingAnim(levData.ped, Config.Levitation.playerAnimDict, Config.Levitation.playerAnimName, 3) then
                            TaskPlayAnim(levData.ped, Config.Levitation.playerAnimDict, Config.Levitation.playerAnimName, 8.0, -8.0, -1, 49, 0, false, false, false)
                        end
                        levData.lastAnimTime = currentTime
                    end

                    if currentTime >= levData.endTime then
                        if levData.auraFx then
                            StopAura(levData.auraFx)
                            levData.auraFx = nil
                        end

                        FreezeEntityPosition(levData.ped, false)
                        StopAnimTask(levData.ped, Config.Levitation.playerAnimDict, Config.Levitation.playerAnimName, 1.0)
                        ClearPedTasks(levData.ped)
                        ClearPedTasksImmediately(levData.ped)

                        if isLocalPlayer then
                            SetEntityVelocity(levData.ped, 0.0, 0.0, -1.0)
                        else
                            SetEntityVelocity(levData.ped, 0.0, 0.0, -0.5)
                        end

                        SetPedCanRagdoll(levData.ped, true)
                        activeLevitations[levitationId] = nil

                        if isLocalPlayer then
                            TriggerServerEvent('th_bloodpillar:levitationExpired', levitationId)
                        end
                    end
                else
                    if levData.auraFx then
                        StopAura(levData.auraFx)
                        levData.auraFx = nil
                    end
                    activeLevitations[levitationId] = nil
                end
            end
        end
    end
end)

RegisterNetEvent('th_bloodpillar:startLevitation', function(targetServerId, casterServerId, duration, height, level)
    level = tonumber(level) or 0
    if level <= 0 then return end

    local targetPlayer <const> = GetPlayerFromServerId(targetServerId)
    if targetPlayer == -1 then return end

    local targetPed <const> = GetPlayerPed(targetPlayer)
    if not targetPed or not DoesEntityExist(targetPed) then return end

    local existingLev = activeLevitations[targetServerId]
    if existingLev then
        if existingLev.auraFx then
            StopAura(existingLev.auraFx)
        end
        activeLevitations[targetServerId] = nil
    end

    local currentPos <const> = GetEntityCoords(targetPed)
    local levitateHeight <const> = height or Config.Levitation.height

    lib.requestAnimDict(Config.Levitation.playerAnimDict)
    TaskPlayAnim(targetPed, Config.Levitation.playerAnimDict, Config.Levitation.playerAnimName, 8.0, -8.0, -1, 49, 0, false, false, false)

    activeLevitations[targetServerId] = {
        ped = targetPed,
        level = level,
        casterServerId = casterServerId,
        startTime = GetGameTimer(),
        endTime = GetGameTimer() + (duration or Config.Levitation.duration),
        startZ = currentPos.z,
        targetZ = currentPos.z + levitateHeight,
        coords = vector3(currentPos.x, currentPos.y, currentPos.z),
        isRising = true,
        animApplied = true,
        auraFx = nil,
        pulseStart = GetGameTimer()
    }

    local auraCfg = Config.Effects and Config.Effects.aura
    if auraCfg then
        activeLevitations[targetServerId].auraFx = StartAura(targetPed, auraCfg)
    end
end)

RegisterNetEvent('th_bloodpillar:playSecondAnim', function()
    local casterPed = cache.ped
    local speedMult = Config.Animation.phase2.speedMultiplier or 10.5

    lib.requestAnimDict(Config.Animation.phase2.dict)

    Wait(50)
    ClearPedTasks(casterPed)

    TaskPlayAnim(
        casterPed,
        Config.Animation.phase2.dict,
        Config.Animation.phase2.name,
        8.0 * speedMult, 8.0,
        -1,
        Config.Animation.phase2.flag,
        0, false, false, false
    )

    CreateThread(function()
        for _ = 1, 8 do
            SetEntityAnimSpeed(casterPed, Config.Animation.phase2.dict, Config.Animation.phase2.name, speedMult)
            Wait(90)
        end
    end)
end)

RegisterNetEvent('th_bloodpillar:otherPlayerSecondAnim', function(sourceServerId)
    if sourceServerId == GetPlayerServerId(PlayerId()) then return end

    local casterPlayer = GetPlayerFromServerId(sourceServerId)
    if casterPlayer == -1 then return end

    local casterPed = GetPlayerPed(casterPlayer)
    if not DoesEntityExist(casterPed) then return end

    local speedMult = Config.Animation.phase2.speedMultiplier or 10.5

    lib.requestAnimDict(Config.Animation.phase2.dict)
    TaskPlayAnim(
        casterPed,
        Config.Animation.phase2.dict,
        Config.Animation.phase2.name,
        8.0 * speedMult, 8.0,
        -1,
        Config.Animation.phase2.flag,
        0, false, false, false
    )

    CreateThread(function()
        for _ = 1, 8 do
            if DoesEntityExist(casterPed) then
                SetEntityAnimSpeed(casterPed, Config.Animation.phase2.dict, Config.Animation.phase2.name, speedMult)
            end
            Wait(90)
        end
    end)
end)

RegisterNetEvent('th_bloodpillar:expelTarget', function(casterServerId, targetServerId, level)
    level = tonumber(level) or 1

    local myServerId <const> = GetPlayerServerId(PlayerId())
    local isCaster <const> = (myServerId == casterServerId)

    local casterPlayer <const> = GetPlayerFromServerId(casterServerId)
    local targetPlayer <const> = GetPlayerFromServerId(targetServerId)
    if casterPlayer == -1 or targetPlayer == -1 then return end

    local casterPed <const> = GetPlayerPed(casterPlayer)
    local targetPed <const> = GetPlayerPed(targetPlayer)
    if not DoesEntityExist(casterPed) or not DoesEntityExist(targetPed) then return end

    local expulsionCfg <const> = Config.Expulsion

    CreateWandParticles(casterPed)

    local projectileDelay <const> = expulsionCfg.projectileDelay or 500

    CreateThread(function()
        Wait(projectileDelay)

        StopWandTrail(casterPed)

        local handBone <const> = GetPedBoneIndex(casterPed, 28422)
        local startCoords <const> = GetWorldPositionOfEntityBone(casterPed, handBone)
        local targetCoords <const> = GetEntityCoords(targetPed)

        local direction = targetCoords - startCoords
        local distance = #direction
        if distance < 0.1 then distance = 0.1 end
        direction = direction / distance

        local propModel <const> = GetHashKey('nib_magic_ray_basic')
        lib.requestModel(propModel, 5000)
        local rayProp <const> = CreateObject(propModel, startCoords.x, startCoords.y, startCoords.z, false, false, false)
        SetEntityCollision(rayProp, false, false)
        SetEntityAsMissionEntity(rayProp, true, true)
        SetEntityCompletelyDisableCollision(rayProp, true, false)

        local heading <const> = math.deg(math.atan2(direction.y, direction.x)) + 90.0
        local pitch <const> = -math.deg(math.asin(direction.z))
        SetEntityCoords(rayProp, startCoords.x, startCoords.y, startCoords.z, false, false, false, false)
        SetEntityRotation(rayProp, pitch, 0.0, heading, 2, true)

        local trailHandle = AttachProjectileTrail(rayProp)

        local speed <const> = expulsionCfg.projectileSpeed or 60.0
        local travelTime <const> = (distance / speed) * 1000.0
        local startTime <const> = GetGameTimer()
        local endTime <const> = startTime + travelTime

        while GetGameTimer() < endTime do
            Wait(0)
            local now <const> = GetGameTimer()
            local progress = (now - startTime) / travelTime
            if progress > 1.0 then progress = 1.0 end

            local newPos <const> = vector3(
                startCoords.x + direction.x * distance * progress,
                startCoords.y + direction.y * distance * progress,
                startCoords.z + direction.z * distance * progress
            )

            SetEntityCoords(rayProp, newPos.x, newPos.y, newPos.z, false, false, false, false)
            SetEntityRotation(rayProp, pitch, 0.0, heading, 2, true)
            DrawLightWithRange(newPos.x, newPos.y, newPos.z, 200, 20, 20, 4.0, 8.0)
        end

        if trailHandle then
            StopParticleFxLooped(trailHandle, false)
            RemoveParticleFx(trailHandle, false)
        end
        if DoesEntityExist(rayProp) then
            SetEntityVisible(rayProp, false, false)
            SetEntityCoords(rayProp, 0.0, 0.0, -5000.0, false, false, false, false)
            SetEntityAsMissionEntity(rayProp, false, false)
            DeleteEntity(rayProp)
            DeleteObject(rayProp)
        end

        local impactCoords <const> = GetEntityCoords(targetPed)

        StopLevitation(targetServerId)

        local impactCfg = Config.Effects and Config.Effects.impact
        if impactCfg and EnsureAsset(impactCfg.asset) then
            UseParticleFxAssetNextCall(impactCfg.asset)
            StartParticleFxNonLoopedAtCoord(
                impactCfg.effect,
                impactCoords.x, impactCoords.y, impactCoords.z,
                0.0, 0.0, 0.0,
                impactCfg.scale or 1.5,
                false, false, false
            )

            UseParticleFxAssetNextCall(impactCfg.asset)
            StartParticleFxNonLoopedAtCoord(
                impactCfg.effect,
                impactCoords.x, impactCoords.y, impactCoords.z + 0.5,
                0.0, 0.0, 0.0,
                (impactCfg.scale or 1.5) * 0.8,
                false, false, false
            )
        end

        CreateThread(function()
            local flashStart <const> = GetGameTimer()
            local flashDuration <const> = 400
            while GetGameTimer() - flashStart < flashDuration do
                local fade = 1.0 - ((GetGameTimer() - flashStart) / flashDuration)
                DrawLightWithRange(impactCoords.x, impactCoords.y, impactCoords.z, 200, 10, 10, 8.0, 12.0 * fade)
                Wait(0)
            end
        end)

        ApplyPedDamagePack(targetPed, 'BigHitByVehicle', 100.0, 100.0)
        ApplyPedDamagePack(targetPed, 'SCR_Torture', 100.0, 100.0)

        local playerCoords <const> = GetEntityCoords(cache.ped)
        local distToImpact = #(playerCoords - impactCoords)
        if distToImpact < 15.0 then
            local intensity = math.max(0.05, 0.15 * (1.0 - (distToImpact / 15.0)))
            ShakeGameplayCam('SMALL_EXPLOSION_SHAKE', intensity)
        end

        local casterCoords <const> = GetEntityCoords(casterPed)
        local expelDir = impactCoords - casterCoords
        local expelDist = #expelDir
        if expelDist < 0.1 then expelDist = 0.1 end
        expelDir = expelDir / expelDist

        local force <const> = expulsionCfg.force or 15.0

        local isTargetLocal <const> = (myServerId == targetServerId)
        if isTargetLocal then
            SetEntityVelocity(targetPed, expelDir.x * force, expelDir.y * force, force * 0.5)
        else
            NetworkRequestControlOfEntity(targetPed)
            SetEntityVelocity(targetPed, expelDir.x * force, expelDir.y * force, force * 0.5)
        end

        if isCaster then
            TriggerServerEvent('th_bloodpillar:applyExpulsionDamage', impactCoords, level)
        end
    end)
end)

AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end

    for _, levData in pairs(activeLevitations) do
        if DoesEntityExist(levData.ped) then
            ClearPedTasks(levData.ped)
            FreezeEntityPosition(levData.ped, false)
            if levData.auraFx then
                StopAura(levData.auraFx)
                levData.auraFx = nil
            end
        end
    end
    activeLevitations = {}

    for _, handle in pairs(wandParticles) do
        StopParticleFxLooped(handle, false)
        RemoveParticleFx(handle, false)
    end
    wandParticles = {}
end)
