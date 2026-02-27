---@diagnostic disable: undefined-global, trailing-space, unused-local, param-type-mismatch, missing-parameter
local activeJump = nil
local lastJumpTime = 0
local jumpCooldown = 300 -- Minimum time between particle effects (ms)

local RequestNamedPtfxAsset = RequestNamedPtfxAsset
local HasNamedPtfxAssetLoaded = HasNamedPtfxAssetLoaded
local UseParticleFxAssetNextCall = UseParticleFxAssetNextCall
local StartParticleFxNonLoopedAtCoord = StartParticleFxNonLoopedAtCoord
local GetGameplayCamCoord = GetGameplayCamCoord
local GetGameplayCamRot = GetGameplayCamRot
local GetEntityCoords = GetEntityCoords
local GetPlayerFromServerId = GetPlayerFromServerId
local GetPlayerPed = GetPlayerPed
local GetPlayerServerId = GetPlayerServerId
local PlayerId = PlayerId
local PlayerPedId = PlayerPedId
local SetSuperJumpThisFrame = SetSuperJumpThisFrame
local vector3 = vector3
local IsControlJustPressed = IsControlJustPressed
local SetPedCanRagdoll = SetPedCanRagdoll
local SetPedConfigFlag = SetPedConfigFlag
local IsPedFalling = IsPedFalling
local GetEntityVelocity = GetEntityVelocity
local GetGroundZFor_3dCoord = GetGroundZFor_3dCoord

local function RotationToDirection(rotation)
    local radX = rotation.x * (math.pi / 180.0)
    local radZ = rotation.z * (math.pi / 180.0)
    return vector3(-math.sin(radZ) * math.abs(math.cos(radX)), math.cos(radZ) * math.abs(math.cos(radX)), math.sin(radX))
end

local function FindTargetPlayer()
    local camCoords = GetGameplayCamCoord()
    local camRot = GetGameplayCamRot(2)
    local dir = RotationToDirection(camRot)
    local maxDist = Config.Raycast and Config.Raycast.maxDistance or 60.0

    local hit, entityHit = lib.raycast.cam(1 | 2 | 4 | 8 | 16, 4, maxDist)
    if not entityHit or not DoesEntityExist(entityHit) or not IsPedAPlayer(entityHit) then
        return nil
    end

    local idx = NetworkGetPlayerIndexFromPed(entityHit)
    if idx == -1 then return nil end
    return GetPlayerServerId(idx)
end

-- Create air wave particle effect at player's feet
local function CreateJumpParticle(ped)
    local now = GetGameTimer()
    if now - lastJumpTime < jumpCooldown then
        return
    end
    lastJumpTime = now

    local coords = GetEntityCoords(ped)
    local particleConfig = Config.Particles or {}
    local dict = particleConfig.dict or 'core'
    local name = particleConfig.name or 'ent_dst_elec_fence_sp'
    local scale = particleConfig.scale or 0.8
    local offset = particleConfig.offset or { x = 0.0, y = 0.0, z = -0.5 }

    if not HasNamedPtfxAssetLoaded(dict) then
        RequestNamedPtfxAsset(dict)
        local endTime = GetGameTimer() + 5000
        while not HasNamedPtfxAssetLoaded(dict) and GetGameTimer() < endTime do
            Wait(0)
        end
    end

    if HasNamedPtfxAssetLoaded(dict) then
        UseParticleFxAssetNextCall(dict)
        StartParticleFxNonLoopedAtCoord(
            name,
            coords.x + offset.x,
            coords.y + offset.y,
            coords.z + offset.z,
            0.0,
            0.0,
            0.0,
            scale,
            false,
            false,
            false
        )
    end
end

local function ApplyJumpBuff(duration, isRemote)
    if activeJump then
        activeJump.cancelled = true
    end
    local state = { cancelled = false }
    activeJump = state

    local player = PlayerPedId()
    local playerId = PlayerId()

    -- Disable ragdoll and prevent roll on landing
    SetPedCanRagdoll(player, false)
    SetPedConfigFlag(player, 281, false) -- Prevents fall/roll animations

    -- Load particle asset
    local particleConfig = Config.Particles or {}
    local dict = particleConfig.dict or 'core'
    RequestNamedPtfxAsset(dict)

    CreateThread(function()
        local startTime = GetGameTimer()
        local endTime = startTime + (duration or Config.Buff.baseDuration or 10000)
        local wasFalling = false
        local lastVelocityZ = 0.0

        while GetGameTimer() < endTime do
            if state.cancelled then
                break
            end

            player = PlayerPedId()
            
            -- Apply super jump every frame
            SetSuperJumpThisFrame(playerId)

            -- Keep ragdoll disabled and prevent roll
            SetPedCanRagdoll(player, false)
            SetPedConfigFlag(player, 281, false)

            -- Detect landing and prevent roll
            local isFalling = IsPedFalling(player)
            local velocity = GetEntityVelocity(player)
            local coords = GetEntityCoords(player)
            local groundZ = coords.z
            
            -- Get ground Z coordinate
            local found, groundZCoord = GetGroundZFor_3dCoord(coords.x, coords.y, coords.z, false)
            if found then
                groundZ = groundZCoord
            end
            
            local distanceFromGround = coords.z - groundZ
            local isLanding = wasFalling and not isFalling and distanceFromGround < 1.5 and velocity.z < 0.0

            if isLanding then
                -- Prevent roll animation on landing
                ClearPedTasksImmediately(player)
                SetPedCanRagdoll(player, false)
                SetPedConfigFlag(player, 281, false)
            end

            wasFalling = isFalling
            lastVelocityZ = velocity.z

            -- Detect jump and create particle effect
            if IsControlJustPressed(0, 22) then -- Jump button
                CreateJumpParticle(player)
            end

            Wait(0)
        end

        -- Re-enable ragdoll after buff ends
        if DoesEntityExist(player) then
            SetPedCanRagdoll(player, true)
            SetPedConfigFlag(player, 281, true)
        end

        activeJump = nil
    end)
end

RegisterNetEvent('th_altis:prepareJump', function(targetId, spellLevel)
    local ped = PlayerPedId()

    CreateThread(function()
        Wait(800)

        local targetServerId = GetPlayerServerId(PlayerId())
        if targetId and targetId > 0 then
            targetServerId = targetId
        else
            local rayTarget = FindTargetPlayer()
            if rayTarget and rayTarget > 0 then
                targetServerId = rayTarget
            end
        end

        TriggerServerEvent('th_altis:applyJump', targetServerId, spellLevel)
    end)
end)

RegisterNetEvent('th_altis:otherPlayerCasting', function(sourceServerId)
    local myId = GetPlayerServerId(PlayerId())
    if sourceServerId == myId then return end

    local casterPlayer = GetPlayerFromServerId(sourceServerId)
    if casterPlayer == -1 then return end
    local casterPed = GetPlayerPed(casterPlayer)
    if not DoesEntityExist(casterPed) then return end
end)

RegisterNetEvent('th_altis:grantJump', function(duration, fromOther)
    ApplyJumpBuff(duration or (Config.Buff.baseDuration or 10000), fromOther)
end)

AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    if activeJump then
        activeJump.cancelled = true
        activeJump = nil
    end
    
    -- Re-enable ragdoll on resource stop
    local player = PlayerPedId()
    if DoesEntityExist(player) then
        SetPedCanRagdoll(player, true)
        SetPedConfigFlag(player, 281, true)
    end
end)

