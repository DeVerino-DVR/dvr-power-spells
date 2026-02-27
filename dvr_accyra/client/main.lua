-- REQUIRES: ESX Framework (es_extended) - Replace ESX calls with your framework
---@diagnostic disable: trailing-space, undefined-global, deprecated
local DEBUG_MODE = false
local accioRayProps = {}
local wandParticles = {}
local wandLights = {}
local pullingObjects = {}
local projectileFx = {}
local projectileLights = {}
local castFxProfiles = {}
local droppingObjects = {}
local mathRandom = math.random
local RequestNamedPtfxAsset = RequestNamedPtfxAsset
local HasNamedPtfxAssetLoaded = HasNamedPtfxAssetLoaded
local UseParticleFxAsset = UseParticleFxAsset
local UseParticleFxAssetNextCall = UseParticleFxAssetNextCall
local StartNetworkedParticleFxLoopedOnEntity = StartNetworkedParticleFxLoopedOnEntity
local StartParticleFxLoopedOnEntity = StartParticleFxLoopedOnEntity
local StartParticleFxLoopedAtCoord = StartParticleFxLoopedAtCoord
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
local GetPlayerFromServerId = GetPlayerFromServerId
local GetPlayerPed = GetPlayerPed
local GetPedBoneIndex = GetPedBoneIndex
local GetWorldPositionOfEntityBone = GetWorldPositionOfEntityBone
local GetEntityCoords = GetEntityCoords
local SetEntityCoords = SetEntityCoords
local SetEntityRotation = SetEntityRotation
local DrawLightWithRange = DrawLightWithRange
local SetEntityAlpha = SetEntityAlpha
local SetEntityCollision = SetEntityCollision
local SetEntityAsMissionEntity = SetEntityAsMissionEntity
local SetEntityCompletelyDisableCollision = SetEntityCompletelyDisableCollision
local GetGamePool = GetGamePool
local SetEntityVelocity = SetEntityVelocity
local SetEntityDynamic = SetEntityDynamic
local ActivatePhysics = ActivatePhysics
local FreezeEntityPosition = FreezeEntityPosition
local ApplyForceToEntity = ApplyForceToEntity
local ApplyForceToEntityCenterOfMass = ApplyForceToEntityCenterOfMass
local IsEntityPositionFrozen = IsEntityPositionFrozen
local SetEntityHasGravity = SetEntityHasGravity
local GetGroundZFor_3dCoord = GetGroundZFor_3dCoord
local NetworkRequestControlOfEntity = NetworkRequestControlOfEntity
local NetworkHasControlOfEntity = NetworkHasControlOfEntity
local SetPedToRagdoll = SetPedToRagdoll
local GetVehiclePedIsIn = GetVehiclePedIsIn
local libRequestNamedPtfxAsset = lib.requestNamedPtfxAsset
local MAX_SPELL_LEVEL <const> = 5

local function DropObject(entity)
    if not entity or not DoesEntityExist(entity) then
        return
    end

    local function ensureControl()
        local attempts = 0
        while attempts < 15 and not NetworkHasControlOfEntity(entity) do
            NetworkRequestControlOfEntity(entity)
            Wait(0)
            attempts = attempts + 1
        end
    end

    ensureControl()

    SetEntityCollision(entity, true, true)
    FreezeEntityPosition(entity, false)
    SetEntityDynamic(entity, true)
    ActivatePhysics(entity)
    SetEntityHasGravity(entity, true)
    SetEntityVelocity(entity, 0.0, 0.0, -6.0)
    ApplyForceToEntity(entity, 1, 0.0, 0.0, -900.0, 0.0, 0.0, 0.0, 0, false, true, true, false, true)
    SetEntityAsMissionEntity(entity, true, false)

    local pos = GetEntityCoords(entity)
    local foundGround, groundZ = GetGroundZFor_3dCoord(pos.x, pos.y, pos.z + 200.0, false)

    droppingObjects[entity] = {
        entity = entity,
        groundZ = foundGround and groundZ or nil,
        startTime = GetGameTimer()
    }
end

local function EndPull(pullData)
    if not pullData or not pullData.object or not DoesEntityExist(pullData.object) then
        return
    end

    if pullData.isPed then
        if IsEntityPositionFrozen and IsEntityPositionFrozen(pullData.object) then
            FreezeEntityPosition(pullData.object, false)
        end
        return
    end

    if pullData.isVehicle then
        if IsEntityPositionFrozen and IsEntityPositionFrozen(pullData.object) then
            FreezeEntityPosition(pullData.object, false)
        end

        if NetworkHasControlOfEntity(pullData.object) then
            SetEntityVelocity(pullData.object, 0.0, 0.0, 0.0)
        end
        return
    end

    if not pullData.reached then
        DropObject(pullData.object)
        return
    end

    local function ensureControl()
        local attempts = 0
        while attempts < 15 and not NetworkHasControlOfEntity(pullData.object) do
            NetworkRequestControlOfEntity(pullData.object)
            Wait(0)
            attempts = attempts + 1
        end
    end

    ensureControl()

    if not NetworkHasControlOfEntity(pullData.object) then
        return
    end

    SetEntityAsMissionEntity(pullData.object, true, true)
    DeleteObject(pullData.object)
    DeleteEntity(pullData.object)
    return
end

local function BuildFxProfile(level)
    local clampedLevel = math.max(tonumber(level) or 0, 0)
    clampedLevel = math.floor(clampedLevel)
    if clampedLevel > MAX_SPELL_LEVEL then
        clampedLevel = MAX_SPELL_LEVEL
    end

    local normalized = clampedLevel / MAX_SPELL_LEVEL
    local quality = 0.2 + (normalized * 0.8)
    local scale = 0.7 + (normalized * 1.3)
    local brightness = 0.6 + (normalized * 1.4)
    local alpha = 0.7 + (normalized * 0.6)
    local countMult = 0.5 + (normalized * 1.5)

    local stage = math.floor((normalized * 9) + 1)
    if stage < 1 then
        stage = 1
    elseif stage > 10 then
        stage = 10
    end

    local stageData = {
        [1] = { pull = 0.0, control = 0.15, lift = 0.0, keepGravity = true },
        [2] = { pull = 0.35, control = 0.35, lift = 0.8, keepGravity = true },
        [3] = { pull = 0.7, control = 0.6, lift = 2.0, keepGravity = false },
        [4] = { pull = 1.0, control = 0.85, lift = 3.8, keepGravity = false },
        [5] = { pull = 1.3, control = 1.05, lift = 5.5, keepGravity = false },
        [6] = { pull = 1.7, control = 1.25, lift = 6.5, keepGravity = false },
        [7] = { pull = 2.0, control = 1.4, lift = 7.5, keepGravity = false },
        [8] = { pull = 2.4, control = 1.55, lift = 8.5, keepGravity = false },
        [9] = { pull = 2.7, control = 1.65, lift = 9.5, keepGravity = false },
        [10] = { pull = 3.0, control = 1.8, lift = nil, keepGravity = false }
    }

    local stageInfo = stageData[stage] or stageData[10]

    return {
        level = clampedLevel,
        quality = quality,
        scale = scale,
        brightness = brightness,
        alpha = alpha,
        countMult = countMult,
        pullPower = stageInfo.pull,
        control = stageInfo.control,
        liftCap = stageInfo.lift,
        keepGravity = stageInfo.keepGravity,
        stage = stage
    }
end

local function SetFxProfile(serverId, level)
    if not serverId then
        return nil
    end

    local profile = BuildFxProfile(level)
    castFxProfiles[serverId] = profile
    return profile
end

local function GetFxProfile(serverId)
    return castFxProfiles[serverId] or BuildFxProfile(0)
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

local function GetAnimationTimings()
    local animConfig <const> = Config.Animation or {}
    local speedMult = animConfig.speedMultiplier or 1.0
    if speedMult <= 0.0 then
        speedMult = 1.0
    end

    local propsDelay <const> = animConfig.propsDelay or 0
    local duration <const> = (animConfig.duration or 3000)
    local scaledDelay <const> = math.floor(propsDelay / speedMult)
    local scaledDuration <const> = math.max(scaledDelay, math.floor(duration / speedMult))
    local cleanupDelay <const> = math.max(0, scaledDuration - scaledDelay)

    return scaledDelay, cleanupDelay, scaledDuration
end

local function loadPtfx(asset)
    if not asset then
        return false
    end

    if libRequestNamedPtfxAsset(asset, 5000) then
        return true
    end

    RequestNamedPtfxAsset(asset)
    while not HasNamedPtfxAssetLoaded(asset) do
        Wait(0)
    end

    return true
end


local function startLightPulse(container, key, entity, offsetZ, intensityMult)
    if not entity or not DoesEntityExist(entity) then
        return
    end

    local color <const> = Config.Effects.light.color
    local intensity <const> = Config.Effects.light.intensity * (intensityMult or 1.0)
    local range <const> = Config.Effects.light.range * (intensityMult or 1.0)
    local offset <const> = offsetZ or 0.0

    container[key] = true

    CreateThread(function()
        while container[key] and DoesEntityExist(entity) do
            local coords <const> = GetEntityCoords(entity)
            DrawLightWithRange(coords.x, coords.y, coords.z + offset, color.r, color.g, color.b, intensity, range)
            Wait(0)
        end
        container[key] = nil
    end)
end

local function stopLightPulse(container, key)
    if container[key] then
        container[key] = nil
    end
end

local function CreateWandParticles(playerPed, isNetworked, fxProfile)
    local weapon <const> = GetCurrentPedWeaponEntityIndex(playerPed)
    if not weapon or not DoesEntityExist(weapon) then 
        return 
    end

    local scaleBoost <const> = (fxProfile and fxProfile.scale) or 1.0
    local alphaBoost <const> = (fxProfile and fxProfile.alpha) or 1.0
    
    if not loadPtfx(Config.Effects.wandParticles.asset) then
        return
    end

    UseParticleFxAsset(Config.Effects.wandParticles.asset)
    local beamHandle
    if isNetworked then
        beamHandle = StartNetworkedParticleFxLoopedOnEntity(
            Config.Effects.wandParticles.name,
            weapon,
            0.95, 0.0, 0.1,
            0.0, 0.0, 0.0,
            Config.Effects.wandParticles.scale,
            false, false, false
        )
    else
        beamHandle = StartParticleFxLoopedOnEntity(
            Config.Effects.wandParticles.name,
            weapon,
            0.95, 0.0, 0.1,
            0.0, 0.0, 0.0,
            Config.Effects.wandParticles.scale * scaleBoost,
            false, false, false
        )
    end

    if beamHandle then
        SetParticleFxLoopedEvolution(beamHandle, 'speed', 1.25, false)
        SetParticleFxLoopedColour(beamHandle, Config.Effects.wandParticles.color.r, Config.Effects.wandParticles.color.g, Config.Effects.wandParticles.color.b, false)
        SetParticleFxLoopedAlpha(beamHandle, math.min(255.0, Config.Effects.wandParticles.alpha * alphaBoost))
    end

    local auraHandle
    if Config.Effects.wandAura and loadPtfx(Config.Effects.wandAura.asset) then
        UseParticleFxAsset(Config.Effects.wandAura.asset)
        if isNetworked then
            auraHandle = StartNetworkedParticleFxLoopedOnEntity(
                Config.Effects.wandAura.name,
                weapon,
                0.6, 0.0, 0.15,
                0.0, 0.0, 0.0,
                Config.Effects.wandAura.scale * scaleBoost,
                false, false, false
            )
        else
            auraHandle = StartParticleFxLoopedOnEntity(
                Config.Effects.wandAura.name,
                weapon,
                0.6, 0.0, 0.15,
                0.0, 0.0, 0.0,
                Config.Effects.wandAura.scale * scaleBoost,
                false, false, false
            )
        end

        if auraHandle then
            SetParticleFxLoopedEvolution(auraHandle, 'speed', 0.8, false)
            SetParticleFxLoopedColour(auraHandle, Config.Effects.wandAura.color.r, Config.Effects.wandAura.color.g, Config.Effects.wandAura.color.b, false)
            SetParticleFxLoopedAlpha(auraHandle, math.min(255.0, Config.Effects.wandAura.alpha * alphaBoost))
        end
    end

    startLightPulse(wandLights, playerPed, weapon, 0.12, (fxProfile and fxProfile.brightness) or 1.0)

    wandParticles[playerPed] = {
        beam = beamHandle,
        aura = auraHandle
    }

    return beamHandle
end

local function RemoveWandParticles(playerPed)
    local handles = wandParticles[playerPed]
    if not handles then
        return
    end

    if handles.beam then
        StopParticleFxLooped(handles.beam, false)
        RemoveParticleFx(handles.beam, false)
    end

    if handles.aura then
        StopParticleFxLooped(handles.aura, false)
        RemoveParticleFx(handles.aura, false)
    end

    stopLightPulse(wandLights, playerPed)
    wandParticles[playerPed] = nil
    RemoveNamedPtfxAsset(Config.Effects.wandParticles.asset)
    if Config.Effects.wandAura then
        RemoveNamedPtfxAsset(Config.Effects.wandAura.asset)
    end
end

local function StartProjectileTrail(prop, fxProfile)
    if not Config.Effects.projectileTrail or not DoesEntityExist(prop) then
        return
    end

    local scaleBoost <const> = (fxProfile and fxProfile.scale) or 1.0
    local alphaBoost <const> = (fxProfile and fxProfile.alpha) or 1.0

    if not loadPtfx(Config.Effects.projectileTrail.asset) then
        return
    end

    UseParticleFxAsset(Config.Effects.projectileTrail.asset)
    local trail = StartNetworkedParticleFxLoopedOnEntity(
        Config.Effects.projectileTrail.name,
        prop,
        0.0, 0.0, 0.0,
        0.0, 0.0, 0.0,
        Config.Effects.projectileTrail.scale * scaleBoost,
        false, false, false
    )

    if trail then
        SetParticleFxLoopedEvolution(trail, 'speed', 1.2, false)
        SetParticleFxLoopedColour(trail, Config.Effects.projectileTrail.color.r, Config.Effects.projectileTrail.color.g, Config.Effects.projectileTrail.color.b, false)
        SetParticleFxLoopedAlpha(trail, math.min(255.0, Config.Effects.projectileTrail.alpha * alphaBoost))
    end

    projectileFx[prop] = {
        trail = trail
    }

    startLightPulse(projectileLights, prop, prop, 0.05, (fxProfile and fxProfile.brightness) or 1.0)
end

local function CleanupProjectileFx(prop)
    local fxHandles = projectileFx[prop]
    if fxHandles then
        if fxHandles.trail then
            StopParticleFxLooped(fxHandles.trail, false)
            RemoveParticleFx(fxHandles.trail, false)
        end
    end

    stopLightPulse(projectileLights, prop)
    projectileFx[prop] = nil

    if Config.Effects.projectileTrail then
        RemoveNamedPtfxAsset(Config.Effects.projectileTrail.asset)
    end
end

local function SpawnImpactEffects(propCoords, fxProfile)
    if not propCoords then
        return
    end

    local scaleBoost <const> = (fxProfile and fxProfile.scale) or 1.0
    local alphaBoost <const> = (fxProfile and fxProfile.alpha) or 1.0
    local countBoost <const> = (fxProfile and fxProfile.countMult) or 1.0
    local count <const> = math.max(1, math.floor((Config.Effects.impactParticles.count or 1) * countBoost))

    local fxHandles = {}
    if loadPtfx(Config.Effects.impactParticles.asset) then
        for i = 1, count do
            UseParticleFxAssetNextCall(Config.Effects.impactParticles.asset)
            local smoke = StartParticleFxLoopedAtCoord(
                Config.Effects.impactParticles.name,
                propCoords.x, propCoords.y, propCoords.z + 0.5,
                0.0, 0.0, mathRandom(0, 360),
                Config.Effects.impactParticles.scale * scaleBoost,
                false, false, false, false
            )

            if smoke then
                SetParticleFxLoopedColour(smoke, Config.Effects.impactParticles.color.r, Config.Effects.impactParticles.color.g, Config.Effects.impactParticles.color.b, false)
                SetParticleFxLoopedAlpha(smoke, math.min(255.0, 190.0 * alphaBoost))
                table.insert(fxHandles, smoke)
            end
        end
    end

    local shockwave
    if Config.Effects.impactShockwave and loadPtfx(Config.Effects.impactShockwave.asset) then
        UseParticleFxAsset(Config.Effects.impactShockwave.asset)
        shockwave = StartParticleFxLoopedAtCoord(
            Config.Effects.impactShockwave.name,
            propCoords.x, propCoords.y, propCoords.z + 0.3,
            0.0, 0.0, 0.0,
            Config.Effects.impactShockwave.scale * scaleBoost,
            false, false, false, false
        )

        if shockwave then
            SetParticleFxLoopedEvolution(shockwave, 'speed', 0.8, false)
            SetParticleFxLoopedColour(shockwave, Config.Effects.impactShockwave.color.r, Config.Effects.impactShockwave.color.g, Config.Effects.impactShockwave.color.b, false)
            SetParticleFxLoopedAlpha(shockwave, math.min(255.0, Config.Effects.impactShockwave.alpha * alphaBoost))
            table.insert(fxHandles, shockwave)
        end
    end

    local brightness <const> = (fxProfile and fxProfile.brightness) or 1.0
    DrawLightWithRange(propCoords.x, propCoords.y, propCoords.z + 0.2, Config.Effects.light.color.r, Config.Effects.light.color.g, Config.Effects.light.color.b, Config.Effects.light.intensity * 2.0 * brightness, Config.Effects.light.range * 0.7 * brightness)

    SetTimeout(Config.Effects.impactParticles.duration, function()
        for _, fx in ipairs(fxHandles) do
            StopParticleFxLooped(fx, 0)
            RemoveParticleFx(fx, false)
        end

        RemoveNamedPtfxAsset(Config.Effects.impactParticles.asset)
        if Config.Effects.impactShockwave then
            RemoveNamedPtfxAsset(Config.Effects.impactShockwave.asset)
        end
    end)
end

local function CreateAccioProjectile(startCoords, targetCoords, sourceServerId, fxProfile)  
    local propModel <const> = GetHashKey(Config.Projectile.model)
    lib.requestModel(propModel, 5000)
    
    local rayProp <const> = CreateObject(propModel, startCoords.x, startCoords.y, startCoords.z, false, false, false)
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
    direction = direction / distance
    
    local heading <const> = math.deg(math.atan2(direction.y, direction.x)) + 90.0
    local pitch <const> = -math.deg(math.asin(direction.z))
    local roll <const> = 0.0
    
    SetEntityCoords(rayProp, startCoords.x, startCoords.y, startCoords.z, false, false, false, false)
    SetEntityRotation(rayProp, pitch, roll, heading, 2, true)

    StartProjectileTrail(rayProp, fxProfile)
    
    local duration <const> = Config.Projectile.duration or (distance / Config.Projectile.speed) * 1000.0
    local startTime <const> = GetGameTimer()
    local endTime <const> = startTime + duration
    
    accioRayProps[rayProp] = {
        prop = rayProp,
        startCoords = startCoords,
        targetCoords = targetCoords,
        direction = direction,
        distance = distance,
        startTime = startTime,
        endTime = endTime,
        speed = Config.Projectile.speed,
        heading = heading,
        pitch = pitch,
        roll = roll,
        sourceServerId = sourceServerId,
        fxProfile = fxProfile
    }
end

CreateThread(function()
    while true do
        Wait(1)
        
        local currentTime <const> = GetGameTimer()
        
        for propId, data in pairs(accioRayProps) do
            if type(data) == "table" then
                if DoesEntityExist(data.prop) then
                    if currentTime < data.endTime then
                        local progress = (currentTime - data.startTime) / (data.endTime - data.startTime)
                        progress = math.min(progress, 1.0)
                        
                        local newPos <const> = vector3(
                            data.startCoords.x + (data.direction.x * data.distance * progress),
                            data.startCoords.y + (data.direction.y * data.distance * progress),
                            data.startCoords.z + (data.direction.z * data.distance * progress)
                        )
                        
                        SetEntityCoords(data.prop, newPos.x, newPos.y, newPos.z, false, false, false, false)
                    else
                        if DoesEntityExist(data.prop) then
                            local propCoords <const> = GetEntityCoords(data.prop)
                            
                            local casterPlayer <const> = GetPlayerFromServerId(data.sourceServerId)
                            local casterPed
                            local casterCoords
                            
                            if casterPlayer ~= -1 then
                                casterPed = GetPlayerPed(casterPlayer)
                                if DoesEntityExist(casterPed) then
                                    casterCoords = GetEntityCoords(casterPed)
                                else
                                    casterPed = nil
                                end
                            end

                            SpawnImpactEffects(propCoords, data.fxProfile)
                            
                            if casterCoords then
                                local casterVehicle
                                if casterPed and DoesEntityExist(casterPed) then
                                    casterVehicle = GetVehiclePedIsIn(casterPed, false)
                                    if casterVehicle == 0 then
                                        casterVehicle = nil
                                    end
                                end

                                local function addPullTarget(entity, entityCoords, isPed, isVehicle)
                                    if not entity or not DoesEntityExist(entity) then
                                        return
                                    end

                                    local distanceToCaster <const> = #(entityCoords - casterCoords)
                                    if distanceToCaster >= Config.Accio.maxDistance then
                                        return
                                    end

                                    for _, existingData in pairs(pullingObjects) do
                                        if existingData.object == entity then
                                            return
                                        end
                                    end

                                    if isPed then
                                        if GetVehiclePedIsIn(entity, false) ~= 0 then
                                            return
                                        end
                                    else
                                        SetEntityDynamic(entity, true)
                                        SetEntityCollision(entity, true, true)
                                        ActivatePhysics(entity)
                                    end

                                    NetworkRequestControlOfEntity(entity)

                                    local pullId = 'pull_' .. entity .. '_' .. GetGameTimer()
                                    pullingObjects[pullId] = {
                                        object = entity,
                                        startTime = GetGameTimer(),
                                        endTime = GetGameTimer() + Config.Accio.pullDuration,
                                        targetCoords = casterCoords,
                                        startCoords = entityCoords,
                                        sourceServerId = data.sourceServerId,
                                        profile = data.fxProfile,
                                        groundZ = select(2, GetGroundZFor_3dCoord(entityCoords.x, entityCoords.y, entityCoords.z + 50.0, false)),
                                        isPed = isPed == true,
                                        isVehicle = isVehicle == true
                                    }

                                    if DEBUG_MODE then
                                        print(string.format('[Accio Debug] Entité %d ajoutée à la liste d\'attraction! (isPed=%s, isVehicle=%s)', entity, tostring(isPed), tostring(isVehicle)))
                                    end
                                end

                                local objects <const> = GetGamePool('CObject')
                                for _, obj in ipairs(objects) do
                                    if DoesEntityExist(obj) and obj ~= data.prop then
                                        local objCoords <const> = GetEntityCoords(obj)
                                        if #(objCoords - propCoords) < Config.Accio.objectRadius then
                                            addPullTarget(obj, objCoords, false, false)
                                        end
                                    end
                                end

                                local peds <const> = GetGamePool('CPed')
                                for _, ped in ipairs(peds) do
                                    if DoesEntityExist(ped) and ped ~= casterPed then
                                        local pedCoords <const> = GetEntityCoords(ped)
                                        if #(pedCoords - propCoords) < Config.Accio.objectRadius then
                                            addPullTarget(ped, pedCoords, true, false)
                                        end
                                    end
                                end

                                local vehicles <const> = GetGamePool('CVehicle')
                                for _, vehicle in ipairs(vehicles) do
                                    if DoesEntityExist(vehicle) and vehicle ~= casterVehicle then
                                        local vehicleCoords <const> = GetEntityCoords(vehicle)
                                        if #(vehicleCoords - propCoords) < Config.Accio.objectRadius then
                                            addPullTarget(vehicle, vehicleCoords, false, true)
                                        end
                                    end
                                end
                            end
                            
                            CleanupProjectileFx(data.prop)
                            DeleteObject(data.prop)
                            SetEntityAsMissionEntity(data.prop, false, true)
                            DeleteEntity(data.prop)
                        else
                            CleanupProjectileFx(data.prop)
                        end
                        
                        accioRayProps[propId] = nil
                    end
                else
                    CleanupProjectileFx(data.prop)
                    accioRayProps[propId] = nil
                end
            end
        end
    end
end)

CreateThread(function()
    while true do
        local hasObjects = false
        
        for _ in pairs(pullingObjects or {}) do
            hasObjects = true
            break
        end
        
        if not hasObjects then
            Wait(500)
        else
            Wait(0)
            
            local currentTime <const> = GetGameTimer()
            
            for pullId, pullData in pairs(pullingObjects or {}) do
                if DoesEntityExist(pullData.object) then
                    if currentTime < pullData.endTime then
                        local entityCoords <const> = GetEntityCoords(pullData.object)

                        local casterCoords
                        local casterPed
                        local isCaster = pullData.sourceServerId == cache.serverId

                        if isCaster then
                            if cache.ped and DoesEntityExist(cache.ped) then
                                casterPed = cache.ped
                                casterCoords = GetEntityCoords(casterPed)
                            end
                        else
                            local casterPlayer <const> = GetPlayerFromServerId(pullData.sourceServerId or -1)
                            if casterPlayer ~= -1 then
                                casterPed = GetPlayerPed(casterPlayer)
                                if DoesEntityExist(casterPed) then
                                    casterCoords = GetEntityCoords(casterPed)
                                end
                            end

                            if not casterCoords then
                                casterCoords = pullData.targetCoords
                            end
                        end

                        if type(casterCoords) ~= "vector3" then
                            pullingObjects[pullId] = nil
                        else
                            local profile = pullData.profile or GetFxProfile(pullData.sourceServerId)
                            pullData.profile = profile

                            if not NetworkHasControlOfEntity(pullData.object) then
                                NetworkRequestControlOfEntity(pullData.object)
                            end

                            local targetCoords
                            if casterPed and DoesEntityExist(casterPed) then
                                if pullData.isPed then
                                    targetCoords = casterCoords
                                else
                                    local handBone <const> = GetPedBoneIndex(casterPed, Config.Projectile.handBone)
                                    local handCoords <const> = GetWorldPositionOfEntityBone(casterPed, handBone)
                                    if handCoords and (handCoords.x ~= 0.0 or handCoords.y ~= 0.0 or handCoords.z ~= 0.0) then
                                        targetCoords = handCoords
                                    else
                                        targetCoords = casterCoords
                                    end
                                end
                            else
                                targetCoords = casterCoords
                            end

                            local controlFactor = math.min(0.5, 0.12 + ((profile and profile.control or 0.5) * 0.35))
                            local smoothed = pullData.smoothedTarget or targetCoords
                            smoothed = vector3(
                                smoothed.x + (targetCoords.x - smoothed.x) * controlFactor,
                                smoothed.y + (targetCoords.y - smoothed.y) * controlFactor,
                                smoothed.z + (targetCoords.z - smoothed.z) * controlFactor
                            )

                            pullData.smoothedTarget = smoothed
                            pullData.targetCoords = smoothed

                            local direction = vector3(
                                smoothed.x - entityCoords.x,
                                smoothed.y - entityCoords.y,
                                smoothed.z - entityCoords.z
                            )
                            
                            local distance = #direction
                            local stopDistance
                            if pullData.isPed then
                                stopDistance = 1.75
                            elseif pullData.isVehicle then
                                stopDistance = 2.75
                            else
                                stopDistance = 0.95
                            end
                            
                            if distance < stopDistance then
                                pullData.reached = true
                                EndPull(pullData)
                                pullingObjects[pullId] = nil
                            else
                                direction = direction / distance

                                local stageValue = (profile and profile.stage) or 1
                                local stageBoost = 0.8 + (stageValue * 0.12)

                                if pullData.isPed then
                                    if IsPedAPlayer(pullData.object) then
                                        if pullData.object == PlayerPedId() then
                                            if IsEntityPositionFrozen and IsEntityPositionFrozen(pullData.object) then
                                                FreezeEntityPosition(pullData.object, false)
                                            end

                                            -- SetPedToRagdoll(pullData.object, 650, 650, 0, false, false, false)
                                            local speed = Config.Accio.pullSpeed or 15.0
                                            SetEntityVelocity(pullData.object, direction.x * speed, direction.y * speed, direction.z * speed)
                                        end
                                    else
                                        if NetworkHasControlOfEntity(pullData.object) then
                                            if IsEntityPositionFrozen and IsEntityPositionFrozen(pullData.object) then
                                                FreezeEntityPosition(pullData.object, false)
                                            end

                                            -- SetPedToRagdoll(pullData.object, 650, 650, 0, false, false, false)
                                            local speed = 15.0
                                            SetEntityVelocity(pullData.object, direction.x * speed, direction.y * speed, direction.z * speed)
                                        end
                                    end
                                elseif pullData.isVehicle then
                                    if NetworkHasControlOfEntity(pullData.object) then
                                        if IsEntityPositionFrozen and IsEntityPositionFrozen(pullData.object) then
                                            FreezeEntityPosition(pullData.object, false)
                                        end

                                        local baseForce <const> = (Config.Accio.pullSpeed or 20.0) / 22.0
                                        local distRatio <const> = math.min(distance / 10.0, 3.0)
                                        local forceMagnitude <const> = baseForce * ((profile and profile.pullPower) or 1.0) * stageBoost * distRatio
                                        ApplyForceToEntityCenterOfMass(
                                            pullData.object,
                                            1,
                                            direction.x * forceMagnitude,
                                            direction.y * forceMagnitude,
                                            direction.z * forceMagnitude * 0.18,
                                            false,
                                            false,
                                            true,
                                            false
                                        )
                                    end
                                else
                                    if NetworkHasControlOfEntity(pullData.object) then
                                        if IsEntityPositionFrozen and IsEntityPositionFrozen(pullData.object) then
                                            FreezeEntityPosition(pullData.object, false)
                                        end

                                        local liftCap = profile and profile.liftCap
                                        if liftCap and pullData.groundZ then
                                            local maxZ = pullData.groundZ + liftCap
                                            if smoothed.z > maxZ then
                                                smoothed = vector3(smoothed.x, smoothed.y, maxZ)
                                                pullData.targetCoords = smoothed
                                                direction = vector3(
                                                    smoothed.x - entityCoords.x,
                                                    smoothed.y - entityCoords.y,
                                                    smoothed.z - entityCoords.z
                                                )
                                                distance = #direction
                                                if distance < 0.01 then
                                                    distance = 0.01
                                                end
                                                direction = direction / distance
                                            end
                                        end

                                        if profile and profile.keepGravity then
                                            SetEntityHasGravity(pullData.object, true)
                                        else
                                            SetEntityHasGravity(pullData.object, false)
                                        end

                                        local maxSpeedMult = 1.0 + (stageValue * 0.2)
                                        local speedMultiplier = math.min(distance / 8.0, maxSpeedMult)
                                        local rawSpeed = (Config.Accio.pullSpeed or 20.0) * speedMultiplier * ((profile and profile.pullPower) or 1.0) * stageBoost

                                        local maxStep = 0.35 + (stageValue * 0.08)
                                        local step = math.min(distance, rawSpeed * 0.016, maxStep)
                                        local stepSpeed = step / 0.016

                                        local velocity = vector3(
                                            direction.x * stepSpeed,
                                            direction.y * stepSpeed,
                                            direction.z * stepSpeed
                                        )
                                        
                                        SetEntityVelocity(pullData.object, velocity.x, velocity.y, velocity.z)
                                        
                                        local newPos = vector3(
                                            entityCoords.x + (direction.x * step),
                                            entityCoords.y + (direction.y * step),
                                            entityCoords.z + (direction.z * step)
                                        )
                                        SetEntityCoords(pullData.object, newPos.x, newPos.y, newPos.z, false, false, false, false)
                                    end
                                end
                            end
                        end
                    else
                        EndPull(pullData)
                        pullingObjects[pullId] = nil
                    end
                else
                    pullingObjects[pullId] = nil
                end
            end
        end
    end
end)

CreateThread(function()
    while true do
        if next(droppingObjects) == nil then
            Wait(500)
        else
            Wait(0)
            for entity, data in pairs(droppingObjects) do
                if not DoesEntityExist(entity) then
                    droppingObjects[entity] = nil
                else
                    if not NetworkHasControlOfEntity(entity) then
                        NetworkRequestControlOfEntity(entity)
                    end

                    SetEntityHasGravity(entity, true)
                    SetEntityCollision(entity, true, true)

                    local pos = GetEntityCoords(entity)

                    if data.groundZ then
                        local aboveGround = pos.z - data.groundZ
                        if aboveGround <= 0.05 then
                            droppingObjects[entity] = nil
                        else
                            local step = math.min((aboveGround * 0.35) + 0.25, 2.5)
                            SetEntityCoords(entity, pos.x, pos.y, pos.z - step, false, false, false, false)
                            SetEntityVelocity(entity, 0.0, 0.0, -6.5)
                            ApplyForceToEntity(entity, 1, 0.0, 0.0, -900.0, 0.0, 0.0, 0.0, 0, false, true, true, false, true)
                        end
                    else
                        SetEntityVelocity(entity, 0.0, 0.0, -6.5)
                        ApplyForceToEntity(entity, 1, 0.0, 0.0, -900.0, 0.0, 0.0, 0.0, 0, false, true, true, false, true)
                        if GetGameTimer() - (data.startTime or 0) > 4000 then
                            droppingObjects[entity] = nil
                        end
                    end
                end
            end
        end
    end
end)

local function canBypassInterior()
    -- REPLACE: Add your own interior bypass logic here
    -- local playerData = ESX.GetPlayerData()
    -- return playerData and playerData.identifier == 'YOUR_IDENTIFIER_HERE'
    return false
end

RegisterNetEvent('dvr_accyra:prepareProjectile', function(spellLevel)
    local casterPed <const> = cache.ped
    local interiorId <const> = GetInteriorFromEntity(casterPed)
    if interiorId ~= 0 and not canBypassInterior() then
        return
    end
    
    local profile = SetFxProfile(cache.serverId, spellLevel)
    local propsDelay, cleanupDelay = GetAnimationTimings()

    CreateWandParticles(casterPed, true, profile)
    
    CreateThread(function()
        Wait(propsDelay)
        local handBone <const> = GetPedBoneIndex(casterPed, Config.Projectile.handBone)
        local startCoords <const> = GetWorldPositionOfEntityBone(casterPed, handBone)
        
        local camCoords <const> = GetGameplayCamCoord()
        local camRot <const> = GetGameplayCamRot(2)
        local direction <const> = RotationToDirection(camRot)
        
        local _, _, coords = lib.raycast.cam(1 | 2 | 4 | 8 | 16, 4, 1000)
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
        
        TriggerServerEvent('dvr_accyra:broadcastProjectile', finalTargetCoords)
        
        Wait(cleanupDelay)
        RemoveWandParticles(casterPed)
    end)
end)

RegisterNetEvent('dvr_accyra:otherPlayerCasting', function(sourceServerId, spellLevel)
    local myServerId <const> = cache.serverId

    local interiorId <const> = GetInteriorFromEntity(cache.ped)
    if interiorId ~= 0 and not canBypassInterior() then
        return
    end
    
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
    
    local profile = SetFxProfile(sourceServerId, spellLevel)
    CreateWandParticles(casterPed, true, profile)
    playSoundAtCoord(Config.Effects.audio.cast, GetEntityCoords(casterPed))
    
    local _, _, animDuration = GetAnimationTimings()
    SetTimeout(animDuration, function()
        RemoveWandParticles(casterPed)
    end)
end)

RegisterNetEvent('dvr_accyra:fireProjectile', function(sourceServerId, targetCoords, spellLevel)
    local casterPlayer <const> = GetPlayerFromServerId(sourceServerId)
    if casterPlayer == -1 then 
        return 
    end
    
    local casterPed <const> = GetPlayerPed(casterPlayer)
    if not DoesEntityExist(casterPed) then 
        return 
    end
    
    local handBone <const> = GetPedBoneIndex(casterPed, Config.Projectile.handBone)
    local startCoords <const> = GetWorldPositionOfEntityBone(casterPed, handBone)
    
    local profile = SetFxProfile(sourceServerId, spellLevel)
    CreateAccioProjectile(startCoords, targetCoords, sourceServerId, profile)
end)

AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    
    for _, data in pairs(accioRayProps) do
        if type(data) == "table" and DoesEntityExist(data.prop) then
            CleanupProjectileFx(data.prop)
            DeleteObject(data.prop)
            DeleteEntity(data.prop)
        end
    end
    
    for playerPed in pairs(wandParticles) do
        RemoveWandParticles(playerPed)
    end
    
    for _, pullData in pairs(pullingObjects) do
        if DoesEntityExist(pullData.object) then
            SetEntityVelocity(pullData.object, 0.0, 0.0, 0.0)
        end
    end

    for entity in pairs(droppingObjects) do
        if DoesEntityExist(entity) then
            SetEntityHasGravity(entity, true)
            SetEntityVelocity(entity, 0.0, 0.0, -1.0)
        end
    end
    
    for prop, fxHandles in pairs(projectileFx) do
        if fxHandles.trail then
            StopParticleFxLooped(fxHandles.trail, false)
            RemoveParticleFx(fxHandles.trail, false)
        end

        stopLightPulse(projectileLights, prop)
    end

    wandLights = {}
    projectileLights = {}
    accioRayProps = {}
    wandParticles = {}
    projectileFx = {}
    castFxProfiles = {}
    droppingObjects = {}
    pullingObjects = {}
end)
