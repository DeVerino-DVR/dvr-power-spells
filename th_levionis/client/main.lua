---@diagnostic disable: undefined-global, trailing-space, unused-local, deprecated, param-type-mismatch
local GetGameTimer = GetGameTimer
local GetPlayerFromServerId = GetPlayerFromServerId
local GetPlayerPed = GetPlayerPed
local GetEntityCoords = GetEntityCoords
local DoesEntityExist = DoesEntityExist
local GetEntityVelocity = GetEntityVelocity
local SetEntityVelocity = SetEntityVelocity
local FreezeEntityPosition = FreezeEntityPosition
local SetEntityCoordsNoOffset = SetEntityCoordsNoOffset
local SetEntityCoords = SetEntityCoords
local NetworkRequestControlOfEntity = NetworkRequestControlOfEntity
local IsControlJustPressed = IsControlJustPressed
local IsEntityPlayingAnim = IsEntityPlayingAnim
local TaskPlayAnim = TaskPlayAnim
local ClearPedTasks = ClearPedTasks
local ClearPedTasksImmediately = ClearPedTasksImmediately
local SetPedCanRagdoll = SetPedCanRagdoll
local GetGamePool = GetGamePool
local GetPlayerServerId = GetPlayerServerId
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
local math_sin = math.sin
local math_pi = math.pi
local math_max = math.max
local math_sqrt = math.sqrt
local vector3 = vector3

local function ClampToRange(origin, point, range)
    if not origin or not point or not range or range <= 0.0 then
        return point, false
    end

    local dx = point.x - origin.x
    local dy = point.y - origin.y
    local dz = point.z - origin.z
    local distSq = dx * dx + dy * dy + dz * dz
    local maxSq = range * range

    if distSq <= maxSq then
        return point, false
    end

    local scale = range / math_sqrt(distSq)
    return vector3(origin.x + dx * scale, origin.y + dy * scale, origin.z + dz * scale), true
end

local activeLevitations = {}

local function EnsureAsset(asset)
    if not asset then
        return false
    end

    RequestNamedPtfxAsset(asset)
    while not HasNamedPtfxAssetLoaded(asset) do
        Wait(0)
    end
    return true
end

local function PulseLight(coords, settings, startTime)
    if not coords or not settings or not settings.color then
        return
    end

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

local function PlayNonLoopedEffect(definition, coords)
    if not definition or not coords or not definition.asset or not definition.effect then
        return
    end

    if not EnsureAsset(definition.asset) then
        return
    end

    local offset = definition.offset
    if offset then
        coords = vector3(coords.x + offset.x, coords.y + offset.y, coords.z + offset.z)
    end

    local repetitions <const> = definition.count or 1
    for _ = 1, repetitions do
        UseParticleFxAssetNextCall(definition.asset)
        StartParticleFxNonLoopedAtCoord(
            definition.effect,
            coords.x, coords.y, coords.z,
            0.0, 0.0, 0.0,
            definition.scale or 1.0,
            false, false, false
        )
    end

    if definition.light then
        local lightCfg = definition.light
        local start <const> = GetGameTimer()
        local duration <const> = lightCfg.duration or 400

        CreateThread(function()
            local now = GetGameTimer()
            while now - start < duration do
                local progress <const> = (now - start) / duration
                local fade <const> = 1.0 - progress
                DrawLightWithRange(
                    coords.x, coords.y, coords.z,
                    lightCfg.color.r,
                    lightCfg.color.g,
                    lightCfg.color.b,
                    lightCfg.radius or 5.0,
                    (lightCfg.intensity or 9.0) * fade
                )
                Wait(0)
                now = GetGameTimer()
            end
        end)
    end
end

local function StartAura(entity, cfg)
    if not cfg or not DoesEntityExist(entity) then
        return nil
    end

    if not EnsureAsset(cfg.asset) then
        return nil
    end

    UseParticleFxAsset(cfg.asset)
    local fxHandle = StartParticleFxLoopedOnEntity(
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
        local r = cfg.color.r
        local g = cfg.color.g
        local b = cfg.color.b
        if r > 1.0 or g > 1.0 or b > 1.0 then
            r = r / 255.0
            g = g / 255.0
            b = b / 255.0
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

local function PlayCastFlash(ped)
    if not DoesEntityExist(ped) then
        return
    end

    local cfg = Config.Effects and Config.Effects.castFlash
    if not cfg then
        return
    end

    local coords = GetEntityCoords(ped)
    PlayNonLoopedEffect(cfg, coords)
end

local function PlayReleaseEffect(coords)
    local cfg = Config.Effects and Config.Effects.release
    if not cfg then
        return
    end

    PlayNonLoopedEffect(cfg, coords)
end

local function DropLevitationObjects(levData)
    local releaseCoords = vector3(levData.coords.x, levData.coords.y, levData.targetZ + 0.4)
    PlayReleaseEffect(releaseCoords)

    for obj, handle in pairs(levData.objectAuras or {}) do
        StopAura(handle)
        levData.objectAuras[obj] = nil
    end

    for obj, originalData in pairs(levData.originalPositions or {}) do
        if DoesEntityExist(obj) then
            NetworkRequestControlOfEntity(obj)
            local offset = originalData.offset or vector3(0.0, 0.0, 0.0)
            SetEntityCoords(obj, levData.coords.x + offset.x, levData.coords.y + offset.y, levData.coords.z, false, false, false, false)
            SetEntityVelocity(obj, 0.0, 0.0, -(levData.dropForce or 12.0))
        end
    end
end

local function ConfigureObjectLevitation(levData)
    if not levData then return end

    local levCfg = Config.Levitation or {}
    local level = tonumber(levData.level) or 0
    local baseRange = levCfg.controlRange or 15.0
    local maxRange = levCfg.maxControlRange or math_max(baseRange, 35.0)
    local baseDuration = levCfg.duration or 5000
    local riseTime = levCfg.riseTime or 0

    levData.controlEnabled = levData.controlEnabled and level >= 2
    levData.controlRange = baseRange
    levData.controlDeadline = nil

    if level == 2 then
        levData.controlDeadline = levData.startTime + 2000
    elseif level == 3 then
        levData.controlDeadline = levData.startTime + 10000
    elseif level >= 5 then
        levData.controlRange = maxRange
    end

    local desiredDuration = baseDuration
    if levData.controlDeadline then
        local needed = (levData.controlDeadline - levData.startTime) + riseTime + 500
        if needed > desiredDuration then
            desiredDuration = needed
        end
    end
    levData.endTime = math_max(levData.endTime or desiredDuration, desiredDuration)
end

RegisterNetEvent('th_levionis:startLevitation', function(targetServerId, casterServerId, duration, height, targetCoords, level)
    level = tonumber(level) or 0
    if level <= 0 then
        return
    end

    if targetServerId ~= -1 then
        local targetPlayer <const> = GetPlayerFromServerId(targetServerId)
        if targetPlayer == -1 then return end
        
        local targetPed <const> = GetPlayerPed(targetPlayer)
        
        if targetPed and DoesEntityExist(targetPed) then
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
                startTime = GetGameTimer(),
                endTime = GetGameTimer() + (duration or Config.Levitation.duration),
                startZ = currentPos.z,
                targetZ = currentPos.z + levitateHeight,
                coords = vector3(currentPos.x, currentPos.y, currentPos.z),
                isRising = true,
                animApplied = true,
                isPlayer = true,
                auraFx = nil,
                pulseStart = GetGameTimer()
            }

            PlayCastFlash(targetPed)
            local auraCfg = Config.Effects and Config.Effects.playerAura
            if auraCfg then
                activeLevitations[targetServerId].auraFx = StartAura(targetPed, auraCfg)
            end
        end
    else
        if targetCoords then
            for levId, levData in pairs(activeLevitations) do
                if not levData.isPlayer and levData.casterServerId == casterServerId then
                    if levData.objectAuras then
                        for obj, handle in pairs(levData.objectAuras) do
                            StopAura(handle)
                        end
                    end
                    activeLevitations[levId] = nil
                end
            end

            local levitateHeight <const> = height or Config.Levitation.height
            local levitationId <const> = 'object_' .. GetGameTimer()
            
            local objects <const> = GetGamePool('CObject')
            local originalPositions = {}
            local auraHandles = {}
            
            for _, obj in ipairs(objects) do
                if DoesEntityExist(obj) then
                    local objCoords <const> = GetEntityCoords(obj)
                    local distance = #(objCoords - targetCoords)
                    
                    if distance < Config.Levitation.objectRadius then
                        NetworkRequestControlOfEntity(obj)
                        originalPositions[obj] = {
                            coords = vector3(objCoords.x, objCoords.y, objCoords.z),
                            velocity = GetEntityVelocity(obj),
                            offset = vector3(objCoords.x - targetCoords.x, objCoords.y - targetCoords.y, objCoords.z - targetCoords.z)
                        }

                        local auraCfg = Config.Effects and Config.Effects.objectAura
                        if auraCfg then
                            auraHandles[obj] = StartAura(obj, auraCfg)
                        end
                    end
                end
            end
            
            activeLevitations[levitationId] = {
                coords = targetCoords,
                controlOrigin = vector3(targetCoords.x, targetCoords.y, targetCoords.z),
                startTime = GetGameTimer(),
                endTime = GetGameTimer() + (duration or Config.Levitation.duration),
                startZ = targetCoords.z,
                targetZ = targetCoords.z + levitateHeight,
                height = levitateHeight,
                controlRange = Config.Levitation.controlRange or 25.0,
                dropForce = Config.Levitation.dropForce or 12.0,
                level = level,
                isRising = true,
                isPlayer = false,
                levitationId = levitationId,
                casterServerId = casterServerId,
                controlEnabled = casterServerId == GetPlayerServerId(PlayerId()),
                originalPositions = originalPositions,
                objectAuras = auraHandles,
                pulseStart = GetGameTimer()
            }
            ConfigureObjectLevitation(activeLevitations[levitationId])
        end
    end
end)

CreateThread(function()
    while true do
        local hasLevitations = false
        
        for _ in pairs(activeLevitations or {}) do
            hasLevitations = true
            break
        end
        
        if not hasLevitations then
            Wait(500)
        else
            Wait(1)
            
            local currentTime <const> = GetGameTimer()
            
            for levitationId, levData in pairs(activeLevitations or {}) do
                if levData.isPlayer then
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
                            FreezeEntityPosition(levData.ped, false)
                            StopAnimTask(levData.ped, Config.Levitation.playerAnimDict, Config.Levitation.playerAnimName, 1.0)
                            ClearPedTasks(levData.ped)
                            ClearPedTasksImmediately(levData.ped)

                            if levData.auraFx then
                                StopAura(levData.auraFx)
                                levData.auraFx = nil
                            end

                            PlayReleaseEffect(vector3(levData.coords.x, levData.coords.y, currentZ + 0.6))

                            if isLocalPlayer then
                                SetEntityVelocity(levData.ped, 0.0, 0.0, -1.0)
                            else
                                SetEntityVelocity(levData.ped, 0.0, 0.0, -0.5)
                            end
                            
                            SetPedCanRagdoll(levData.ped, true)
                            
                            activeLevitations[levitationId] = nil
                        end
                    else
                        if levData.auraFx then
                            StopAura(levData.auraFx)
                            levData.auraFx = nil
                        end
                        activeLevitations[levitationId] = nil
                    end
                else
                    if levData.isRising then
                        local elapsed <const> = currentTime - levData.startTime
                        
                        if elapsed < Config.Levitation.riseTime then
                            local progress <const> = elapsed / Config.Levitation.riseTime
                            local currentZ = levData.startZ + ((levData.targetZ - levData.startZ) * progress)
                            
                            local objects <const> = GetGamePool('CObject')
                            for _, obj in ipairs(objects) do
                                if DoesEntityExist(obj) then
                                    local objCoords <const> = GetEntityCoords(obj)
                                    local distance <const> = #(objCoords - levData.coords)
                                    
                                    if distance < Config.Levitation.objectRadius then
                                        local auraCfg = Config.Effects and Config.Effects.objectAura
                                        if auraCfg and not levData.objectAuras[obj] then
                                            levData.objectAuras[obj] = StartAura(obj, auraCfg)
                                        end
                                        SetEntityCoords(obj, objCoords.x, objCoords.y, currentZ, false, false, false, false)
                                        SetEntityVelocity(obj, 0.0, 0.0, 0.0)
                                    end
                                elseif levData.objectAuras[obj] then
                                    StopAura(levData.objectAuras[obj])
                                    levData.objectAuras[obj] = nil
                                end
                            end
                            local pulseCfg = Config.Effects and Config.Effects.pulseLight
                            if pulseCfg then
                                PulseLight(vector3(levData.coords.x, levData.coords.y, currentZ + 0.3), pulseCfg, levData.pulseStart)
                            end
                        else
                            levData.isRising = false
                        end
                    else
                        if levData.controlDeadline and currentTime >= levData.controlDeadline then
                            levData.dropRequested = true
                        end

                        if levData.controlEnabled and not levData.dropRequested then
                            local hit, _, hitCoords = lib.raycast.cam(1 | 2 | 4 | 8 | 16, 4, levData.controlRange or 25.0)
                            if hitCoords then
                                local origin = levData.controlOrigin or levData.coords
                                local range = levData.controlRange or 25.0
                                local clampedCoords = ClampToRange(origin, hitCoords, range)

                                levData.coords = clampedCoords
                                levData.targetZ = clampedCoords.z + (levData.height or Config.Levitation.height or 1.5)
                            end

                            if IsControlJustPressed(0, 24) then
                                levData.dropRequested = true
                            end
                        end

                        if levData.dropRequested then
                            DropLevitationObjects(levData)
                            activeLevitations[levitationId] = nil
                        else
                            local origin = levData.controlOrigin or levData.coords
                            local range = levData.controlRange or 25.0
                            local clampedTarget, forcedClamp = ClampToRange(origin, levData.coords, range)
                            if forcedClamp then
                                levData.coords = clampedTarget
                                levData.targetZ = clampedTarget.z + (levData.height or Config.Levitation.height or 1.5)
                            end

                            local objects <const> = GetGamePool('CObject')
                            for _, obj in ipairs(objects) do
                                if DoesEntityExist(obj) and levData.originalPositions[obj] then
                                    local offset <const> = levData.originalPositions[obj].offset or vector3(0.0, 0.0, 0.0)
                                    SetEntityCoords(obj, levData.coords.x + offset.x, levData.coords.y + offset.y, levData.targetZ, false, false, false, false)
                                    SetEntityVelocity(obj, 0.0, 0.0, 0.0)
                                elseif levData.objectAuras[obj] then
                                    StopAura(levData.objectAuras[obj])
                                    levData.objectAuras[obj] = nil
                                end
                            end
                            local pulseCfg = Config.Effects and Config.Effects.pulseLight
                            if pulseCfg then
                                PulseLight(vector3(levData.coords.x, levData.coords.y, levData.targetZ + 0.3), pulseCfg, levData.pulseStart)
                            end
                        end
                    end

                    for obj, handle in pairs(levData.objectAuras or {}) do
                        if not DoesEntityExist(obj) then
                            StopAura(handle)
                            levData.objectAuras[obj] = nil
                        end
                    end
                    
                    if currentTime >= levData.endTime and not levData.dropRequested then
                        DropLevitationObjects(levData)
                        activeLevitations[levitationId] = nil
                    end
                end
            end
        end
    end
end)

AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    
    for targetServerId, levData in pairs(activeLevitations) do
        if levData.isPlayer and DoesEntityExist(levData.ped) then
            ClearPedTasks(levData.ped)
            FreezeEntityPosition(levData.ped, false)
            if levData.auraFx then
                StopAura(levData.auraFx)
                levData.auraFx = nil
            end
        end

        if levData.objectAuras then
            for _, handle in pairs(levData.objectAuras) do
                StopAura(handle)
            end
        end
    end
    activeLevitations = {}
end)
