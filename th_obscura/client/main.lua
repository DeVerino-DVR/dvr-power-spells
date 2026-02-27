---@diagnostic disable: undefined-global, trailing-space, unused-local, param-type-mismatch, missing-parameter
local blackoutTimers = {}
local wandParticles = {}
local RequestNamedPtfxAsset = RequestNamedPtfxAsset
local HasNamedPtfxAssetLoaded = HasNamedPtfxAssetLoaded
local UseParticleFxAssetNextCall = UseParticleFxAssetNextCall
local StartParticleFxLoopedOnEntity = StartParticleFxLoopedOnEntity
local StopParticleFxLooped = StopParticleFxLooped
local RemoveParticleFx = RemoveParticleFx
local RemoveNamedPtfxAsset = RemoveNamedPtfxAsset
local SetArtificialLightsState = SetArtificialLightsState
local GetGameTimer = GetGameTimer
local GetPedBoneIndex = GetPedBoneIndex
local GetWorldPositionOfEntityBone = GetWorldPositionOfEntityBone
local GetPlayerFromServerId = GetPlayerFromServerId
local GetPlayerPed = GetPlayerPed
local GetPlayerServerId = GetPlayerServerId
local PlayerId = PlayerId
local SetTimeout = SetTimeout

local function PlayWandFx(playerPed)
    RequestNamedPtfxAsset('core')
    while not HasNamedPtfxAssetLoaded('core') do
        Wait(0)
    end

    UseParticleFxAssetNextCall('core')
    local fx = StartParticleFxLoopedOnEntity('ent_amb_tnl_bubbles_sml', playerPed, 0.1, 0.0, 0.0, 0.0, 0.0, 0.0, 0.8, false, false, false)
    if fx then
        wandParticles[playerPed] = fx
    end
end

local function StopWandFx(playerPed)
    local fx = wandParticles[playerPed]
    if fx then
        StopParticleFxLooped(fx, false)
        RemoveParticleFx(fx, false)
        wandParticles[playerPed] = nil
    end
    RemoveNamedPtfxAsset('core')
end

local function hasActiveBlackout()
    local now = GetGameTimer()
    for i = 1, #blackoutTimers do
        if blackoutTimers[i] > now then
            return true
        end
    end
    return false
end

local function addTimedBlackout(duration)
    local endTime = GetGameTimer() + duration
    blackoutTimers[#blackoutTimers + 1] = endTime
    SetArtificialLightsState(true)

    CreateThread(function()
        while GetGameTimer() < endTime do
            Wait(500)
        end

        local now = GetGameTimer()
        local remaining = {}
        for _, t in ipairs(blackoutTimers) do
            if t > now then
                remaining[#remaining + 1] = t
            end
        end
        blackoutTimers = remaining

        if #blackoutTimers == 0 then
            SetArtificialLightsState(false)
        else
            SetArtificialLightsState(true)
        end
    end)
end

RegisterNetEvent('th_obscura:prepareBlackout', function(level)
    local ped = cache.ped
    PlayWandFx(ped)
    local lvl = math.max(math.floor(tonumber(level) or 1), 1)

    CreateThread(function()
        Wait(4000)
        TriggerServerEvent('th_obscura:startBlackout', lvl)
        Wait(800)
        StopWandFx(ped)
    end)
end)

RegisterNetEvent('th_obscura:otherPlayerCasting', function(sourceServerId)
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

RegisterNetEvent('th_obscura:applyBlackout', function(sourceServerId, settings)
    settings = settings or {}
    local mode = settings.mode or 'blackout'

    if mode == 'flash' then
        local flashDuration = settings.flashDuration or 800
        SetArtificialLightsState(true)
        CreateThread(function()
            Wait(flashDuration)
            if hasActiveBlackout() then
                SetArtificialLightsState(true)
            else
                SetArtificialLightsState(false)
            end
        end)
        return
    end

    if mode == 'blink' then
        local blinkInterval = settings.blinkInterval or 400
        local blinkCount = settings.blinkCount or 8
        CreateThread(function()
            SetArtificialLightsState(true)
            local lightsOff = true
            for _ = 1, blinkCount do
                Wait(blinkInterval)
                lightsOff = not lightsOff
                if lightsOff then
                    SetArtificialLightsState(true)
                elseif not hasActiveBlackout() then
                    SetArtificialLightsState(false)
                end
            end
            if hasActiveBlackout() then
                SetArtificialLightsState(true)
            else
                SetArtificialLightsState(false)
            end
        end)
        return
    end

    local duration = settings.duration or Config.Duration or 30000
    addTimedBlackout(duration)
end)

AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    SetArtificialLightsState(false)
    for _, fx in pairs(wandParticles) do
        StopParticleFxLooped(fx, false)
        RemoveParticleFx(fx, false)
    end
    wandParticles = {}
    RemoveNamedPtfxAsset('core')
end)
