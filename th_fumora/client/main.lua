---@diagnostic disable: undefined-global, trailing-space, unused-local, param-type-mismatch, missing-parameter
local activeScreens = {}
local allParticles = {}
local wandParticles = {}

local RequestNamedPtfxAsset = RequestNamedPtfxAsset
local HasNamedPtfxAssetLoaded = HasNamedPtfxAssetLoaded
local UseParticleFxAssetNextCall = UseParticleFxAssetNextCall
local StartParticleFxLoopedAtCoord = StartParticleFxLoopedAtCoord
local StartParticleFxLoopedOnEntity = StartParticleFxLoopedOnEntity
local StopParticleFxLooped = StopParticleFxLooped
local RemoveParticleFx = RemoveParticleFx
local SetParticleFxLoopedFarClipDist = SetParticleFxLoopedFarClipDist
local SetParticleFxLoopedAlpha = SetParticleFxLoopedAlpha
local SetParticleFxLoopedColour = SetParticleFxLoopedColour
local GetGameplayCamCoord = GetGameplayCamCoord
local GetGameplayCamRot = GetGameplayCamRot
local GetEntityCoords = GetEntityCoords
local GetGroundZFor_3dCoord = GetGroundZFor_3dCoord
local GetPlayerFromServerId = GetPlayerFromServerId
local GetPlayerPed = GetPlayerPed
local GetPlayerServerId = GetPlayerServerId
local PlayerId = PlayerId
local GetGameTimer = GetGameTimer
local vector3 = vector3

local math_pi = math.pi
local math_sin = math.sin
local math_cos = math.cos

local function RotationToDirection(rotation)
    local radX = rotation.x * (math_pi / 180.0)
    local radZ = rotation.z * (math_pi / 180.0)
    return vector3(-math_sin(radZ) * math.abs(math_cos(radX)), math_cos(radZ) * math.abs(math_cos(radX)), math_sin(radX))
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

local function PlayWandFxOnPed(ped)
    local fxCfg = Config.WandFx
    if not fxCfg then
        return
    end

    RequestNamedPtfxAsset(fxCfg.dict)
    while not HasNamedPtfxAssetLoaded(fxCfg.dict) do
        Wait(0)
    end

    UseParticleFxAssetNextCall(fxCfg.dict)
    local fx = StartParticleFxLoopedOnEntity(fxCfg.particle, ped, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, fxCfg.scale or 1.0, false, false, false)
    if fx then
        wandParticles[ped] = fx
        allParticles[fx] = { createdTime = GetGameTimer(), type = 'wand', ped = ped }
    end

    SetTimeout(fxCfg.duration or 3000, function()
        StopWandParticles(ped)
    end)
end

local function ResolveGroundCoords(coords)
    if not coords then
        return nil
    end

    local ok, groundZ = GetGroundZFor_3dCoord(coords.x, coords.y, coords.z + 15.0, false)
    if ok then
        coords = vector3(coords.x, coords.y, groundZ + 0.02)
    end

    return coords
end

local function FindGroundTarget()
    local camCoords = GetGameplayCamCoord()
    local camRot = GetGameplayCamRot(2)
    local dir = RotationToDirection(camRot)
    local maxDist = Config.Raycast.maxDistance or 60.0

    local _, _, coords = lib.raycast.cam(1 | 2 | 4 | 8 | 16, 4, maxDist)
    if coords and (coords.x ~= 0.0 or coords.y ~= 0.0 or coords.z ~= 0.0) then
        return ResolveGroundCoords(coords)
    end

    return ResolveGroundCoords(vector3(
        camCoords.x + dir.x * maxDist,
        camCoords.y + dir.y * maxDist,
        camCoords.z + dir.z * maxDist
    ))
end

local function CleanupScreen(screenId)
    local screen = activeScreens[screenId]
    if not screen then
        return
    end

    if screen.handles then
        for _, handle in ipairs(screen.handles) do
            if handle then
                StopParticleFxLooped(handle, false)
                RemoveParticleFx(handle, false)
                allParticles[handle] = nil
            end
        end
    end

    activeScreens[screenId] = nil
end

local function SpawnSmokeScreenAt(coords)
    local cfg = Config.SmokeScreen
    if not cfg then
        return {}
    end

    RequestNamedPtfxAsset(cfg.dict)
    while not HasNamedPtfxAssetLoaded(cfg.dict) do
        Wait(0)
    end

    local handles = {}

    UseParticleFxAssetNextCall(cfg.dict)
    local center = StartParticleFxLoopedAtCoord(cfg.particle, coords.x, coords.y, coords.z, 0.0, 0.0, 0.0, cfg.centerScale or 4.0, false, false, false, false)
    if center then
        if cfg.maxRenderDistance and SetParticleFxLoopedFarClipDist then
            SetParticleFxLoopedFarClipDist(center, cfg.maxRenderDistance)
        end
        handles[#handles + 1] = center
        allParticles[center] = { createdTime = GetGameTimer(), type = 'screen' }
    end

    local points = math.max(3, math.floor(cfg.pointsPerRing or 5))
    local radius = cfg.radius or 4.5
    local ringScale = cfg.ringScale or 3.8
    local zOffsets = cfg.zOffsets or { 0.15 }

    for zi = 1, #zOffsets do
        local zOff = zOffsets[zi] or 0.15
        for i = 1, points do
            local angle = (i / points) * (math_pi * 2.0)
            local x = coords.x + (math_cos(angle) * radius)
            local y = coords.y + (math_sin(angle) * radius)

            UseParticleFxAssetNextCall(cfg.dict)
            local fx = StartParticleFxLoopedAtCoord(cfg.particle, x, y, coords.z + zOff, 0.0, 0.0, 0.0, ringScale, false, false, false, false)
            if fx then
                if cfg.maxRenderDistance and SetParticleFxLoopedFarClipDist then
                    SetParticleFxLoopedFarClipDist(fx, cfg.maxRenderDistance)
                end
                handles[#handles + 1] = fx
                allParticles[fx] = { createdTime = GetGameTimer(), type = 'screen' }
            end
        end
    end

    return handles
end

RegisterNetEvent('th_fumora:prepare', function()
    local ped = cache.ped
    PlayWandFxOnPed(ped)

    CreateThread(function()
        Wait(850)

        local coords = FindGroundTarget()
        if not coords then
            if Config.Messages and Config.Messages.noGround then
                TriggerEvent('ox_lib:notify', Config.Messages.noGround)
            end
            StopWandParticles(ped)
            return
        end

        TriggerServerEvent('th_fumora:cast', coords)
    end)
end)

RegisterNetEvent('th_fumora:otherPlayerCasting', function(sourceServerId)
    local myId = GetPlayerServerId(PlayerId())
    if sourceServerId == myId then
        return
    end

    local casterPlayer = GetPlayerFromServerId(sourceServerId)
    if casterPlayer == -1 then
        return
    end

    local casterPed = GetPlayerPed(casterPlayer)
    if not DoesEntityExist(casterPed) then
        return
    end

    PlayWandFxOnPed(casterPed)
end)

RegisterNetEvent('th_fumora:spawn', function(screenId, coords, durationMs)
    if not screenId or not coords then
        return
    end

    if activeScreens[screenId] then
        return
    end

    local cfg = Config.SmokeScreen or {}
    local myCoords = GetEntityCoords(cache.ped)
    local dist = #(myCoords - vector3(coords.x, coords.y, coords.z))
    if cfg.maxRenderDistance and dist > cfg.maxRenderDistance then
        return
    end

    local groundCoords = ResolveGroundCoords(vector3(coords.x, coords.y, coords.z))
    if not groundCoords then
        return
    end

    local handles = SpawnSmokeScreenAt(groundCoords)
    activeScreens[screenId] = {
        handles = handles,
        expiresAt = GetGameTimer() + (durationMs or (cfg.duration or 10000))
    }

    SetTimeout(durationMs or (cfg.duration or 10000), function()
        CleanupScreen(screenId)
    end)
end)

AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then
        return
    end

    StopWandParticles(cache.ped)
    local ids = {}
    for screenId, _ in pairs(activeScreens) do
        ids[#ids + 1] = screenId
    end
    for i = 1, #ids do
        CleanupScreen(ids[i])
    end
    activeScreens = {}

    for handle, _ in pairs(allParticles) do
        StopParticleFxLooped(handle, false)
        RemoveParticleFx(handle, false)
    end
    allParticles = {}

    RemoveNamedPtfxAsset('core')
end)

