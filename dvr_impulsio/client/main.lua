---@diagnostic disable: undefined-global, trailing-space, unused-local, param-type-mismatch, missing-parameter
local projectileProps = {}
local wandParticles = {}
local allParticles = {}

-- Native caching
local RequestNamedPtfxAsset = RequestNamedPtfxAsset
local HasNamedPtfxAssetLoaded = HasNamedPtfxAssetLoaded
local UseParticleFxAsset = UseParticleFxAsset
local UseParticleFxAssetNextCall = UseParticleFxAssetNextCall
local StartParticleFxLoopedOnEntity = StartParticleFxLoopedOnEntity
local StartParticleFxNonLoopedOnEntity = StartParticleFxNonLoopedOnEntity
local StartParticleFxNonLoopedAtCoord = StartParticleFxNonLoopedAtCoord
local StartNetworkedParticleFxNonLoopedAtCoord = StartNetworkedParticleFxNonLoopedAtCoord
local SetParticleFxLoopedColour = SetParticleFxLoopedColour
local SetParticleFxLoopedAlpha = SetParticleFxLoopedAlpha
local StopParticleFxLooped = StopParticleFxLooped
local RemoveParticleFx = RemoveParticleFx
local GetGameplayCamCoord = GetGameplayCamCoord
local GetGameplayCamRot = GetGameplayCamRot
local GetPedBoneIndex = GetPedBoneIndex
local GetWorldPositionOfEntityBone = GetWorldPositionOfEntityBone
local GetEntityCoords = GetEntityCoords
local GetPlayerFromServerId = GetPlayerFromServerId
local GetPlayerPed = GetPlayerPed
local GetPlayerServerId = GetPlayerServerId
local PlayerId = PlayerId
local DoesEntityExist = DoesEntityExist
local GetHashKey = GetHashKey
local SetPedToRagdoll = SetPedToRagdoll
local ApplyForceToEntity = ApplyForceToEntity
local GetGameTimer = GetGameTimer
local CreateObject = CreateObject
local DeleteObject = DeleteObject
local SetEntityCoords = SetEntityCoords
local SetEntityRotation = SetEntityRotation
local SetEntityCollision = SetEntityCollision
local SetEntityAsMissionEntity = SetEntityAsMissionEntity
local SetEntityCompletelyDisableCollision = SetEntityCompletelyDisableCollision
local AddExplosion = AddExplosion
local PlaySoundFromCoord = PlaySoundFromCoord

--- Check if player has Prothea shield
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

--- Convert rotation to direction
local function RotationToDirection(rotation)
    local pitch = math.rad(rotation.x)
    local yaw = math.rad(rotation.z)
    return vector3(
        -math.sin(yaw) * math.cos(pitch),
        math.cos(yaw) * math.cos(pitch),
        math.sin(pitch)
    )
end

--- Stop wand glow
local function StopWandGlow(playerPed)
    local handle = wandParticles[playerPed]
    if handle then
        StopParticleFxLooped(handle, false)
        RemoveParticleFx(handle, false)
        wandParticles[playerPed] = nil
    end
end

--- Create wand glow (green like raypistol)
local function CreateWandGlow(playerPed)
    local weapon = GetCurrentPedWeaponEntityIndex and GetCurrentPedWeaponEntityIndex(playerPed)
    if not weapon or not DoesEntityExist(weapon) then return nil end

    RequestNamedPtfxAsset('core')
    while not HasNamedPtfxAssetLoaded('core') do Wait(0) end

    UseParticleFxAsset('core')
    local handle = StartParticleFxLoopedOnEntity(
        'veh_light_clear', weapon,
        0.95, 0.0, 0.1, 0.0, 0.0, 0.0,
        0.7, false, false, false
    )

    if handle then
        -- GREEN like raypistol
        SetParticleFxLoopedColour(handle, 0.0, 1.0, 0.3, false)
        SetParticleFxLoopedAlpha(handle, 255)
        wandParticles[playerPed] = handle
    end

    return handle
end

--- Get real impact point via raycast
local function GetImpactPoint()
    local camPos = GetGameplayCamCoord()
    local camRot = GetGameplayCamRot(2)
    local dir = RotationToDirection(camRot)
    
    local maxDistance = Config.Projectile.maxDistance or 100.0
    local endPos = camPos + dir * maxDistance
    
    -- Raycast to find actual hit point
    local rayHandle = StartShapeTestRay(camPos.x, camPos.y, camPos.z, endPos.x, endPos.y, endPos.z, -1, cache.ped, 0)
    local _, hit, hitCoords, _, _ = GetShapeTestResult(rayHandle)
    
    if hit then
        return hitCoords
    else
        return endPos
    end
end

--- Attach projectile trail (green energy)
local function AttachProjectileTrail(rayProp)
    if not rayProp or not DoesEntityExist(rayProp) then return end

    RequestNamedPtfxAsset('core')
    while not HasNamedPtfxAssetLoaded('core') do Wait(0) end

    UseParticleFxAsset('core')
    UseParticleFxAssetNextCall('core')

    -- Initial burst
    StartParticleFxNonLoopedOnEntity('veh_light_red_trail', rayProp, 0.35, 0.0, 0.1, 0.0, 0.0, 0.0)

    -- Trail
    local trailHandle = StartParticleFxLoopedOnEntity('veh_light_red_trail', rayProp, 0.35, 0.0, 0.1, 0.0, 0.0, 0.0, 0.8, false, false, false)

    -- GREEN/CYAN color (raypistol)
    SetParticleFxLoopedColour(trailHandle, 0.0, 1.0, 0.5, false)
    SetParticleFxLoopedAlpha(trailHandle, 255)

    allParticles[trailHandle] = {
        createdTime = GetGameTimer(),
        type = 'projectileTrail'
    }

    return trailHandle
end

--- Create impact explosion (raypistol style)
local function CreateImpactExplosion(coords, spellLevel)
    -- Explosion type 70 (submarine big) - NO FIRE, just shockwave
    -- isInvisible = true pour éviter les flammes visuelles
    AddExplosion(coords.x, coords.y, coords.z, 70, 0.0, true, true, 0.5, true)
    
    -- Raypistol explosion sound
    PlaySoundFromCoord(-1, "DLC_XM_Explosions_Sounds", "Explosion_Alien", coords.x, coords.y, coords.z, false, 0, false)
    -- Note: EMP particle is played via network event 'dvr_impulsio:playImpactFx' for all clients
end

--- Create Impulsio projectile
local function CreateImpulsioProjectile(startCoords, targetCoords, sourceServerId, casterPed, spellLevel)
    local propModel = GetHashKey("wizardsV_nib_wizards_lightning_boltSmall")
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
    
    -- Stop wand glow only if casterPed is valid (local player or visible player)
    if casterPed and DoesEntityExist(casterPed) then
        StopWandGlow(casterPed)
    end
    
    local trailHandle = AttachProjectileTrail(rayProp)
    
    local speed = Config.Projectile.speed or 80.0
    local duration = (distance / speed) * 1000.0
    local startTime = GetGameTimer()
    local endTime = startTime + duration
    
    projectileProps[rayProp] = {
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
        spellLevel = spellLevel or 1
    }
end

--- Projectile movement thread
CreateThread(function()
    while true do
        local currentTime = GetGameTimer()
        local projectilesToRemove = {}
        
        for prop, data in pairs(projectileProps) do
            if DoesEntityExist(prop) then
                local progress = math.min((currentTime - data.startTime) / (data.endTime - data.startTime), 1.0)
                
                if progress >= 1.0 then
                    -- Impact!
                    local impactCoords = data.targetCoords
                    
                    -- Notify server to broadcast impact FX to all clients
                    TriggerServerEvent('dvr_impulsio:onImpact', impactCoords, data.spellLevel)
                    
                    -- Explosion & Sound (local only, FX will be synced via server)
                    CreateImpactExplosion(impactCoords, data.spellLevel)
                    
                    -- Cleanup
                    if data.trailHandle then
                        StopParticleFxLooped(data.trailHandle, false)
                        RemoveParticleFx(data.trailHandle, false)
                        allParticles[data.trailHandle] = nil
                    end
                    
                    DeleteObject(prop)
                    table.insert(projectilesToRemove, prop)
                else
                    -- Move projectile
                    local currentPos = vector3(
                        data.startCoords.x + data.direction.x * data.distance * progress,
                        data.startCoords.y + data.direction.y * data.distance * progress,
                        data.startCoords.z + data.direction.z * data.distance * progress
                    )
                    
                    SetEntityCoords(prop, currentPos.x, currentPos.y, currentPos.z, false, false, false, false)
                end
            else
                table.insert(projectilesToRemove, prop)
            end
        end
        
        for _, prop in ipairs(projectilesToRemove) do
            projectileProps[prop] = nil
        end
        
        Wait(0)
    end
end)

--- Create projectile for all clients (networked)
RegisterNetEvent('dvr_impulsio:createProjectile', function(startCoords, targetCoords, sourceServerId, spellLevel)
    -- Get caster ped if it's the local player, otherwise try to get from server ID
    local casterPed = nil
    if sourceServerId == GetPlayerServerId(PlayerId()) then
        casterPed = cache.ped
    else
        local casterPlayer = GetPlayerFromServerId(sourceServerId)
        if casterPlayer ~= -1 then
            casterPed = GetPlayerPed(casterPlayer)
        end
    end
    
    -- Always create projectile, even if casterPed is not found (for other players)
    CreateImpulsioProjectile(startCoords, targetCoords, sourceServerId, casterPed, spellLevel)
end)

--- Play impact EMP particle for all clients
RegisterNetEvent('dvr_impulsio:playImpactFx', function(impactCoords)
    -- Electromagnetic EMP impulse particles
    RequestNamedPtfxAsset('scr_xs_dr')
    while not HasNamedPtfxAssetLoaded('scr_xs_dr') do Wait(0) end

    -- Main EMP discharge
    UseParticleFxAssetNextCall('scr_xs_dr')
    StartNetworkedParticleFxNonLoopedAtCoord(
        'scr_xs_dr_emp',
        impactCoords.x, impactCoords.y, impactCoords.z + 0.5,
        0.0, 0.0, 0.0,
        2.0, false, false, false
    )
end)

--- Apply knockback locally
RegisterNetEvent('dvr_impulsio:applyKnockback', function(impactCoords, level, forceUp, forceHorizontal, ragdollTime)
    if HasProtheaShield() then return end

    local ped = cache.ped
    local pedCoords = GetEntityCoords(ped)
    local radius = Config.Knockback.radius or 6.0

    local dist = #(pedCoords - impactCoords)
    if dist > radius then return end

    local dir = pedCoords - impactCoords
    local dirLength = #dir
    if dirLength > 0.01 then
        dir = dir / dirLength
    else
        dir = vector3(0.0, 0.0, 1.0)
    end

    SetPedToRagdoll(ped, ragdollTime, ragdollTime, 0, false, false, false)

    Wait(50)
    ApplyForceToEntity(ped, 1, 0.0, 0.0, forceUp, 0.0, 0.0, 0.0, 0, false, true, true, false, true)
    ApplyForceToEntity(ped, 1, dir.x * forceHorizontal, dir.y * forceHorizontal, forceUp * 0.3, 0.0, 0.0, 0.0, 0, false, true, true, false, true)
end)

--- Event: Prepare and shoot
RegisterNetEvent('dvr_impulsio:prepareCast', function(spellLevel)
    local casterPed = cache.ped

    CreateWandGlow(casterPed)

    CreateThread(function()
        local duration = Config.Animation.duration or 2500
        local animSpeed = Config.Animation.speedMultiplier or 3.5
        local realDuration = duration / animSpeed
        local castDelay = math.floor(realDuration * 0.4)

        if castDelay < 0 then castDelay = 0 end
        Wait(castDelay)

        local impactCoords = GetImpactPoint()
        
        -- Send to server for damage
        TriggerServerEvent('dvr_impulsio:prepareImpact', impactCoords, spellLevel)
        
        Wait(50)
        
        -- Get start position and send to server for synchronization
        local handBone = GetPedBoneIndex(casterPed, 28422)
        local startPos = GetWorldPositionOfEntityBone(casterPed, handBone)
        
        -- Send to server to broadcast projectile creation to all clients
        TriggerServerEvent('dvr_impulsio:createProjectile', startPos, impactCoords, spellLevel)

        Wait(300)
        
        SetPedUsingActionMode(casterPed, false, -1, "DEFAULT_ACTION")
        ResetPedMovementClipset(casterPed, 0.25)
    end)
end)

--- Event: Other player casting
RegisterNetEvent('dvr_impulsio:otherPlayerCasting', function(sourceServerId)
    local myServerId = GetPlayerServerId(PlayerId())
    if sourceServerId == myServerId then return end

    local casterPlayer = GetPlayerFromServerId(sourceServerId)
    if casterPlayer == -1 then return end

    local casterPed = GetPlayerPed(casterPlayer)
    if not DoesEntityExist(casterPed) then return end

    CreateWandGlow(casterPed)
    SetTimeout(1000, function()
        StopWandGlow(casterPed)
    end)
end)

--- Cleanup on stop
AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end

    for ped, handle in pairs(wandParticles) do
        StopParticleFxLooped(handle, false)
        RemoveParticleFx(handle, false)
    end
    wandParticles = {}
    
    for prop, data in pairs(projectileProps) do
        if data.trailHandle then
            StopParticleFxLooped(data.trailHandle, false)
            RemoveParticleFx(data.trailHandle, false)
        end
        if DoesEntityExist(prop) then
            DeleteObject(prop)
        end
    end
    projectileProps = {}
end)
