---@diagnostic disable: undefined-global, trailing-space, unused-local, param-type-mismatch, missing-parameter
local wandParticles = {}
local allParticles = {}
local activeSpeed = nil

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
local GetPlayerFromServerId = GetPlayerFromServerId
local GetPlayerPed = GetPlayerPed
local GetPlayerServerId = GetPlayerServerId
local PlayerId = PlayerId
local PlayerPedId = PlayerPedId
local RestorePlayerStamina = RestorePlayerStamina
local StatSetInt = StatSetInt
local vector3 = vector3

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

local function ApplySpeedBuff(duration, isRemote)
    if activeSpeed then
        activeSpeed.cancelled = true
    end
    local state = { cancelled = false }
    activeSpeed = state

    local player = PlayerPedId()
    local runMult = math.min(1.49, Config.Buff.sprintMultiplier or 1.49)
    local swimMult = math.min(1.49, Config.Buff.speedMultiplier or 1.49)
    SetRunSprintMultiplierForPlayer(PlayerId(), runMult)
    SetSwimMultiplierForPlayer(PlayerId(), swimMult)
    RestorePlayerStamina(PlayerId(), 1.0)

    CreateThread(function()
        Wait(duration or 30000)
        if state.cancelled then return end
        SetRunSprintMultiplierForPlayer(PlayerId(), 1.0)
        SetSwimMultiplierForPlayer(PlayerId(), 1.0)
        activeSpeed = nil
    end)
end

RegisterNetEvent('th_speedom:prepareSpeed', function(targetId)
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

        TriggerServerEvent('th_speedom:applySpeed', targetServerId)
    end)
end)

RegisterNetEvent('th_speedom:otherPlayerCasting', function(sourceServerId)
    local myId = GetPlayerServerId(PlayerId())
    if sourceServerId == myId then return end

    local casterPlayer = GetPlayerFromServerId(sourceServerId)
    if casterPlayer == -1 then return end
    local casterPed = GetPlayerPed(casterPlayer)
    if not DoesEntityExist(casterPed) then return end
end)

RegisterNetEvent('th_speedom:grantSpeed', function(duration, fromOther)
    ApplySpeedBuff(duration or (Config.Buff.duration or 30000), fromOther)
end)

AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    SetRunSprintMultiplierForPlayer(PlayerId(), 1.0)
    SetSwimMultiplierForPlayer(PlayerId(), 1.0)
end)
