---@diagnostic disable: undefined-global, trailing-space, unused-local, param-type-mismatch, missing-parameter
local wandParticles = {}
local allParticles = {}

local RequestNamedPtfxAsset = RequestNamedPtfxAsset
local HasNamedPtfxAssetLoaded = HasNamedPtfxAssetLoaded
local UseParticleFxAssetNextCall = UseParticleFxAssetNextCall
local StartParticleFxLoopedOnEntity = StartParticleFxLoopedOnEntity
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
local SetPedToRagdoll = SetPedToRagdoll

local function HasProtheaShield()
    local hasShield = false

    if LocalPlayer and LocalPlayer.state then
        hasShield = LocalPlayer.state.protheaShield == true
    end

    if not hasShield and exports['th_prothea'] and exports['th_prothea'].hasLocalShield then
        local ok, result = pcall(function()
            return exports['th_prothea']:hasLocalShield()
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
    RequestNamedPtfxAsset('core')
    while not HasNamedPtfxAssetLoaded('core') do
        Wait(0)
    end
    UseParticleFxAssetNextCall('core')
    local fx = StartParticleFxLoopedOnEntity('ent_amb_tnl_bubbles_sml', playerPed, 0.1, 0.0, 0.0, 0.0, 0.0, 0.0, 0.9, false, false, false)
    if fx then
        wandParticles[playerPed] = fx
        allParticles[fx] = { createdTime = GetGameTimer(), type = 'wand' }
    end
end

local function PlayShockwaveFx(coords)
    local fx = Config.FX
    if not fx then return end

    RequestNamedPtfxAsset(fx.ring.dict)
    while not HasNamedPtfxAssetLoaded(fx.ring.dict) do Wait(0) end

    UseParticleFxAssetNextCall(fx.ring.dict)
    StartParticleFxNonLoopedAtCoord(fx.ring.particle, coords.x, coords.y, coords.z, 0.0, 0.0, 0.0, fx.ring.scale or 2.0, false, false, false)

    UseParticleFxAssetNextCall(fx.ring.dict)
    StartParticleFxNonLoopedAtCoord(fx.smoke.particle, coords.x, coords.y, coords.z + 0.3, 0.0, 0.0, 0.0, fx.smoke.scale or 1.4, false, false, false)

    UseParticleFxAssetNextCall(fx.ring.dict)
    StartParticleFxNonLoopedAtCoord(fx.sparks.particle, coords.x, coords.y, coords.z, 0.0, 0.0, 0.0, fx.sparks.scale or 1.0, false, false, false)
end

local function ApplyShake(coords)
    if HasProtheaShield() then
        return
    end

    local myCoords = GetEntityCoords(cache.ped)
    local dist = #(myCoords - coords)
    local maxDist = Config.Shockwave.shakeDistance or 30.0
    if dist < maxDist then
        local factor = 1.0 - (dist / maxDist)
        local intensity = (Config.Shockwave.shakeIntensity or 0.45) * factor
        ShakeGameplayCam('MEDIUM_EXPLOSION_SHAKE', intensity)
    end
end

local function RagdollIfClose(coords)
    if HasProtheaShield() then
        return
    end

    local myCoords = GetEntityCoords(cache.ped)
    local dist = #(myCoords - coords)
    if dist < (Config.Shockwave.radius or 10.0) then
        local time = Config.Shockwave.ragdollTime or 2000
        SetPedToRagdoll(cache.ped, time, time, 0, false, false, false)
    end
end

local function FindTargetCoords()
    local camCoords = GetGameplayCamCoord()
    local camRot = GetGameplayCamRot(2)
    local dir = RotationToDirection(camRot)
    local maxDist = Config.Shockwave.radius or 10.0

    local hit, entityHit, coords = lib.raycast.cam(1 | 2 | 4 | 8 | 16, 4, maxDist)
    if coords and (coords.x ~= 0.0 or coords.y ~= 0.0 or coords.z ~= 0.0) then
        return coords
    end

    return vector3(
        camCoords.x + dir.x * maxDist,
        camCoords.y + dir.y * maxDist,
        camCoords.z + dir.z * maxDist
    )
end

RegisterNetEvent('th_shockwave:prepare', function()
    local ped = cache.ped
    PlayWandFx(ped)

    CreateThread(function()
        Wait(900)
        local handBone = GetPedBoneIndex(ped, 28422)
        local castPos = GetWorldPositionOfEntityBone(ped, handBone)

        local targetCoords = FindTargetCoords()
        TriggerServerEvent('th_shockwave:trigger', targetCoords)

        SetTimeout(600, function()
            StopWandFx(ped)
        end)
    end)
end)

RegisterNetEvent('th_shockwave:otherPlayerCasting', function(sourceServerId)
    local myId = GetPlayerServerId(PlayerId())
    if sourceServerId == myId then return end

    local casterPlayer = GetPlayerFromServerId(sourceServerId)
    if casterPlayer == -1 then return end
    local casterPed = GetPlayerPed(casterPlayer)
    if not DoesEntityExist(casterPed) then return end

    PlayWandFx(casterPed)
    SetTimeout(2000, function()
        StopWandFx(casterPed)
    end)
end)

RegisterNetEvent('th_shockwave:fire', function(sourceServerId, targetCoords)
    if not targetCoords then return end
    PlayShockwaveFx(targetCoords)

    local myId = GetPlayerServerId(PlayerId())
    if sourceServerId ~= myId then
        ApplyShake(targetCoords)
        RagdollIfClose(targetCoords)
    end
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
