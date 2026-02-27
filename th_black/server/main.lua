---@diagnostic disable: undefined-global, trailing-space, unused-local
local TriggerClientEvent = TriggerClientEvent
local RegisterNetEvent = RegisterNetEvent
local AddEventHandler = AddEventHandler
local Wait = Wait
local CreateThread = CreateThread
local GetResourceState = GetResourceState
local GetEntityCoords = GetEntityCoords
local GetPlayerPed = GetPlayerPed
local GetPlayerIdentifiers = GetPlayerIdentifiers
local pairs = pairs
local ipairs = ipairs
local type = type
local print = print

local blackPlayers = {}

local function IsMakeupProfile(value)
    return type(value) == 'table'
        and (value.overlay_id ~= nil or value.style ~= nil or value.opacity ~= nil or value.colour_type ~= nil)
end

local FALLBACK_PROFILE <const> = {
    overlay_id = 4,
    style = 49,
    opacity = 1.0,
    colour_type = 1,
    colour = 56,
    secondary_colour = 56
}

local function ResolveMakeupProfile(sourceId)
    local makeupCfg = Config and Config.Makeup

    if IsMakeupProfile(makeupCfg) then
        return makeupCfg
    end

    if type(makeupCfg) ~= 'table' then
        return FALLBACK_PROFILE
    end

    local identifiers = GetPlayerIdentifiers(sourceId)
    for _, identifier in ipairs(identifiers) do
        local profile = makeupCfg[identifier]
        if IsMakeupProfile(profile) then
            return profile
        end
    end

    local defaultProfile = makeupCfg.default
    if IsMakeupProfile(defaultProfile) then
        return defaultProfile
    end

    return FALLBACK_PROFILE
end

local function SyncPlayerState(target, serverId, enabled, profile)
    SetTimeout(3000, function()
        TriggerClientEvent('th_black:sync', target, serverId, enabled, profile)
    end)
end

local function TriggerTransitionFx(serverId, profile, enabled)
    SetTimeout(3000, function()
        TriggerClientEvent('th_black:transitionFx', -1, serverId, profile, enabled == true)
    end)
end

RegisterNetEvent('th_black:requestSync', function()
    local source <const> = source

    for serverId, profile in pairs(blackPlayers) do
        SyncPlayerState(source, serverId, true, profile)
    end
end)

AddEventHandler('playerJoining', function()
    local source <const> = source

    Wait(2000)

    for serverId, profile in pairs(blackPlayers) do
        SyncPlayerState(source, serverId, true, profile)
    end
end)

AddEventHandler('playerDropped', function()
    local source <const> = source

    if not blackPlayers[source] then
        return
    end

    blackPlayers[source] = nil
    SyncPlayerState(-1, source, false, nil)
end)

local function TogglePlayerMakeup(sourceId)
    local enabled = blackPlayers[sourceId] == nil

    if not enabled then
        local previousProfile = blackPlayers[sourceId]
        blackPlayers[sourceId] = nil
        SyncPlayerState(-1, sourceId, false, nil)
        TriggerTransitionFx(sourceId, previousProfile, false)
        return false
    end

    local profile <const> = ResolveMakeupProfile(sourceId)
    blackPlayers[sourceId] = profile
    SyncPlayerState(-1, sourceId, true, profile)
    TriggerTransitionFx(sourceId, profile, true)
    return true
end

local function RegisterBlackModule()
    local moduleData <const> = {
        id = Config.Module.id,
        name = Config.Module.name,
        description = Config.Module.description,
        icon = Config.Module.icon,
        color = Config.Module.color,
        cooldown = Config.Module.cooldown or 2000,
        type = Config.Module.type,
        isBasic = false,
        selfCast = true,
        image = Config.Module.image or 'images/power/th_black.png',
        professor = Config.Module.professor ~= false,
        soundType = '3d',
        sound = "YOUR_SOUND_URL_HERE",
        hidden = true,
        isWand = false,
        animation = nil,
        onCast = function(hasItem, raycast, source, target, level)
            local enabled = TogglePlayerMakeup(source)

            exports['th_power']:LogSpellCast({
                professor = { source = source },
                spell = { id = Config.Module.id, name = Config.Module.name, level = level or 0 },
                context = { temp = true, coords = source and GetEntityCoords(GetPlayerPed(source)) or nil }
            })

            return true
        end
    }

    exports['th_power']:registerModule(moduleData, 0)
    print('[th_black] Module enregistré avec succès')
end

CreateThread(function()
    while GetResourceState('th_power') ~= 'started' do
        Wait(100)
    end

    Wait(500)
    RegisterBlackModule()
end)

AddEventHandler('onResourceStart', function(resourceName)
    if resourceName == 'th_power' then
        Wait(1000)
        RegisterBlackModule()
    end
end)
