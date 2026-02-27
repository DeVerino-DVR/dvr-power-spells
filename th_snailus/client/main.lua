---@diagnostic disable: undefined-global, trailing-space, unused-local, param-type-mismatch, missing-parameter
local GetPlayerFromServerId = GetPlayerFromServerId
local GetPlayerPed = GetPlayerPed
local PlayerId = PlayerId
local GetPlayerServerId = GetPlayerServerId
local DoesEntityExist = DoesEntityExist
local SetPedMoveRateOverride = SetPedMoveRateOverride
local SetRunSprintMultiplierForPlayer = SetRunSprintMultiplierForPlayer
local SetSwimMultiplierForPlayer = SetSwimMultiplierForPlayer
local ResetPedMovementClipset = ResetPedMovementClipset
local GetGameTimer = GetGameTimer
local TriggerServerEvent = TriggerServerEvent
local Wait = Wait
local CreateThread = CreateThread
local RegisterNetEvent = RegisterNetEvent
local AddEventHandler = AddEventHandler
local GetCurrentResourceName = GetCurrentResourceName
local pairs = pairs
local tonumber = tonumber

local slowedPlayers = {}
local localSlowEndTime = nil
local isLocalSlowed = false
local currentSpeedMultiplier = 1.0

local function IsLocalServerId(serverId)
    local playerId = PlayerId()
    if playerId == nil then
        return false
    end

    local localServerId = GetPlayerServerId(playerId)
    if localServerId == nil then
        return false
    end

    return serverId == localServerId
end

local function ApplySlowEffect(speedMultiplier)
    if not isLocalSlowed then
        isLocalSlowed = true
    end
    currentSpeedMultiplier = speedMultiplier or 0.5

    local playerId = PlayerId()
    local ped = GetPlayerPed(playerId)
    if ped and DoesEntityExist(ped) then
        SetPedMoveRateOverride(ped, currentSpeedMultiplier)
        SetRunSprintMultiplierForPlayer(playerId, currentSpeedMultiplier)
        SetSwimMultiplierForPlayer(playerId, currentSpeedMultiplier)
    end
end

local function RemoveSlowEffect()
    if isLocalSlowed then
        local playerId = PlayerId()
        local ped = GetPlayerPed(playerId)
        if ped and DoesEntityExist(ped) then
            SetPedMoveRateOverride(ped, 1.0)
            SetRunSprintMultiplierForPlayer(playerId, 1.0)
            SetSwimMultiplierForPlayer(playerId, 1.0)
            ResetPedMovementClipset(ped, 0.0)
        end
        isLocalSlowed = false
        localSlowEndTime = nil
        currentSpeedMultiplier = 1.0
    end
end

local function SetSlowState(serverId, enabled, durationMs, speedMultiplier)
    if not IsLocalServerId(serverId) then
        return
    end

    if enabled then
        slowedPlayers[serverId] = {
            speedMultiplier = speedMultiplier or 0.5,
            durationMs = durationMs
        }
        
        if durationMs == -1 then
            -- Toggle permanent
            localSlowEndTime = -1
        else
            -- Durée limitée
            local duration = tonumber(durationMs) or 15000
            localSlowEndTime = GetGameTimer() + duration
        end
        
        ApplySlowEffect(speedMultiplier)
    else
        slowedPlayers[serverId] = nil
        RemoveSlowEffect()
    end
end

RegisterNetEvent('th_snailus:sync', function(serverId, enabled, durationMs, speedMultiplier)
    SetSlowState(serverId, enabled == true, durationMs, speedMultiplier)
end)

-- Thread pour maintenir l'effet de ralentissement et gérer la durée
CreateThread(function()
    while true do
        Wait(0)

        if isLocalSlowed then
            local playerId = PlayerId()
            local ped = GetPlayerPed(playerId)
            if ped and DoesEntityExist(ped) then
                -- Réappliquer le ralentissement pour s'assurer qu'il reste actif
                SetPedMoveRateOverride(ped, currentSpeedMultiplier)
                SetRunSprintMultiplierForPlayer(playerId, currentSpeedMultiplier)
                SetSwimMultiplierForPlayer(playerId, currentSpeedMultiplier)
            end

            -- Vérifier si la durée est écoulée (sauf pour toggle permanent)
            if localSlowEndTime and localSlowEndTime ~= -1 then
                local now = GetGameTimer()
                if now >= localSlowEndTime then
                    local localServerId = GetPlayerServerId(PlayerId())
                    TriggerServerEvent('th_snailus:timeExpired', localServerId)
                    RemoveSlowEffect()
                end
            end
        else
            Wait(500)
        end
    end
end)

-- Demander la synchronisation au démarrage
CreateThread(function()
    Wait(2500)
    TriggerServerEvent('th_snailus:requestSync')
end)

-- Nettoyer à l'arrêt de la ressource
AddEventHandler('onResourceStop', function(resourceName)
    if resourceName ~= GetCurrentResourceName() then
        return
    end

    RemoveSlowEffect()

    slowedPlayers = {}
    localSlowEndTime = nil
    isLocalSlowed = false
    currentSpeedMultiplier = 1.0
end)
