---@diagnostic disable: undefined-global, trailing-space, unused-local, param-type-mismatch, missing-parameter
local activeWalls = {}
local wandParticles = {}
local allParticles = {}

-- Native caching for performance
local RequestNamedPtfxAsset = RequestNamedPtfxAsset
local HasNamedPtfxAssetLoaded = HasNamedPtfxAssetLoaded
local UseParticleFxAsset = UseParticleFxAsset
local UseParticleFxAssetNextCall = UseParticleFxAssetNextCall
local StartParticleFxLoopedOnEntity = StartParticleFxLoopedOnEntity
local StartParticleFxLoopedAtCoord = StartParticleFxLoopedAtCoord
local StartParticleFxNonLoopedAtCoord = StartParticleFxNonLoopedAtCoord
local SetParticleFxLoopedColour = SetParticleFxLoopedColour
local SetParticleFxLoopedAlpha = SetParticleFxLoopedAlpha
local SetParticleFxLoopedScale = SetParticleFxLoopedScale
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
local SetEntityAlpha = SetEntityAlpha
local GetPlayerFromServerId = GetPlayerFromServerId
local GetPlayerPed = GetPlayerPed
local GetPlayerServerId = GetPlayerServerId
local PlayerId = PlayerId
local GetHashKey = GetHashKey
local CreateObject = CreateObject
local GetGroundZFor_3dCoord = GetGroundZFor_3dCoord
local ShakeGameplayCam = ShakeGameplayCam

--- Convert camera rotation to direction vector
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

--- Stop and cleanup wand particle effect
local function StopWandTrail(playerPed)
    local handle = wandParticles[playerPed]
    if handle then
        StopParticleFxLooped(handle, false)
        RemoveParticleFx(handle, false)
        allParticles[handle] = nil
        wandParticles[playerPed] = nil
    end
end

--- Create glowing wand effect during cast
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
        handle = StartParticleFxLoopedOnEntity('veh_light_clear', weapon, 0.95, 0.0, 0.1, 0.0, 0.0, 0.0, 0.6, false, false, false)
    else
        handle = StartParticleFxLoopedOnEntity('veh_light_clear', weapon, 0.95, 0.0, 0.1, 0.0, 0.0, 0.0, 0.6, false, false, false)
    end

    -- Blue energy color for wall spell
    SetParticleFxLoopedColour(handle, 0.2, 0.6, 1.0, false)
    SetParticleFxLoopedAlpha(handle, 255)

    wandParticles[playerPed] = handle
    allParticles[handle] = { createdTime = GetGameTimer(), type = 'wandGlow' }
    return handle
end

--- Play wall sound at location
local function PlayWallSound(coords, type)
    local soundConfig = Config.Sounds[type]
    if not soundConfig or not soundConfig.url or soundConfig.url == '' then return end

    local soundId = ('wallis_%s_%d'):format(type, GetGameTimer())
    pcall(function()
        -- REPLACE WITH YOUR SOUND SYSTEM
        -- exports['lo_audio']:playSound({
        -- id = soundId,
        -- url = soundConfig.url,
        -- volume = soundConfig.volume or 0.8,
        -- loop = false,
        -- spatial = true,
        -- pos = coords,
        -- distance = 30.0,
        -- category = 'spell'
        -- })
    end)
end

--- Create wall entity and visual effects
local function CreateWall(targetCoords, direction, level, sourceServerId)
    local levelConfig = Config.Levels[level] or Config.Levels[1]
    local wallLength = levelConfig.length or 5.0
    local wallHeight = levelConfig.height or 3.0
    local duration = levelConfig.duration or 5000

    -- Get ground Z coordinate
    local _, groundZ = GetGroundZFor_3dCoord(targetCoords.x, targetCoords.y, targetCoords.z + 10.0, false)
    local wallCenter = vector3(targetCoords.x, targetCoords.y, groundZ)

    -- Calculate wall orientation (perpendicular to camera direction)
    local wallDir = vector3(-direction.y, direction.x, 0.0)
    local wallDirLength = math.sqrt(wallDir.x * wallDir.x + wallDir.y * wallDir.y)
    if wallDirLength > 0.001 then
        wallDir = vector3(wallDir.x / wallDirLength, wallDir.y / wallDirLength, 0.0)
    else
        wallDir = vector3(1.0, 0.0, 0.0)
    end

    -- Calculate wall heading (perpendicular to direction)
    local heading = math.deg(math.atan2(wallDir.y, wallDir.x))

    -- Request rock model (visual)
    local rockModel = GetHashKey(Config.Effects.wallModel)
    lib.requestModel(rockModel, 5000)
    
    -- Request collision model (invisible solid props)
    local collisionModel = GetHashKey(Config.Effects.collisionModel)
    lib.requestModel(collisionModel, 5000)

    -- Calculate how many rocks we need horizontally
    local rockWidth = Config.Effects.fenceWidth or 2.0
    local rockHeight = Config.Effects.fenceHeight or 1.2
    local rockRows = Config.Effects.rockRows or 3
    local rockCount = math.max(1, math.ceil(wallLength / rockWidth))
    local actualSpacing = wallLength / rockCount

    -- Create rock wall (stacked rows)
    local wallSegments = {}
    
    for row = 1, rockRows do
        -- Offset every other row for a natural stacked look
        local rowOffset = (row % 2 == 0) and (actualSpacing * 0.5) or 0
        
        for col = 1, rockCount do
            -- Calculate position for this rock
            local offset = (col - 0.5 - rockCount * 0.5) * actualSpacing + rowOffset
            local rockPos = vector3(
                wallCenter.x + wallDir.x * offset,
                wallCenter.y + wallDir.y * offset,
                wallCenter.z + (row - 1) * rockHeight
            )

            -- Create rock prop starting below ground (will rise up)
            local startZ = rockPos.z - (rockRows * rockHeight) - 1.0
            local targetZ = rockPos.z
            
            local rockProp = CreateObject(rockModel, rockPos.x, rockPos.y, startZ, false, false, false)
            
            SetEntityCollision(rockProp, true, true)
            SetEntityAsMissionEntity(rockProp, true, true)
            FreezeEntityPosition(rockProp, true)
            SetEntityInvincible(rockProp, true)
            
            -- Rotate rock to be perpendicular to view direction + random rotation for variety
            local randomRot = math.random(-15, 15)
            SetEntityRotation(rockProp, 0.0, 0.0, heading + randomRot, 2, true)
            
            SetEntityVisible(rockProp, true, false)
            SetEntityAlpha(rockProp, 255, false)
            
            table.insert(wallSegments, {
                prop = rockProp,
                collisionProps = {},
                startZ = startZ,
                targetZ = targetZ,
                basePos = rockPos,
                riseStartTime = GetGameTimer(),
                riseDuration = Config.Wall.riseDuration or 800
            })
        end
    end

    -- Create INVISIBLE COLLISION PROPS (stacked for full height coverage)
    local collisionLayers = math.max(2, math.ceil(wallHeight / 2.0))
    for layer = 1, collisionLayers do
        for col = 1, rockCount do
            local offset = (col - 0.5 - rockCount * 0.5) * actualSpacing
            local layerZ = wallCenter.z + ((layer - 0.5) * (wallHeight / collisionLayers))
            
            local collisionProp = CreateObject(collisionModel, wallCenter.x + wallDir.x * offset, wallCenter.y + wallDir.y * offset, layerZ - wallHeight - 1.0, false, false, false)
            
            SetEntityCollision(collisionProp, false, false)
            SetEntityAsMissionEntity(collisionProp, true, true)
            SetEntityCompletelyDisableCollision(collisionProp, true, true)
            FreezeEntityPosition(collisionProp, true)
            SetEntityInvincible(collisionProp, true)
            SetEntityProofs(collisionProp, true, true, true, true, true, true, true, true)
            SetEntityRotation(collisionProp, 0.0, 0.0, heading, 2, true)
            SetEntityVisible(collisionProp, false, false)
            SetEntityAlpha(collisionProp, 0, false)
            
            -- Add to first segment for cleanup
            if wallSegments[1] then
                table.insert(wallSegments[1].collisionProps, {
                    prop = collisionProp,
                    startZ = layerZ - wallHeight - 1.0,
                    targetZ = layerZ,
                    collisionEnabled = false
                })
            end
        end
    end


    -- Create magical particle effects on the fence (REDUCED)
    RequestNamedPtfxAsset('core')
    while not HasNamedPtfxAssetLoaded('core') do
        Wait(0)
    end
    
    RequestNamedPtfxAsset('scr_rcbarry2')
    while not HasNamedPtfxAssetLoaded('scr_rcbarry2') do
        Wait(0)
    end

    local particleHandles = {}
    
    -- Pop effect when wall appears (reduced to 2-3 points)
    local popSegments = math.min(2, math.max(1, math.floor(rockCount / 2)))
    for pop = 1, popSegments do
        local popOffset = (pop - 0.5 - popSegments * 0.5) * (wallLength / popSegments)
        
        UseParticleFxAssetNextCall('scr_rcbarry2')
        StartParticleFxNonLoopedAtCoord(
            'scr_clown_appears',
            wallCenter.x + wallDir.x * popOffset,
            wallCenter.y + wallDir.y * popOffset,
            wallCenter.z + wallHeight * 0.3,
            0.0, 0.0, 0.0,
            1.8, false, false, false
        )
    end
    
    -- Energy burst on rise (just at center)
    UseParticleFxAssetNextCall('core')
    StartParticleFxNonLoopedAtCoord(
        'ent_amb_elec_fire_sp',
        wallCenter.x, wallCenter.y, wallCenter.z,
        0.0, 0.0, 0.0,
        1.5, false, false, false
    )

    -- Add magical glow particles (REDUCED - less segments)
    local particleSegments = math.max(2, math.ceil(wallLength / 3.0))  -- Reduced spacing
    
    for i = 1, particleSegments do
        local offsetX = (i - 0.5 - particleSegments * 0.5) * (wallLength / particleSegments)
        
        local particlePos = vector3(
            wallCenter.x + wallDir.x * offsetX,
            wallCenter.y + wallDir.y * offsetX,
            wallCenter.z + wallHeight * 0.5
        )

        -- Just electric crackle (removed smoke for cleaner look)
        UseParticleFxAssetNextCall('core')
        local energyHandle = StartParticleFxLoopedAtCoord(
            'ent_amb_elec_crackle_sp',
            particlePos.x, particlePos.y, particlePos.z,
            0.0, 0.0, 0.0,
            1.0, false, false, false  -- Reduced scale
        )
        
        if energyHandle then
            SetParticleFxLoopedColour(energyHandle, 0.3, 0.7, 1.0, false)
            SetParticleFxLoopedAlpha(energyHandle, 180)  -- Slightly transparent
            table.insert(particleHandles, energyHandle)
            allParticles[energyHandle] = { createdTime = GetGameTimer(), type = 'wallEnergy' }
        end
    end

    -- Create wall data entry
    local wallId = GetGameTimer()
    activeWalls[wallId] = {
        segments = wallSegments,
        center = wallCenter,
        direction = wallDir,
        length = wallLength,
        height = wallHeight,
        heading = heading,
        sourceServerId = sourceServerId,
        createTime = GetGameTimer(),
        endTime = GetGameTimer() + duration,
        particleHandles = particleHandles,
        level = level,
        lastAmbientParticle = GetGameTimer(),  -- For continuous ambient particles
        isDescending = false,                   -- Flag for descent animation
        descendStartTime = nil                  -- When descent animation started
    }

    -- Play rise sound
    PlayWallSound(wallCenter, 'rise')

    return wallId
end

--- Cleanup wall and all its effects
local function CleanupWall(wallId)
    local wallData = activeWalls[wallId]
    if not wallData then return end

    -- Remove particle effects
    if wallData.particleHandles then
        for _, handle in ipairs(wallData.particleHandles) do
            if handle then
                StopParticleFxLooped(handle, false)
                RemoveParticleFx(handle, false)
                allParticles[handle] = nil
            end
        end
    end

    -- Remove wall segments and collision props
    if wallData.segments then
        for _, segment in ipairs(wallData.segments) do
            -- Remove collision props
            if segment.collisionProps then
                for _, collisionData in ipairs(segment.collisionProps) do
                    if collisionData.prop and DoesEntityExist(collisionData.prop) then
                        SetEntityVisible(collisionData.prop, false, false)
                        SetEntityCoords(collisionData.prop, 0.0, 0.0, -5000.0, false, false, false, false)
                        DeleteEntity(collisionData.prop)
                        DeleteObject(collisionData.prop)
                    end
                end
            end
            
            -- Remove fence prop
            if segment.prop and DoesEntityExist(segment.prop) then
                SetEntityVisible(segment.prop, false, false)
                SetEntityCoords(segment.prop, 0.0, 0.0, -5000.0, false, false, false, false)
                Wait(50)
                DeleteEntity(segment.prop)
                DeleteObject(segment.prop)
            end
        end
    end

    activeWalls[wallId] = nil
end

--- Main update loop for walls
CreateThread(function()
    while true do
        Wait(0)
        local currentTime = GetGameTimer()
        local wallsToRemove = {}
        local descendDuration = 800  -- Same duration as rise

        for wallId, wallData in pairs(activeWalls) do
            -- Check if wall should start descending
            if currentTime >= wallData.endTime and not wallData.isDescending then
                -- Start descent animation
                wallData.isDescending = true
                wallData.descendStartTime = currentTime
                
                -- Play descend sound
                PlayWallSound(wallData.center, 'descend')
                
                -- Stop ambient particles
                wallData.lastAmbientParticle = math.huge
                
                -- Clean up looped particles
                if wallData.particleHandles then
                    for _, handle in ipairs(wallData.particleHandles) do
                        if handle then
                            StopParticleFxLooped(handle, false)
                            RemoveParticleFx(handle, false)
                            allParticles[handle] = nil
                        end
                    end
                    wallData.particleHandles = {}
                end
            end
            
            -- Check if descent animation is complete
            if wallData.isDescending and currentTime >= wallData.descendStartTime + descendDuration then
                -- Descent complete, remove wall
                table.insert(wallsToRemove, wallId)
            elseif wallData.isDescending then
                -- Animate descent into ground
                local descendProgress = math.min(
                    (currentTime - wallData.descendStartTime) / descendDuration,
                    1.0
                )
                
                if wallData.segments then
                    for _, segment in ipairs(wallData.segments) do
                        if segment.prop and DoesEntityExist(segment.prop) then
                            -- Ease-in descent
                            local easeProgress = descendProgress * descendProgress
                            local descendZ = segment.targetZ - (segment.targetZ - segment.startZ) * easeProgress
                            local coords = GetEntityCoords(segment.prop)
                            SetEntityCoords(segment.prop, coords.x, coords.y, descendZ, false, false, false, false)
                            
                            -- Fade out during descent
                            local alpha = math.floor(255 * (1.0 - descendProgress))
                            SetEntityAlpha(segment.prop, alpha, false)
                        end
                        
                        -- Animate collision props descent too
                        if segment.collisionProps then
                            for _, collisionData in ipairs(segment.collisionProps) do
                                if collisionData.prop and DoesEntityExist(collisionData.prop) then
                                    local easeProgress = descendProgress * descendProgress
                                    local collisionDescendZ = collisionData.targetZ - (collisionData.targetZ - collisionData.startZ) * easeProgress
                                    local collisionCoords = GetEntityCoords(collisionData.prop)
                                    SetEntityCoords(collisionData.prop, collisionCoords.x, collisionCoords.y, collisionDescendZ, false, false, false, false)
                                    
                                    -- Disable collision during descent to prevent pushing player
                                    if collisionData.collisionEnabled then
                                        SetEntityCollision(collisionData.prop, false, false)
                                        SetEntityCompletelyDisableCollision(collisionData.prop, true, true)
                                        collisionData.collisionEnabled = false
                                    end
                                end
                            end
                        end
                    end
                end
            else
                -- Animate fence segments rising from ground
                if wallData.segments then
                    for _, segment in ipairs(wallData.segments) do
                        if segment.prop and DoesEntityExist(segment.prop) then
                            local riseProgress = math.min(
                                (currentTime - segment.riseStartTime) / segment.riseDuration,
                                1.0
                            )

                            if riseProgress < 1.0 then
                                -- Fence is still rising (smooth animation with ease-out)
                                local easeProgress = riseProgress * riseProgress  -- Ease out
                                local currentZ = segment.startZ + (segment.targetZ - segment.startZ) * easeProgress
                                local coords = GetEntityCoords(segment.prop)
                                SetEntityCoords(segment.prop, coords.x, coords.y, currentZ, false, false, false, false)
                                
                                -- Animate collision props too
                                if segment.collisionProps then
                                    for _, collisionData in ipairs(segment.collisionProps) do
                                        if collisionData.prop and DoesEntityExist(collisionData.prop) then
                                            local collisionZ = collisionData.startZ + (collisionData.targetZ - collisionData.startZ) * easeProgress
                                            local collisionCoords = GetEntityCoords(collisionData.prop)
                                            SetEntityCoords(collisionData.prop, collisionCoords.x, collisionCoords.y, collisionZ, false, false, false, false)
                                            
                                            -- Keep collision DISABLED during rise to prevent pushing player up
                                            SetEntityCollision(collisionData.prop, false, false)
                                            SetEntityCompletelyDisableCollision(collisionData.prop, true, true)
                                            FreezeEntityPosition(collisionData.prop, true)
                                        end
                                    end
                                end
                                
                                -- Keep fence collision enabled during rise
                                SetEntityCollision(segment.prop, true, true)
                                FreezeEntityPosition(segment.prop, true)
                            else
                                -- Fence fully risen, ensure it's at final position
                                local coords = GetEntityCoords(segment.prop)
                                if math.abs(coords.z - segment.targetZ) > 0.1 then
                                    SetEntityCoords(segment.prop, coords.x, coords.y, segment.targetZ, false, false, false, false)
                                end
                                
                                -- Ensure collision props are at final position
                                if segment.collisionProps then
                                    for _, collisionData in ipairs(segment.collisionProps) do
                                        if collisionData.prop and DoesEntityExist(collisionData.prop) then
                                            local collisionCoords = GetEntityCoords(collisionData.prop)
                                            if math.abs(collisionCoords.z - collisionData.targetZ) > 0.1 then
                                                SetEntityCoords(collisionData.prop, collisionCoords.x, collisionCoords.y, collisionData.targetZ, false, false, false, false)
                                            end
                                            
                                            -- ENABLE collision only when fully risen to prevent pushing player up during rise
                                            if not collisionData.collisionEnabled then
                                                SetEntityCollision(collisionData.prop, true, true)
                                                SetEntityCompletelyDisableCollision(collisionData.prop, false, true)
                                                collisionData.collisionEnabled = true
                                            end
                                            FreezeEntityPosition(collisionData.prop, true)
                                            SetEntityProofs(collisionData.prop, true, true, true, true, true, true, true, true)
                                        end
                                    end
                                end
                                
                                -- Ensure fence collision stays enabled
                                SetEntityCollision(segment.prop, true, true)
                                FreezeEntityPosition(segment.prop, true)
                            end
                        end
                    end
                end
                
                -- Spawn continuous ambient particles around the wall (only if not descending)
                if not wallData.isDescending and currentTime - wallData.lastAmbientParticle > 300 then  -- Every 300ms
                    wallData.lastAmbientParticle = currentTime
                    
                    -- Spawn small magical sparkles at random positions along the wall
                    local randomSegments = 2  -- Spawn 2 sparkles at a time
                    for i = 1, randomSegments do
                        local randomOffset = (math.random() - 0.5) * wallData.length
                        local randomHeight = math.random() * wallData.height
                        
                        local sparklePos = vector3(
                            wallData.center.x + wallData.direction.x * randomOffset,
                            wallData.center.y + wallData.direction.y * randomOffset,
                            wallData.center.z + randomHeight
                        )
                        
                        -- Small sparkle particles
                        UseParticleFxAssetNextCall('core')
                        StartParticleFxNonLoopedAtCoord(
                            'ent_dst_elec_fire_sp',  -- Small electric sparkle
                            sparklePos.x, sparklePos.y, sparklePos.z,
                            0.0, 0.0, 0.0,
                            0.3,  -- Small scale
                            false, false, false
                        )
                    end
                end
            end
        end

        -- Remove expired walls
        for _, wallId in ipairs(wallsToRemove) do
            CleanupWall(wallId)
        end
    end
end)

--- Periodic cleanup of orphaned particles
CreateThread(function()
    while true do
        Wait(30000)
        local currentTime = GetGameTimer()
        local toRemove = {}

        for particleHandle, particleData in pairs(allParticles) do
            if currentTime - (particleData.createdTime or 0) > 30000 then
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

--- Calculate target position from camera raycast
local function FindTargetCoords()
    local camCoords = GetGameplayCamCoord()
    local camRot = GetGameplayCamRot(2)
    local direction = RotationToDirection(camRot)
    local maxDist = 50.0

    local hit, entityHit, coords = lib.raycast.cam(1 | 2 | 4 | 8 | 16, 4, maxDist)

    if coords and (coords.x ~= 0.0 or coords.y ~= 0.0 or coords.z ~= 0.0) then
        return coords, direction
    end

    return vector3(
        camCoords.x + direction.x * maxDist,
        camCoords.y + direction.y * maxDist,
        camCoords.z + direction.z * maxDist
    ), direction
end

--- Event: Local player starts casting
RegisterNetEvent('th_wallis:prepareCast', function(spellLevel)
    local casterPed = cache.ped

    CreateWandParticles(casterPed, true)

    CreateThread(function()
        local duration = Config.Animation.duration or 2000
        local speed = Config.Animation.speedMultiplier or 1.5
        local realDuration = duration / speed
        local castDelay = math.floor(realDuration * 0.6)

        if castDelay < 0 then castDelay = 0 end
        Wait(castDelay)

        local targetCoords, direction = FindTargetCoords()

        -- Send to server to broadcast the wall creation
        TriggerServerEvent('th_wallis:broadcastWall', targetCoords, direction, spellLevel)

        Wait(800)
        StopWandTrail(casterPed)
    end)
end)

--- Event: Another player is casting (for visual sync)
RegisterNetEvent('th_wallis:otherPlayerCasting', function(sourceServerId)
    local myServerId = GetPlayerServerId(PlayerId())
    if sourceServerId == myServerId then return end

    local casterPlayer = GetPlayerFromServerId(sourceServerId)
    if casterPlayer == -1 then return end

    local casterPed = GetPlayerPed(casterPlayer)
    if not DoesEntityExist(casterPed) then return end

    CreateWandParticles(casterPed, true)

    SetTimeout(3000, function()
        StopWandTrail(casterPed)
    end)
end)

--- Event: Spawn wall (all clients see it)
RegisterNetEvent('th_wallis:spawnWall', function(sourceServerId, targetCoords, direction, spellLevel)
    if not targetCoords or not direction then return end

    local level = spellLevel or 1
    if level < 1 then level = 1 end
    if level > 5 then level = 5 end

    CreateWall(targetCoords, direction, level, sourceServerId)

    -- Camera shake on wall creation
    local playerCoords = GetEntityCoords(cache.ped)
    local distance = #(playerCoords - targetCoords)
    if distance < 20.0 then
        local intensity = math.max(0.1, 0.3 * (1.0 - distance / 20.0))
        ShakeGameplayCam('SMALL_EXPLOSION_SHAKE', intensity)
    end
end)

--- Cleanup on resource stop
AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end

    for wallId, _ in pairs(activeWalls) do
        CleanupWall(wallId)
    end
    activeWalls = {}

    for ped, handle in pairs(wandParticles) do
        StopParticleFxLooped(handle, false)
        RemoveParticleFx(handle, false)
    end
    wandParticles = {}

    for particleHandle, _ in pairs(allParticles) do
        StopParticleFxLooped(particleHandle, false)
        RemoveParticleFx(particleHandle, false)
    end
    allParticles = {}

    RemoveNamedPtfxAsset('core')
    RemoveNamedPtfxAsset('scr_rcbarry2')
end)

--- Check if player is behind a Wallis wall (for spell blocking)
local function IsPlayerBehindWall(playerPos, targetPos)
    -- Check if there's a wall between player and target
    for _, wallData in pairs(activeWalls) do
        if wallData and wallData.segments and #wallData.segments > 0 then
            -- Get wall plane
            local wallCenter = wallData.center
            local wallDir = wallData.direction
            local wallLength = wallData.length
            local wallHeight = wallData.height
            
            -- Check if line from player to target crosses the wall plane
            local toTarget = vector3(targetPos.x - playerPos.x, targetPos.y - playerPos.y, targetPos.z - playerPos.z)
            local toWall = vector3(wallCenter.x - playerPos.x, wallCenter.y - playerPos.y, 0.0)
            
            -- Project onto wall direction to see if it's within wall bounds
            local alongWall = toWall.x * wallDir.x + toWall.y * wallDir.y
            
            if math.abs(alongWall) < wallLength * 0.5 then
                -- Within wall length, check if crossing
                local perpDir = vector3(-wallDir.y, wallDir.x, 0.0)
                local playerDist = toWall.x * perpDir.x + toWall.y * perpDir.y
                local targetToWall = vector3(wallCenter.x - targetPos.x, wallCenter.y - targetPos.y, 0.0)
                local targetDist = targetToWall.x * perpDir.x + targetToWall.y * perpDir.y
                
                -- If player and target are on opposite sides of wall
                if (playerDist > 0 and targetDist < 0) or (playerDist < 0 and targetDist > 0) then
                    -- Check height
                    if playerPos.z >= wallCenter.z and playerPos.z <= wallCenter.z + wallHeight then
                        return true
                    end
                end
            end
        end
    end
    return false
end

--- Export function for other spells to check if target is behind wall
exports('IsPlayerBehindWall', IsPlayerBehindWall)

