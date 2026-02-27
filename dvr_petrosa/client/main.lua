---@diagnostic disable: undefined-global, trailing-space, unused-local, param-type-mismatch, missing-parameter
local petrosaRayProps = {}
local wandParticles = {}
local allParticles = {}

-- Native caching for performance
local RequestNamedPtfxAsset = RequestNamedPtfxAsset
local HasNamedPtfxAssetLoaded = HasNamedPtfxAssetLoaded
local UseParticleFxAsset = UseParticleFxAsset
local UseParticleFxAssetNextCall = UseParticleFxAssetNextCall
local StartParticleFxLoopedOnEntity = StartParticleFxLoopedOnEntity
local StartNetworkedParticleFxLoopedOnEntity = StartNetworkedParticleFxLoopedOnEntity
local StartParticleFxNonLoopedAtCoord = StartParticleFxNonLoopedAtCoord
local SetParticleFxLoopedColour = SetParticleFxLoopedColour
local SetParticleFxLoopedAlpha = SetParticleFxLoopedAlpha
local StopParticleFxLooped = StopParticleFxLooped
local RemoveParticleFx = RemoveParticleFx
local RemoveNamedPtfxAsset = RemoveNamedPtfxAsset
local DoesEntityExist = DoesEntityExist
local AddExplosion = AddExplosion
local ShakeGameplayCam = ShakeGameplayCam
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
local DeleteEntity = DeleteEntity
local DeleteObject = DeleteObject

--- Stop wand particle effect
local function StopWandTrail(playerPed)
    local handle = wandParticles[playerPed]
    if handle then
        StopParticleFxLooped(handle, false)
        RemoveParticleFx(handle, false)
        allParticles[handle] = nil
        wandParticles[playerPed] = nil
    end
end

--- Convert rotation to direction vector
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

--- Create wand glow effect (brown/earth color)
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
        handle = StartNetworkedParticleFxLoopedOnEntity('veh_light_clear', weapon, 0.95, 0.0, 0.1, 0.0, 0.0, 0.0, 0.7, false, false, false)
    else
        handle = StartParticleFxLoopedOnEntity('veh_light_clear', weapon, 0.95, 0.0, 0.1, 0.0, 0.0, 0.0, 0.7, false, false, false)
    end

    -- Brown/earth color for rock spell
    SetParticleFxLoopedColour(handle, 0.6, 0.4, 0.2, false)
    SetParticleFxLoopedAlpha(handle, 255)

    wandParticles[playerPed] = handle
    return handle
end

--- Create BIG launch burst effect at wand
local function CreateLaunchBurst(coords, rockCount)
    RequestNamedPtfxAsset('core')
    if not HasNamedPtfxAssetLoaded('core') then
        while not HasNamedPtfxAssetLoaded('core') do Wait(0) end
    end
    
    local scale = 0.3 + (rockCount * 0.15) -- Bigger burst for more rocks
    
    -- Earth burst effect
    UseParticleFxAssetNextCall('core')
    StartParticleFxNonLoopedAtCoord('ent_dst_rocks', coords.x, coords.y, coords.z, 0.0, 0.0, 0.0, scale, false, false, false)
    
    -- Dust puff
    UseParticleFxAssetNextCall('core')
    StartParticleFxNonLoopedAtCoord('exp_grd_bzgas_smoke', coords.x, coords.y, coords.z, 0.0, 0.0, 0.0, scale * 0.8, false, false, false)
    
    -- Launch sound
    PlaySoundFromCoord(-1, 'Explosion_Large', coords.x, coords.y, coords.z, 'FBI_05_SOUNDS', false, 30.0, false)
end

--- Attach magical aura to rock prop
local function AttachRockAura(rockProp)
    if not rockProp or not DoesEntityExist(rockProp) then
        return nil
    end

    RequestNamedPtfxAsset('core')
    while not HasNamedPtfxAssetLoaded('core') do
        Wait(0)
    end

    UseParticleFxAsset('core')
    
    -- Magical dust aura around the rock
    local auraHandle = StartParticleFxLoopedOnEntity('exp_grd_bzgas_smoke', rockProp, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.6, false, false, false)
    SetParticleFxLoopedColour(auraHandle, 0.5, 0.4, 0.3, false)
    SetParticleFxLoopedAlpha(auraHandle, 180.0)

    allParticles[auraHandle] = {
        createdTime = GetGameTimer(),
        type = 'rockAura'
    }

    return auraHandle
end

--- Create a single rock projectile
local function CreateSingleRock(startCoords, targetCoords, sourceServerId, spellLevel, rockIndex, totalRocks)
    -- Select random rock model
    local rockModels = Config.Projectile.rockModels or {'prop_rock_3_a'}
    local randomIndex = math.random(1, #rockModels)
    local rockModelName = rockModels[randomIndex]
    local rockModel <const> = GetHashKey(rockModelName)
    lib.requestModel(rockModel, 5000)
    
    -- Create the rock prop
    local rockProp <const> = CreateObject(rockModel, startCoords.x, startCoords.y, startCoords.z, false, false, false)
    SetEntityCollision(rockProp, false, false)
    SetEntityAsMissionEntity(rockProp, true, true)
    SetEntityCompletelyDisableCollision(rockProp, true, false)
    
    -- Calculate direction with spread for multiple rocks
    local baseDirection = vector3(
        targetCoords.x - startCoords.x,
        targetCoords.y - startCoords.y,
        targetCoords.z - startCoords.z
    )
    local distance = #baseDirection
    baseDirection = baseDirection / distance
    
    -- Apply spread angle for multiple rocks
    local spreadAngle = Config.Projectile.spreadAngle or 8.0
    local angleOffset = 0.0
    if totalRocks > 1 then
        -- Distribute rocks in a fan pattern
        local halfSpread = (totalRocks - 1) * spreadAngle / 2
        angleOffset = -halfSpread + (rockIndex - 1) * spreadAngle
    end
    
    -- Rotate direction by angleOffset (horizontal spread)
    local angleRad = math.rad(angleOffset)
    local direction = vector3(
        baseDirection.x * math.cos(angleRad) - baseDirection.y * math.sin(angleRad),
        baseDirection.x * math.sin(angleRad) + baseDirection.y * math.cos(angleRad),
        baseDirection.z
    )
    
    -- Recalculate target with new direction
    local adjustedTarget = startCoords + direction * distance
    
    local heading <const> = math.deg(math.atan2(direction.y, direction.x)) + 90.0
    local pitch <const> = -math.deg(math.asin(direction.z))
    
    SetEntityCoords(rockProp, startCoords.x, startCoords.y, startCoords.z, false, false, false, false)
    SetEntityRotation(rockProp, pitch, 0.0, heading, 2, true)
    
    -- Attach magical aura to the rock
    local auraHandle = AttachRockAura(rockProp)
    
    -- Calculate duration based on speed
    local speed = Config.Projectile.speed or 85.0
    local duration <const> = (distance / speed) * 1000.0
    local startTime <const> = GetGameTimer()
    local endTime <const> = startTime + duration
    
    petrosaRayProps[rockProp] = {
        prop = rockProp,
        startCoords = startCoords,
        targetCoords = adjustedTarget,
        direction = direction,
        distance = distance,
        startTime = startTime,
        endTime = endTime,
        heading = heading,
        pitch = pitch,
        sourceServerId = sourceServerId,
        auraHandle = auraHandle,
        spellLevel = spellLevel or 1,
        rotation = math.random(0, 360),
        lastTrailTime = 0,
        rockIndex = rockIndex,
        totalRocks = totalRocks
    }
end

--- Create rock projectile(s) - multiple based on level
local function CreatePetrosaProjectile(startCoords, targetCoords, sourceServerId, casterPed, spellLevel)
    StopWandTrail(casterPed)
    
    -- Get number of rocks based on level
    local rocksPerLevel = Config.Projectile.rocksPerLevel or {[1]=1, [2]=1, [3]=2, [4]=2, [5]=3}
    local rockCount = rocksPerLevel[spellLevel] or 1
    
    -- Launch burst effect (bigger for more rocks)
    CreateLaunchBurst(startCoords, rockCount)
    
    -- Create each rock with slight delay for dramatic effect
    for i = 1, rockCount do
        if i > 1 then
            SetTimeout((i - 1) * 80, function() -- 80ms delay between each rock
                CreateSingleRock(startCoords, targetCoords, sourceServerId, spellLevel, i, rockCount)
            end)
        else
            CreateSingleRock(startCoords, targetCoords, sourceServerId, spellLevel, i, rockCount)
        end
    end
end

-- Main update loop for rock projectiles
CreateThread(function()
    local rotationSpeed = Config.Projectile.rotationSpeed or 480.0
    local trailInterval = 40 -- Spawn trail every 40ms
    
    while true do
        Wait(0)
        
        local currentTime <const> = GetGameTimer()
        local deltaTime = 0.001 -- ~1ms per frame
        
        for propId, data in pairs(petrosaRayProps) do
            if type(data) == "table" and data.prop and DoesEntityExist(data.prop) then
                local progress = (currentTime - data.startTime) / (data.endTime - data.startTime)
                progress = math.min(progress, 1.0)
                
                -- In flight
                if progress < 1.0 then
                    -- Move rock
                    local newPos <const> = vector3(
                        data.startCoords.x + (data.direction.x * data.distance * progress),
                        data.startCoords.y + (data.direction.y * data.distance * progress),
                        data.startCoords.z + (data.direction.z * data.distance * progress)
                    )
                    
                    SetEntityCoords(data.prop, newPos.x, newPos.y, newPos.z, false, false, false, false)
                    
                    -- Rotate rock continuously (tumbling effect)
                    data.rotation = data.rotation + (rotationSpeed * deltaTime)
                    if data.rotation >= 360.0 then
                        data.rotation = data.rotation - 360.0
                    end
                    SetEntityRotation(data.prop, data.rotation, data.rotation * 0.7, data.heading, 2, true)
                    
                    -- Spawn trail particles periodically
                    if currentTime - data.lastTrailTime >= trailInterval then
                        data.lastTrailTime = currentTime

                        RequestNamedPtfxAsset('core')
                        if HasNamedPtfxAssetLoaded('core') then
                            -- Dust trail behind rock
                            UseParticleFxAssetNextCall('core')
                            StartParticleFxNonLoopedAtCoord(
                                'exp_grd_bzgas_smoke',
                                newPos.x - data.direction.x * 0.5,
                                newPos.y - data.direction.y * 0.5,
                                newPos.z - data.direction.z * 0.5,
                                0.0, 0.0, 0.0,
                                0.15, false, false, false
                            )

                            -- Magical spark trail (earth-colored sparks)
                            UseParticleFxAssetNextCall('core')
                            StartParticleFxNonLoopedAtCoord(
                                'ent_dst_electrical_box',
                                newPos.x - data.direction.x * 0.8,
                                newPos.y - data.direction.y * 0.8,
                                newPos.z - data.direction.z * 0.8,
                                0.0, 0.0, 0.0,
                                0.08, false, false, false
                            )

                            -- Ground dust kick-up effect
                            UseParticleFxAssetNextCall('core')
                            StartParticleFxNonLoopedAtCoord(
                                'ent_dst_gen_grnd_sml',
                                newPos.x - data.direction.x * 0.2,
                                newPos.y - data.direction.y * 0.2,
                                newPos.z - 0.1, -- Slightly below ground
                                0.0, 0.0, 0.0,
                                0.05, false, false, false
                            )
                        end
                    end
                end
                
                -- Impact
                if progress >= 1.0 then
                    local impactPos = data.targetCoords
                    local level = data.spellLevel or 1

                    -- Check if impact is on caster (don't explode on yourself!)
                    local casterPlayer = GetPlayerFromServerId(data.sourceServerId)
                    local casterPed = GetPlayerPed(casterPlayer)
                    local casterCoords = GetEntityCoords(casterPed)
                    local distanceToCaster = #(impactPos - casterCoords)

                    -- Only explode if not too close to caster (minimum safe distance)
                    local minSafeDistance = 2.0 -- 2 meters minimum distance
                    local shouldExplode = distanceToCaster >= minSafeDistance

                    if shouldExplode then
                        -- Stop aura particle
                        if data.auraHandle then
                            StopParticleFxLooped(data.auraHandle, false)
                            RemoveParticleFx(data.auraHandle, false)
                            allParticles[data.auraHandle] = nil
                        end

                        -- Notify server for damage (only the caster triggers this, only once per barrage)
                        local myServerId = GetPlayerServerId(PlayerId())
                        if data.sourceServerId == myServerId and data.rockIndex == 1 then
                            TriggerServerEvent('dvr_petrosa:applyDamage', impactPos, level)
                        end
                    
                    -- ==========================================
                    -- SPECTACULAR ROCK EXPLOSION EFFECTS
                    -- ==========================================
                    
                    -- Scale effects based on level
                    local impactScale = 1.0 + (level * 0.2)
                    
                    -- 1. Main debris falling effect (FBI stairs collapse effect)
                    local debrisConfig = Config.Impact and Config.Impact.debris
                    if debrisConfig then
                        RequestNamedPtfxAsset(debrisConfig.dict)
                        local timeout = 0
                        while not HasNamedPtfxAssetLoaded(debrisConfig.dict) and timeout < 50 do
                            Wait(10)
                            timeout = timeout + 1
                        end
                        if HasNamedPtfxAssetLoaded(debrisConfig.dict) then
                            UseParticleFxAssetNextCall(debrisConfig.dict)
                            StartParticleFxNonLoopedAtCoord(
                                debrisConfig.particle,
                                impactPos.x, impactPos.y, impactPos.z,
                                0.0, 0.0, 0.0,
                                (debrisConfig.scale or 1.5) * impactScale, false, false, false
                            )
                        end
                    end
                    
                    -- 2. Multiple rock debris explosions
                    RequestNamedPtfxAsset('core')
                    if HasNamedPtfxAssetLoaded('core') then
                        -- Big rock chunks flying UP
                        UseParticleFxAssetNextCall('core')
                        StartParticleFxNonLoopedAtCoord(
                            'ent_dst_rocks',
                            impactPos.x, impactPos.y, impactPos.z,
                            0.0, 0.0, 0.0,
                            2.0 * impactScale, false, false, false
                        )
                        
                        -- Secondary rock explosion (offset)
                        UseParticleFxAssetNextCall('core')
                        StartParticleFxNonLoopedAtCoord(
                            'ent_dst_rocks',
                            impactPos.x + 0.3, impactPos.y + 0.3, impactPos.z + 0.5,
                            0.0, 0.0, 0.0,
                            1.5 * impactScale, false, false, false
                        )
                        
                        -- Third rock debris wave
                        UseParticleFxAssetNextCall('core')
                        StartParticleFxNonLoopedAtCoord(
                            'ent_dst_rocks',
                            impactPos.x - 0.3, impactPos.y - 0.3, impactPos.z + 0.2,
                            0.0, 0.0, 0.0,
                            1.2 * impactScale, false, false, false
                        )
                        
                        -- Large dust cloud
                        UseParticleFxAssetNextCall('core')
                        StartParticleFxNonLoopedAtCoord(
                            'exp_grd_bzgas_smoke',
                            impactPos.x, impactPos.y, impactPos.z,
                            0.0, 0.0, 0.0,
                            2.5 * impactScale, false, false, false
                        )
                        
                        -- Ground impact dust ring
                        UseParticleFxAssetNextCall('core')
                        StartParticleFxNonLoopedAtCoord(
                            'ent_dst_gen_grnd_sml',
                            impactPos.x, impactPos.y, impactPos.z,
                            0.0, 0.0, 0.0,
                            1.5 * impactScale, false, false, false
                        )
                    end
                    
                    -- 3. REAL EXPLOSION for the impact (dramatic!)
                    AddExplosion(impactPos.x, impactPos.y, impactPos.z, 2, 0.0, true, false, 0.5 * impactScale, false)
                    
                    -- 4. Heavy impact sounds
                    PlaySoundFromCoord(-1, 'Explosion_Large', impactPos.x, impactPos.y, impactPos.z, 'FBI_05_SOUNDS', false, 100.0, false)
                    PlaySoundFromCoord(-1, 'INTELLI_BARRIER_HIT', impactPos.x, impactPos.y, impactPos.z, 'DLC_SECURITY_TURRET_SOUNDS', false, 80.0, false)
                    
                    -- 5. Camera shake (reduced intensity for comfort)
                    local playerCoords <const> = GetEntityCoords(cache.ped)
                    local distToImpact = #(playerCoords - impactPos)
                    
                        if distToImpact < 15.0 then
                            local intensity = math.max(0.05, (0.15 + level * 0.03) * (1.0 - (distToImpact / 15.0)))
                            ShakeGameplayCam('SMALL_EXPLOSION_SHAKE', intensity)
                        end
                    else
                        -- Impact too close to caster - just play a small effect without damage/explosion
                        RequestNamedPtfxAsset('core')
                        if HasNamedPtfxAssetLoaded('core') then
                            UseParticleFxAssetNextCall('core')
                            StartParticleFxNonLoopedAtCoord(
                                'exp_grd_bzgas_smoke',
                                impactPos.x, impactPos.y, impactPos.z,
                                0.0, 0.0, 0.0,
                                0.3, false, false, false
                            )
                        end
                    end

                    -- Stop aura particle (always do this)
                    if data.auraHandle then
                        StopParticleFxLooped(data.auraHandle, false)
                        RemoveParticleFx(data.auraHandle, false)
                        allParticles[data.auraHandle] = nil
                    end

                    -- Delete the rock prop (always do this)
                    if DoesEntityExist(data.prop) then
                        SetEntityVisible(data.prop, false, false)
                        SetEntityCoords(data.prop, 0.0, 0.0, -5000.0, false, false, false, false)
                        SetEntityAsMissionEntity(data.prop, false, false)
                        DeleteEntity(data.prop)
                        DeleteObject(data.prop)
                    end

                    petrosaRayProps[propId] = nil
                end
            else
                -- Cleanup invalid entry
                petrosaRayProps[propId] = nil
            end
        end
    end
end)

-- Periodic cleanup
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

--- Event: Prepare projectile
RegisterNetEvent('dvr_petrosa:prepareProjectile', function(spellLevel)
    local casterPed <const> = cache.ped
    
    CreateWandParticles(casterPed, true)
    
    CreateThread(function()
        -- Use configurable projectile delay (for animation timing)
        local castDelay = Config.Animation.projectileDelay or 100
        
        if castDelay < 0 then castDelay = 0 end
        Wait(castDelay)
        
        local handBone <const> = GetPedBoneIndex(casterPed, 28422)
        local startCoords <const> = GetWorldPositionOfEntityBone(casterPed, handBone)
        
        local camCoords <const> = GetGameplayCamCoord()
        local camRot <const> = GetGameplayCamRot(2)
        local direction <const> = RotationToDirection(camRot)
        
        local hit, entityHit, coords = lib.raycast.cam(1 | 2 | 4 | 8 | 16, 4, 1000)
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
        
        TriggerServerEvent('dvr_petrosa:broadcastProjectile', finalTargetCoords, spellLevel)
        
        Wait(800)
        StopWandTrail(casterPed)
    end)
end)

--- Event: Other player casting
RegisterNetEvent('dvr_petrosa:otherPlayerCasting', function(sourceServerId)
    local myServerId <const> = GetPlayerServerId(PlayerId())
    
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
    
    CreateWandParticles(casterPed, true)
    
    SetTimeout(3000, function()
        StopWandTrail(casterPed)
    end)
end)

--- Event: Fire projectile
RegisterNetEvent('dvr_petrosa:fireProjectile', function(sourceServerId, targetCoords, spellLevel)
    local casterPlayer <const> = GetPlayerFromServerId(sourceServerId)
    if casterPlayer == -1 then 
        return 
    end
    
    local casterPed <const> = GetPlayerPed(casterPlayer)
    if not DoesEntityExist(casterPed) then 
        return 
    end
    
    local handBone <const> = GetPedBoneIndex(casterPed, 28422)
    local startCoords <const> = GetWorldPositionOfEntityBone(casterPed, handBone)
    
    CreatePetrosaProjectile(startCoords, targetCoords, sourceServerId, casterPed, spellLevel)
end)

--- Cleanup on stop
AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    
    -- Clean up all rock props
    for propId, data in pairs(petrosaRayProps) do
        if type(data) == "table" then
            if data.auraHandle then
                StopParticleFxLooped(data.auraHandle, false)
                RemoveParticleFx(data.auraHandle, false)
            end
            
            if data.prop and DoesEntityExist(data.prop) then
                SetEntityVisible(data.prop, false, false)
                SetEntityCoords(data.prop, 0.0, 0.0, -5000.0, false, false, false, false)
                DeleteEntity(data.prop)
                DeleteObject(data.prop)
            end
        end
    end
    petrosaRayProps = {}
    
    -- Clean up wand particles
    for ped, handle in pairs(wandParticles) do
        StopParticleFxLooped(handle, false)
        RemoveParticleFx(handle, false)
    end
    wandParticles = {}
    
    -- Clean up any looped particles
    for particleHandle, particleData in pairs(allParticles) do
        StopParticleFxLooped(particleHandle, false)
        RemoveParticleFx(particleHandle, false)
    end
    allParticles = {}
    
    RemoveNamedPtfxAsset('core')
end)
