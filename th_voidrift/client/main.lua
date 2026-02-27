---@diagnostic disable: undefined-global, trailing-space, unused-local, param-type-mismatch, missing-parameter
local wandParticles = {}
local allParticles = {}
local rifts = {}

local RequestNamedPtfxAsset = RequestNamedPtfxAsset
local HasNamedPtfxAssetLoaded = HasNamedPtfxAssetLoaded
local UseParticleFxAssetNextCall = UseParticleFxAssetNextCall
local StartParticleFxLoopedAtCoord = StartParticleFxLoopedAtCoord
local StopParticleFxLooped = StopParticleFxLooped
local RemoveParticleFx = RemoveParticleFx
local RemoveNamedPtfxAsset = RemoveNamedPtfxAsset
local GetGameplayCamCoord = GetGameplayCamCoord
local GetGameplayCamRot = GetGameplayCamRot
local GetPlayerFromServerId = GetPlayerFromServerId
local GetPlayerPed = GetPlayerPed
local GetPlayerServerId = GetPlayerServerId
local PlayerId = PlayerId
local SetEntityCoords = SetEntityCoords
local GetEntityCoords = GetEntityCoords
local SetEntityVelocity = SetEntityVelocity
local ApplyForceToEntity = ApplyForceToEntity
local DoesEntityExist = DoesEntityExist
local vector3 = vector3
local ShakeGameplayCam = ShakeGameplayCam

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
    local fx = wandParticles[playerPed]
    if fx then
        StopParticleFxLooped(fx, false)
        RemoveParticleFx(fx, false)
        wandParticles[playerPed] = nil
        allParticles[fx] = nil
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
    while not HasNamedPtfxAssetLoaded('core') do Wait(0) end
    UseParticleFxAssetNextCall('core')
    local fx = StartParticleFxLoopedAtCoord('ent_amb_tnl_bubbles_sml', GetEntityCoords(playerPed), 0.0, 0.0, 0.0, 0.9, false, false, false, false)
    if fx then
        wandParticles[playerPed] = fx
        allParticles[fx] = { createdTime = GetGameTimer(), type = 'wand' }
    end
end

local function SpawnRiftFx(coords)
    local fxCfg = Config.FX
    RequestNamedPtfxAsset('core')
    while not HasNamedPtfxAssetLoaded('core') do Wait(0) end

    UseParticleFxAssetNextCall('core')
    local riftFx = StartParticleFxLoopedAtCoord(fxCfg.rift.particle, coords.x, coords.y, coords.z, 0.0, 0.0, 0.0, fxCfg.rift.scale or 2.0, false, false, false, false)
    if riftFx then
        allParticles[riftFx] = { createdTime = GetGameTimer(), type = 'rift' }
    end

    UseParticleFxAssetNextCall('core')
    local auraFx = StartParticleFxLoopedAtCoord(fxCfg.aura.particle, coords.x, coords.y, coords.z + 0.2, 0.0, 0.0, 0.0, fxCfg.aura.scale or 1.1, false, false, false, false)
    if auraFx then
        allParticles[auraFx] = { createdTime = GetGameTimer(), type = 'rift' }
    end

    return { riftFx, auraFx }
end

local function ExplodeRift(coords, sourceServerId)
    local myId = GetPlayerServerId(PlayerId())
    if sourceServerId and sourceServerId == myId then
        return
    end

    if HasProtheaShield() then
        return
    end

    local fxCfg = Config.FX
    RequestNamedPtfxAsset('core')
    while not HasNamedPtfxAssetLoaded('core') do Wait(0) end

    UseParticleFxAssetNextCall('core')
    StartParticleFxLoopedAtCoord(fxCfg.explode.particle, coords.x, coords.y, coords.z, 0.0, 0.0, 0.0, fxCfg.explode.scale or 1.2, false, false, false, false)

    local myCoords = GetEntityCoords(cache.ped)
    local dist = #(myCoords - coords)
    if dist < Config.Rift.explodeRadius then
        local shake = math.max(0.1, 0.45 * (1.0 - (dist / Config.Rift.explodeRadius)))
        ShakeGameplayCam('MEDIUM_EXPLOSION_SHAKE', shake)
    end
end

local function PullEntities(coords, sourceServerId)
    local myId = GetPlayerServerId(PlayerId())
    if sourceServerId and sourceServerId == myId then
        return
    end

    if HasProtheaShield() then
        return
    end

    local pullRadius = Config.Rift.pullRadius or 12.0
    local pullForce = Config.Rift.pullForce or 2.8

    local ped = cache.ped
    local pedCoords = GetEntityCoords(ped)
    local dist = #(pedCoords - coords)
    if dist < pullRadius then
        local dir = (coords - pedCoords)
        local d = #dir
        if d > 0.001 then
            dir = dir / d
            local force = dir * pullForce
            ApplyForceToEntity(ped, 1, force.x, force.y, force.z, 0.0, 0.0, 0.0, 0, false, true, true, false, true)
        end
    end
end

local function FindTargetCoords()
    local camCoords = GetGameplayCamCoord()
    local camRot = GetGameplayCamRot(2)
    local dir = RotationToDirection(camRot)
    local maxDist = Config.Rift.pullRadius or 12.0

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

RegisterNetEvent('th_voidrift:prepareRift', function()
    local ped = cache.ped
    PlayWandFx(ped)

    CreateThread(function()
        Wait(800)
        local targetCoords = FindTargetCoords()
        TriggerServerEvent('th_voidrift:spawnRift', targetCoords)
        SetTimeout(800, function()
            StopWandFx(ped)
        end)
    end)
end)

RegisterNetEvent('th_voidrift:otherPlayerCasting', function(sourceServerId)
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

RegisterNetEvent('th_voidrift:createRift', function(sourceServerId, targetCoords)
    if not targetCoords then return end

    local effects = SpawnRiftFx(targetCoords)
    local endTime = GetGameTimer() + (Config.Rift.duration or 4500)
    local explodeAt = GetGameTimer() + (Config.Rift.explodeAfter or 3500)

    rifts[#rifts + 1] = {
        coords = targetCoords,
        effects = effects,
        endTime = endTime,
        explodeAt = explodeAt,
        exploded = false,
        sourceServerId = sourceServerId
    }
end)

CreateThread(function()
    while true do
        Wait(0)
        local now = GetGameTimer()
        for i = #rifts, 1, -1 do
            local r = rifts[i]
            if now >= (r.explodeAt or 0) and not r.exploded then
                r.exploded = true
                ExplodeRift(r.coords, r.sourceServerId)
            end

            if now < (r.endTime or 0) then
                PullEntities(r.coords, r.sourceServerId)
            else
                if r.effects then
                    for _, fx in ipairs(r.effects) do
                        if fx then
                            StopParticleFxLooped(fx, false)
                            RemoveParticleFx(fx, false)
                            allParticles[fx] = nil
                        end
                    end
                end
                table.remove(rifts, i)
            end
        end
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
