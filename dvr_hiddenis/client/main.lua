---@diagnostic disable: undefined-global, trailing-space, unused-local, param-type-mismatch, missing-parameter
local PlayerPedId = PlayerPedId
local DoesEntityExist = DoesEntityExist
local SetEntityAlpha = SetEntityAlpha
local ResetEntityAlpha = ResetEntityAlpha
local GetGameTimer = GetGameTimer
local GetPlayerServerId = GetPlayerServerId
local PlayerId = PlayerId
local GetPlayerPed = GetPlayerPed
local GetActivePlayers = GetActivePlayers
local NetworkGetPlayerIndexFromPed = NetworkGetPlayerIndexFromPed
local GetGameplayCamCoord = GetGameplayCamCoord
local GetGameplayCamRot = GetGameplayCamRot
local GetPlayerFromServerId = GetPlayerFromServerId
local math_random = math.random

local activeEffect = nil
local hiddenPlayers = {}
local amIHidden = false

local myServerId = nil
CreateThread(function()
    while not myServerId do
        myServerId = GetPlayerServerId(PlayerId())
        Wait(100)
    end
end)

local function RotationToDirection(rotation)
    local radX = rotation.x * (math.pi / 180.0)
    local radZ = rotation.z * (math.pi / 180.0)
    return vector3(-math.sin(radZ) * math.abs(math.cos(radX)), math.cos(radZ) * math.abs(math.cos(radX)), math.sin(radX))
end

local function FindTargetPlayer()
    local maxDist = Config.Raycast and Config.Raycast.maxDistance or 60.0
    local hit, entityHit = lib.raycast.cam(1 | 2 | 4 | 8 | 16, 4, maxDist)
    if not entityHit or not DoesEntityExist(entityHit) or not IsPedAPlayer(entityHit) then
        return nil
    end

    local idx = NetworkGetPlayerIndexFromPed(entityHit)
    if idx == -1 then return nil end
    return GetPlayerServerId(idx)
end

local function SetPlayerHidden(serverId, hidden)
    if serverId == myServerId then return end

    for _, playerId in ipairs(GetActivePlayers()) do
        local playerServerId = GetPlayerServerId(playerId)
        if playerServerId == serverId then
            local ped = GetPlayerPed(playerId)
            if ped and DoesEntityExist(ped) then
                if hidden then
                    -- Si JE suis aussi en hiddenis, je vois les autres en transparent (alpha 51)
                    -- Sinon, je les vois invisibles (alpha 0)
                    local alpha = amIHidden and 51 or 0
                    SetEntityAlpha(ped, alpha, false)
                else
                    ResetEntityAlpha(ped)
                end
            end
            break
        end
    end
end

-- Réappliquer la visibilité à tous les joueurs cachés (quand mon statut change)
local function ReapplyHiddenVisibility()
    for serverId, _ in pairs(hiddenPlayers) do
        if serverId ~= myServerId then
            SetPlayerHidden(serverId, true)
        end
    end
end

CreateThread(function()
    while true do
        Wait(500)
        for serverId, _ in pairs(hiddenPlayers) do
            if serverId ~= myServerId then
                SetPlayerHidden(serverId, true)
            end
        end
    end
end)

RegisterNetEvent('dvr_hiddenis:syncHidden', function(serverId, hidden)
    if hidden then
        hiddenPlayers[serverId] = true
    else
        hiddenPlayers[serverId] = nil
    end
    SetPlayerHidden(serverId, hidden)
end)

local function ResolveEffectProfile(payload, fallbackAlpha)
    local defaultDuration = (Config.Effect and Config.Effect.duration) or 15000
    local defaultAlpha = fallbackAlpha or (Config.Effect and Config.Effect.alpha) or 51
    local profile = {
        duration = defaultDuration,
        alpha = defaultAlpha,
        broadcast = 'full',
        flickerInterval = 0,
        flickerChance = 0.5,
        level = 1,
        infinite = false
    }

    if type(payload) == 'table' then
        profile.duration = payload.duration ~= nil and payload.duration or defaultDuration
        profile.alpha = payload.alpha or defaultAlpha
        profile.broadcast = payload.broadcast or 'full'
        profile.flickerInterval = payload.flickerInterval or 0
        profile.flickerChance = payload.flickerChance or 0.5
        profile.level = payload.level or 1
        profile.infinite = payload.infinite or (profile.duration ~= nil and profile.duration <= 0)
        return profile
    end

    profile.duration = payload or defaultDuration
    profile.infinite = profile.duration ~= nil and profile.duration <= 0
    return profile
end

local function ClearEffect()
    if not activeEffect then
        return
    end

    local ped = activeEffect.ped
    if ped and DoesEntityExist(ped) then
        ResetEntityAlpha(ped)
    end

    TriggerServerEvent('dvr_hiddenis:setHidden', false)
    activeEffect = nil

    -- Je ne suis plus caché, réappliquer la visibilité aux autres joueurs cachés
    amIHidden = false
    ReapplyHiddenVisibility()
end

local function ApplyHiddenis(profileOrDuration, alpha)
    if activeEffect then
        ClearEffect()
        return
    end

    local profile = ResolveEffectProfile(profileOrDuration, alpha)
    local ped = cache and cache.ped or PlayerPedId()
    if not ped or not DoesEntityExist(ped) then
        return
    end
    local expiresAt = nil
    if not profile.infinite and profile.duration and profile.duration > 0 then
        expiresAt = GetGameTimer() + profile.duration
    end

    local data = {
        ped = ped,
        expiresAt = expiresAt,
        profile = profile
    }

    local animCfg = Config.Animation or (Config.Module and Config.Module.animation) or {}
    local effectDelay = animCfg.effectDelay or animCfg.duration or 2000
    local buffer = 0
    effectDelay = effectDelay + buffer

    CreateThread(function()
        if effectDelay > 0 then
            Wait(effectDelay)
        end

        SetEntityAlpha(ped, profile.alpha or 51, false)

        activeEffect = data

        -- Je suis maintenant caché, réappliquer la visibilité aux autres joueurs cachés
        amIHidden = true
        ReapplyHiddenVisibility()

        if profile.broadcast == 'full' then
            TriggerServerEvent('dvr_hiddenis:setHidden', true)
        elseif profile.broadcast == 'flicker' then
            CreateThread(function()
                while activeEffect == data do
                    local shouldHide = math_random() < (profile.flickerChance or 0.5)
                    TriggerServerEvent('dvr_hiddenis:setHidden', shouldHide)
                    Wait(profile.flickerInterval > 0 and profile.flickerInterval or 1500)
                end
            end)
        else
            TriggerServerEvent('dvr_hiddenis:setHidden', false)
        end

        while activeEffect == data and (not data.expiresAt or GetGameTimer() < data.expiresAt) do
            Wait(250)
        end
        if activeEffect == data and data.expiresAt then
            ClearEffect()
        end
    end)
end

RegisterNetEvent('dvr_hiddenis:prepareHidden', function(targetId, profile)
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

        TriggerServerEvent('dvr_hiddenis:applyToTarget', targetServerId, profile)
    end)
end)

RegisterNetEvent('dvr_hiddenis:otherPlayerCasting', function(sourceServerId)
    local myId = GetPlayerServerId(PlayerId())
    if sourceServerId == myId then return end

    local casterPlayer = GetPlayerFromServerId(sourceServerId)
    if casterPlayer == -1 then return end
    local casterPed = GetPlayerPed(casterPlayer)
    if not DoesEntityExist(casterPed) then return end
end)

RegisterNetEvent('dvr_hiddenis:apply', function(profileOrDuration, alpha)
    ApplyHiddenis(profileOrDuration, alpha)
end)

AddEventHandler('onResourceStop', function(resourceName)
    if resourceName ~= GetCurrentResourceName() then
        return
    end
    ClearEffect()
end)
