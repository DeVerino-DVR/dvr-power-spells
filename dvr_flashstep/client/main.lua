---@diagnostic disable: undefined-global, trailing-space, unused-local, param-type-mismatch, missing-parameter
local wandParticles = {}
local allParticles = {}

local RequestNamedPtfxAsset = RequestNamedPtfxAsset
local HasNamedPtfxAssetLoaded = HasNamedPtfxAssetLoaded
local UseParticleFxAssetNextCall = UseParticleFxAssetNextCall
local StartParticleFxLoopedOnEntity = StartParticleFxLoopedOnEntity
local StartParticleFxLoopedAtCoord = StartParticleFxLoopedAtCoord
local StartParticleFxNonLoopedAtCoord = StartParticleFxNonLoopedAtCoord
local StopParticleFxLooped = StopParticleFxLooped
local RemoveParticleFx = RemoveParticleFx
local RemoveNamedPtfxAsset = RemoveNamedPtfxAsset
local GetGameplayCamCoord = GetGameplayCamCoord
local GetGameplayCamRot = GetGameplayCamRot
local GetPedBoneIndex = GetPedBoneIndex
local GetWorldPositionOfEntityBone = GetWorldPositionOfEntityBone
local GetEntityCoords = GetEntityCoords
local SetEntityCoords = SetEntityCoords
local GetPlayerFromServerId = GetPlayerFromServerId
local GetPlayerPed = GetPlayerPed
local GetPlayerServerId = GetPlayerServerId
local PlayerId = PlayerId
local vector3 = vector3
local ShakeGameplayCam = ShakeGameplayCam

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

local function StopWandFx(playerPed)
    local handle = wandParticles[playerPed]
    if handle then
        StopParticleFxLooped(handle, false)
        RemoveParticleFx(handle, false)
        allParticles[handle] = nil
        wandParticles[playerPed] = nil
    end
end

local function RotationToDirection(rotation)
    local radX = rotation.x * (math.pi / 180.0)
    local radZ = rotation.z * (math.pi / 180.0)
    return vector3(
        -math.sin(radZ) * math.abs(math.cos(radX)),
        math.cos(radZ) * math.abs(math.cos(radX)),
        math.sin(radX)
    )
end

local function PlayWandFx(playerPed)
    local fxCfg = Config.FX and Config.FX.wand
    if not fxCfg then return end

    RequestNamedPtfxAsset(fxCfg.dict)
    while not HasNamedPtfxAssetLoaded(fxCfg.dict) do
        Wait(0)
    end

    UseParticleFxAssetNextCall(fxCfg.dict)
    local fx = StartParticleFxLoopedOnEntity(
        fxCfg.particle,
        playerPed,
        0.1, 0.0, 0.0,
        0.0, 0.0, 0.0,
        fxCfg.scale or 1.0,
        false, false, false
    )

    if fx then
        wandParticles[playerPed] = fx
        allParticles[fx] = { createdTime = GetGameTimer(), type = 'wand' }
    end
end

local function PlayTrail(startCoords, endCoords)
    local fxCfg = Config.FX and Config.FX.trail
    if not fxCfg then return end

    RequestNamedPtfxAsset(fxCfg.dict)
    while not HasNamedPtfxAssetLoaded(fxCfg.dict) do
        Wait(0)
    end

    local dir = endCoords - startCoords
    local distance = #(dir)
    if distance <= 0.01 then return end
    dir = dir / distance
    local steps = 12
    local step = distance / steps

    for i = 1, steps do
        local pos = startCoords + (dir * (step * i))
        UseParticleFxAssetNextCall(fxCfg.dict)
        StartParticleFxNonLoopedAtCoord(
            fxCfg.particle,
            pos.x, pos.y, pos.z,
            0.0, 0.0, 0.0,
            fxCfg.scale or 0.6,
            false, false, false
        )
    end
end

local function PlayArrivalFx(coords)
    local fxCfg = Config.FX and Config.FX.arrival
    if not fxCfg then return end

    RequestNamedPtfxAsset(fxCfg.dict)
    while not HasNamedPtfxAssetLoaded(fxCfg.dict) do
        Wait(0)
    end

    UseParticleFxAssetNextCall(fxCfg.dict)
    StartParticleFxNonLoopedAtCoord(
        fxCfg.particle,
        coords.x, coords.y, coords.z,
        0.0, 0.0, 0.0,
        fxCfg.scale or 1.0,
        false, false, false
    )

    UseParticleFxAssetNextCall(fxCfg.dict)
    StartParticleFxNonLoopedAtCoord(
        fxCfg.particle,
        coords.x, coords.y, coords.z + 0.3,
        0.0, 0.0, 0.0,
        (fxCfg.scale or 1.0) * 0.7,
        false, false, false
    )
end

local function ApplyCameraShake(coords)
    if HasProtheaShield() then
        return
    end

    local playerCoords = GetEntityCoords(cache.ped)
    local dist = #(playerCoords - coords)
    local maxDist = Config.Dash.shakeDistance or 25.0
    local base = Config.Dash.shakeIntensity or 0.6
    if dist < maxDist then
        local factor = 1.0 - (dist / maxDist)
        local intensity = math.max(0.1, base * factor)
        ShakeGameplayCam('SMALL_EXPLOSION_SHAKE', intensity)
    end
end

local function FindDashTarget()
    local camCoords = GetGameplayCamCoord()
    local camRot = GetGameplayCamRot(2)
    local dir = RotationToDirection(camRot)
    local maxDist = Config.Dash.maxDistance or 28.0

    local hit, entityHit, coords = lib.raycast.cam(1 | 2 | 4 | 8 | 16, 4, maxDist)
    local target
    if coords and (coords.x ~= 0.0 or coords.y ~= 0.0 or coords.z ~= 0.0) then
        target = coords
    else
        target = vector3(
            camCoords.x + dir.x * maxDist,
            camCoords.y + dir.y * maxDist,
            camCoords.z + dir.z * maxDist
        )
    end
    return target
end

RegisterNetEvent('dvr_flashstep:prepareDash', function()
    local ped = cache.ped
    PlayWandFx(ped)

    CreateThread(function()
        Wait(800)

        local startCoords = GetEntityCoords(ped)
        local targetCoords = FindDashTarget()
        if not targetCoords then
            if Config.Messages and Config.Messages.noTarget then
                TriggerEvent('ox_lib:notify', Config.Messages.noTarget)
            end
            StopWandFx(ped)
            return
        end

        TriggerServerEvent('dvr_flashstep:dash', targetCoords)
        Wait(500)
        StopWandFx(ped)
    end)
end)

RegisterNetEvent('dvr_flashstep:otherPlayerCasting', function(sourceServerId)
    local myId = GetPlayerServerId(PlayerId())
    if sourceServerId == myId then return end

    local casterPlayer = GetPlayerFromServerId(sourceServerId)
    if casterPlayer == -1 then return end
    local casterPed = GetPlayerPed(casterPlayer)
    if not DoesEntityExist(casterPed) then return end

    PlayWandFx(casterPed)
    SetTimeout(1500, function()
        StopWandFx(casterPed)
    end)
end)

RegisterNetEvent('dvr_flashstep:doDash', function(sourceServerId, targetCoords)
    if not targetCoords then return end

    local casterPlayer = GetPlayerFromServerId(sourceServerId)
    if casterPlayer == -1 then return end

    local casterPed = GetPlayerPed(casterPlayer)
    if not DoesEntityExist(casterPed) then return end

    local startCoords = GetEntityCoords(casterPed)

    -- Visual trail and arrival for everyone
    PlayTrail(startCoords, targetCoords)
    PlayArrivalFx(targetCoords)
    ApplyCameraShake(targetCoords)

    -- Move ped
    SetEntityCoords(casterPed, targetCoords.x, targetCoords.y, targetCoords.z, false, false, false, false)
end)

AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    for ped, fx in pairs(wandParticles) do
        StopParticleFxLooped(fx, false)
        RemoveParticleFx(fx, false)
    end
    wandParticles = {}
    for handle, _ in pairs(allParticles) do
        StopParticleFxLooped(handle, false)
        RemoveParticleFx(handle, false)
    end
    allParticles = {}
    RemoveNamedPtfxAsset('core')
end)
