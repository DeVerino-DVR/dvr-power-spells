---@diagnostic disable: undefined-global, trailing-space, unused-local, param-type-mismatch, missing-parameter, deprecated
local wandParticles = {}
local allParticles = {}

local RequestNamedPtfxAsset = RequestNamedPtfxAsset
local HasNamedPtfxAssetLoaded = HasNamedPtfxAssetLoaded
local UseParticleFxAssetNextCall = UseParticleFxAssetNextCall
local StartParticleFxLoopedOnEntity = StartParticleFxLoopedOnEntity
local StartParticleFxLoopedAtCoord = StartParticleFxLoopedAtCoord
local StopParticleFxLooped = StopParticleFxLooped
local RemoveParticleFx = RemoveParticleFx
local RemoveNamedPtfxAsset = RemoveNamedPtfxAsset
local GetGameplayCamCoord = GetGameplayCamCoord
local GetGameplayCamRot = GetGameplayCamRot
local GetGameTimer = GetGameTimer
local GetPedBoneIndex = GetPedBoneIndex
local GetWorldPositionOfEntityBone = GetWorldPositionOfEntityBone
local GetEntityCoords = GetEntityCoords
local SetEntityCoords = SetEntityCoords
local GetGroundZFor_3dCoord = GetGroundZFor_3dCoord
local GetPlayerFromServerId = GetPlayerFromServerId
local GetPlayerPed = GetPlayerPed
local GetPlayerServerId = GetPlayerServerId
local SetTimeout = SetTimeout
local GetCurrentResourceName = GetCurrentResourceName

local PlaySoundUrl = function(id, url, coords)
    if not url then return end
    -- REPLACE WITH YOUR SOUND SYSTEM
    -- exports['lo_audio']:playSound({
    -- id = id,
    -- url = url,
    -- volume = 0.9,
    -- loop = false,
    -- spatial = true,
    -- distance = 5.0,
    -- pos = coords and { x = coords.x, y = coords.y, z = coords.z } or nil
    -- })
end

local function StopWandParticles(playerPed)
    local handle = wandParticles[playerPed]
    if handle then
        StopParticleFxLooped(handle, false)
        RemoveParticleFx(handle, false)
        allParticles[handle] = nil
        wandParticles[playerPed] = nil
    end
end

local function RemoveAllParticles()
    for ped, handle in pairs(wandParticles) do
        StopParticleFxLooped(handle, false)
        RemoveParticleFx(handle, false)
    end
    wandParticles = {}

    for handle, _ in pairs(allParticles) do
        StopParticleFxLooped(handle, false)
        RemoveParticleFx(handle, false)
    end
    allParticles = {}

    RemoveNamedPtfxAsset('core')
end

local function RotationToDirection(rotation)
    local radX = rotation.x * (math.pi / 180.0)
    local radZ = rotation.z * (math.pi / 180.0)
    local dir = vector3(-math.sin(radZ) * math.abs(math.cos(radX)), math.cos(radZ) * math.abs(math.cos(radX)), math.sin(radX))
    return dir
end

local function PlayWandFx(playerPed)
    local wandFx = Config.Fx and Config.Fx.wand
    if not wandFx then return end

    RequestNamedPtfxAsset(wandFx.dict)
    while not HasNamedPtfxAssetLoaded(wandFx.dict) do
        Wait(0)
    end

    UseParticleFxAssetNextCall(wandFx.dict)
    local fx = StartParticleFxLoopedOnEntity(
        wandFx.particle,
        playerPed,
        0.1,
        0.0,
        0.0,
        0.0,
        0.0,
        0.0,
        wandFx.scale or 1.0,
        false, false, false
    )
    if fx then
        wandParticles[playerPed] = fx
        allParticles[fx] = { createdTime = GetGameTimer(), type = 'wand' }
    end
end

local function SpawnPathFx(startCoords, endCoords)
    local fxCfg = Config.Fx and Config.Fx.path
    if not fxCfg then return end

    RequestNamedPtfxAsset(fxCfg.dict)
    while not HasNamedPtfxAssetLoaded(fxCfg.dict) do
        Wait(0)
    end

    local dir = endCoords - startCoords
    local distance = #(dir)
    if distance <= 0.01 then return end
    dir = dir / distance

    local steps = fxCfg.steps or 24
    local stepDist = distance / steps

    for i = 1, steps do
        local t = i / steps
        local pos = startCoords + (dir * (stepDist * i))
        local spread = fxCfg.radius or 0.4
        pos = pos + vector3( (math.random() - 0.5) * spread, (math.random() - 0.5) * spread, (math.random() - 0.5) * 0.2 )

        UseParticleFxAssetNextCall(fxCfg.dict)
        local fx1 = StartParticleFxLoopedAtCoord(fxCfg.particlesMain or "veh_air_turbulance_water", pos.x, pos.y, pos.z, 0.0, 0.0, 0.0, fxCfg.scaleMain or 0.35, false, false, false, false)
        if fx1 then
            allParticles[fx1] = { createdTime = GetGameTimer(), type = 'path' }
        end
    end

    SetTimeout(2000, function()
        for handle, data in pairs(allParticles) do
            if data.type == 'path' then
                StopParticleFxLooped(handle, false)
                RemoveParticleFx(handle, false)
                allParticles[handle] = nil
            end
        end
        RemoveNamedPtfxAsset(fxCfg.dict)
    end)
end

local function SpawnArrivalFx(targetCoords)
    local fxCfg = Config.Fx and Config.Fx.arrival
    if not fxCfg then return end

    RequestNamedPtfxAsset(fxCfg.dict)
    while not HasNamedPtfxAssetLoaded(fxCfg.dict) do
        Wait(0)
    end

    UseParticleFxAssetNextCall(fxCfg.dict)
    local splash = StartParticleFxLoopedAtCoord(fxCfg.splash or "exp_water", targetCoords.x, targetCoords.y, targetCoords.z, 0.0, 0.0, 0.0, fxCfg.scale or 1.4, false, false, false, false)
    if splash then
        allParticles[splash] = { createdTime = GetGameTimer(), type = 'arrival' }
    end

    SetTimeout(2000, function()
        for handle, data in pairs(allParticles) do
            if data.type == 'arrival' then
                StopParticleFxLooped(handle, false)
                RemoveParticleFx(handle, false)
                allParticles[handle] = nil
            end
        end
        RemoveNamedPtfxAsset(fxCfg.dict)
    end)
end

local function FindTargetCoords()
    local camCoords = GetGameplayCamCoord()
    local camRot = GetGameplayCamRot(2)
    local dir = RotationToDirection(camRot)
    local maxDist = Config.Teleport.maxDistance or 60.0
    local hit, entityHit, coords = lib.raycast.cam(1 | 2 | 4 | 8 | 16, 4, maxDist)

    local function isValid(c)
        return c and (c.x ~= 0.0 or c.y ~= 0.0 or c.z ~= 0.0)
    end

    local target = isValid(coords) and vector3(coords.x, coords.y, coords.z)
    if not target then
        target = vector3(camCoords.x + dir.x * maxDist, camCoords.y + dir.y * maxDist, camCoords.z + dir.z * maxDist)
    end

    local found, groundZ = GetGroundZFor_3dCoord(target.x, target.y, target.z, false)
    if found then
        target = vector3(target.x, target.y, groundZ + (Config.Teleport.verticalOffset or 0.0))
    end

    return target
end

RegisterNetEvent('dvr_aquamens:prepareTeleport', function()
    local ped = cache.ped
    PlayWandFx(ped)
    -- PlaySoundUrl(('aquamens_cast_%s'):format(GetGameTimer()), 'YOUR_SOUND_URL_HERE', GetEntityCoords(ped))

    CreateThread(function()
        Wait(800)

        local startCoords = GetEntityCoords(ped)
        local target = FindTargetCoords()
        if not target then
            if Config.Messages and Config.Messages.noTarget then
                TriggerEvent('ox_lib:notify', Config.Messages.noTarget)
            end
            StopWandParticles(ped)
            return
        end

        TriggerServerEvent('dvr_aquamens:doTeleport', startCoords, target)
    end)
end)

RegisterNetEvent('dvr_aquamens:otherPlayerCasting', function(sourceServerId)
    local myId = GetPlayerServerId(PlayerId())
    if sourceServerId == myId then return end

    local casterPlayer = GetPlayerFromServerId(sourceServerId)
    if casterPlayer == -1 then return end
    local casterPed = GetPlayerPed(casterPlayer)
    if not DoesEntityExist(casterPed) then return end

    PlayWandFx(casterPed)

    SetTimeout(1500, function()
        StopWandParticles(casterPed)
    end)
end)

RegisterNetEvent('dvr_aquamens:runTeleport', function(sourceServerId, startCoords, targetCoords)
    if not targetCoords or not startCoords then return end

    local myServerId = GetPlayerServerId(PlayerId())
    local isLocal = (sourceServerId == myServerId)

    SpawnPathFx(startCoords, targetCoords)

    if isLocal then
        SetEntityCoords(cache.ped, targetCoords.x, targetCoords.y, targetCoords.z, false, false, false, false)
        StopWandParticles(cache.ped)
    else
        local casterPlayer = GetPlayerFromServerId(sourceServerId)
        if casterPlayer ~= -1 then
            local casterPed = GetPlayerPed(casterPlayer)
            if DoesEntityExist(casterPed) then
                SetEntityCoords(casterPed, targetCoords.x, targetCoords.y, targetCoords.z, false, false, false, false)
            end
        end
    end

    SpawnArrivalFx(targetCoords)
end)

AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    RemoveAllParticles()
end)
