---@diagnostic disable: undefined-global, trailing-space, unused-local, param-type-mismatch, missing-parameter
local GetPlayerFromServerId = GetPlayerFromServerId
local GetPlayerPed = GetPlayerPed
local PlayerId = PlayerId
local GetPlayerServerId = GetPlayerServerId
local DoesEntityExist = DoesEntityExist
local DoScreenFadeOut = DoScreenFadeOut
local DoScreenFadeIn = DoScreenFadeIn
local IsScreenFadedOut = IsScreenFadedOut
local IsScreenFadingOut = IsScreenFadingOut
local IsScreenFadingIn = IsScreenFadingIn
local GetGameTimer = GetGameTimer
local TriggerServerEvent = TriggerServerEvent
local Wait = Wait
local CreateThread = CreateThread
local RegisterNetEvent = RegisterNetEvent
local AddEventHandler = AddEventHandler
local GetCurrentResourceName = GetCurrentResourceName
local pairs = pairs
local tonumber = tonumber

local blindedPlayers = {}
local localBlindEndTime = nil
local isLocalBlinded = false

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

local function ApplyBlindEffect()
    if not isLocalBlinded then
        DoScreenFadeOut(500)
        isLocalBlinded = true
    end
end

local function RemoveBlindEffect()
    if isLocalBlinded then
        DoScreenFadeIn(1000)
        isLocalBlinded = false
        localBlindEndTime = nil
    end
end

local function SetBlindState(serverId, enabled, durationMs)
    if not IsLocalServerId(serverId) then
        return
    end

    if enabled then
        blindedPlayers[serverId] = true
        
        if durationMs == -1 then
            -- Toggle permanent
            localBlindEndTime = -1
        else
            -- Durée limitée
            local duration = tonumber(durationMs) or 10000
            localBlindEndTime = GetGameTimer() + duration
        end
        
        ApplyBlindEffect()
    else
        blindedPlayers[serverId] = nil
        RemoveBlindEffect()
    end
end

RegisterNetEvent('th_aveuglus:sync', function(serverId, enabled, durationMs)
    SetBlindState(serverId, enabled == true, durationMs)
end)

-- Thread pour maintenir l'effet d'aveuglement et gérer la durée
CreateThread(function()
    while true do
        Wait(100)
        
        if isLocalBlinded then
            -- Maintenir l'écran noir
            if not IsScreenFadedOut() and not IsScreenFadingOut() then
                DoScreenFadeOut(0)
            end
            
            -- Vérifier si la durée est écoulée (sauf pour toggle permanent)
            if localBlindEndTime and localBlindEndTime ~= -1 then
                local now = GetGameTimer()
                if now >= localBlindEndTime then
                    local localServerId = GetPlayerServerId(PlayerId())
                    TriggerServerEvent('th_aveuglus:timeExpired', localServerId)
                    RemoveBlindEffect()
                end
            end
        end
    end
end)

-- Demander la synchronisation au démarrage
CreateThread(function()
    Wait(2500)
    TriggerServerEvent('th_aveuglus:requestSync')
end)

-- Nettoyer à l'arrêt de la ressource
AddEventHandler('onResourceStop', function(resourceName)
    if resourceName ~= GetCurrentResourceName() then
        return
    end

    if isLocalBlinded then
        DoScreenFadeIn(500)
    end

    blindedPlayers = {}
    localBlindEndTime = nil
    isLocalBlinded = false
end)
