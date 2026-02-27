---@diagnostic disable: undefined-global, trailing-space, unused-local, param-type-mismatch, missing-parameter
local wandParticles = {}
local allParticles = {}

local RequestNamedPtfxAsset = RequestNamedPtfxAsset
local HasNamedPtfxAssetLoaded = HasNamedPtfxAssetLoaded
local UseParticleFxAssetNextCall = UseParticleFxAssetNextCall
local StartParticleFxLoopedOnEntity = StartParticleFxLoopedOnEntity
local StopParticleFxLooped = StopParticleFxLooped
local RemoveParticleFx = RemoveParticleFx
local RemoveNamedPtfxAsset = RemoveNamedPtfxAsset
local GetGameplayCamCoord = GetGameplayCamCoord
local GetGameplayCamRot = GetGameplayCamRot
local GetPedBoneIndex = GetPedBoneIndex
local GetWorldPositionOfEntityBone = GetWorldPositionOfEntityBone
local GetEntityCoords = GetEntityCoords
local GetGroundZFor_3dCoord = GetGroundZFor_3dCoord
local GetPlayerFromServerId = GetPlayerFromServerId
local GetPlayerPed = GetPlayerPed
local GetPlayerServerId = GetPlayerServerId
local PlayerId = PlayerId
local vector3 = vector3

local function StopWandParticles(playerPed)
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
    return vector3(-math.sin(radZ) * math.abs(math.cos(radX)), math.cos(radZ) * math.abs(math.cos(radX)), math.sin(radX))
end

local function PlaySmokeFxOnPed(ped)
    local fxCfg = Config.Smoke
    if not fxCfg then return end

    RequestNamedPtfxAsset(fxCfg.dict)
    while not HasNamedPtfxAssetLoaded(fxCfg.dict) do
        Wait(0)
    end

    UseParticleFxAssetNextCall(fxCfg.dict)
    local fx = StartParticleFxLoopedOnEntity(fxCfg.particle, ped, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, fxCfg.scale or 1.0, false, false, false)
    if fx then
        allParticles[fx] = { createdTime = GetGameTimer(), type = 'smoke', ped = ped }
    end

    SetTimeout(fxCfg.duration or 3000, function()
        if fx then
            StopParticleFxLooped(fx, false)
            RemoveParticleFx(fx, false)
            allParticles[fx] = nil
        end
    end)
end

local function PlayWandFx(playerPed)
    PlaySmokeFxOnPed(playerPed)
end

local function FindPlayerTarget()
    local camCoords = GetGameplayCamCoord()
    local camRot = GetGameplayCamRot(2)
    local dir = RotationToDirection(camRot)
    local maxDist = Config.Raycast.maxDistance or 60.0

    local hit, entityHit, coords = lib.raycast.cam(1 | 2 | 4 | 8 | 16, 4, maxDist)
    if not entityHit or not DoesEntityExist(entityHit) then
        return nil, nil, coords
    end

    if not IsPedAPlayer(entityHit) then
        return nil, nil, coords
    end

    local targetPlayer = NetworkGetPlayerIndexFromPed(entityHit)
    if targetPlayer == -1 then
        return nil, nil, coords
    end

    local targetServerId = GetPlayerServerId(targetPlayer)
    return targetServerId, entityHit, coords
end

RegisterNetEvent('th_fumania:prepareSwap', function()
    local ped = cache.ped
    PlayWandFx(ped)

    CreateThread(function()
        Wait(800)

        local sourceCoords = GetEntityCoords(ped)
        local targetId, targetPed, coords = FindPlayerTarget()
        if not targetId then
            if Config.Messages and Config.Messages.noTarget then
                TriggerEvent('ox_lib:notify', Config.Messages.noTarget)
            end
            StopWandParticles(ped)
            return
        end

        local targetCoords = coords or GetEntityCoords(targetPed)
        TriggerServerEvent('th_fumania:swapPositions', targetId, sourceCoords, targetCoords)
    end)
end)

RegisterNetEvent('th_fumania:otherPlayerCasting', function(sourceServerId)
    local myId = GetPlayerServerId(PlayerId())
    if sourceServerId == myId then return end

    local casterPlayer = GetPlayerFromServerId(sourceServerId)
    if casterPlayer == -1 then return end
    local casterPed = GetPlayerPed(casterPlayer)
    if not DoesEntityExist(casterPed) then return end

    PlayWandFx(casterPed)
end)

RegisterNetEvent('th_fumania:doSwap', function(sourceId, targetId, sourceCoords, targetCoords)
    if not sourceCoords or not targetCoords then return end

    local myId = GetPlayerServerId(PlayerId())
    if myId == sourceId then
        SetEntityCoords(cache.ped, targetCoords.x, targetCoords.y, targetCoords.z, false, false, false, false)
        PlaySmokeFxOnPed(cache.ped)
    elseif myId == targetId then
        SetEntityCoords(cache.ped, sourceCoords.x, sourceCoords.y, sourceCoords.z, false, false, false, false)
        PlaySmokeFxOnPed(cache.ped)
    end
end)

AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    StopWandParticles(cache.ped)
    for handle, _ in pairs(allParticles) do
        StopParticleFxLooped(handle, false)
        RemoveParticleFx(handle, false)
    end
    allParticles = {}
    RemoveNamedPtfxAsset('core')
end)
