---@diagnostic disable: undefined-global, trailing-space, unused-local
local TriggerClientEvent = TriggerClientEvent
local RegisterNetEvent = RegisterNetEvent
local AddEventHandler = AddEventHandler
local Wait = Wait
local CreateThread = CreateThread
local GetResourceState = GetResourceState
local GetEntityCoords = GetEntityCoords
local GetPlayerPed = GetPlayerPed
local pairs = pairs
local tonumber = tonumber
local type = type
local print = print

local slowedPlayers = {}

local function GetSlowDuration(level)
    local lvl = tonumber(level) or 1
    if lvl < 1 then lvl = 1 end
    if lvl > 5 then lvl = 5 end
    
    return Config.SlowDurations[lvl] or Config.SlowDurations[1]
end

local function GetSpeedMultiplier(level)
    local lvl = tonumber(level) or 1
    if lvl < 1 then lvl = 1 end
    if lvl > 5 then lvl = 5 end
    
    return Config.SpeedMultipliers[lvl] or Config.SpeedMultipliers[1]
end

local function SyncPlayerState(target, serverId, enabled, durationMs, speedMultiplier)
    TriggerClientEvent('dvr_snailus:sync', target, serverId, enabled, durationMs, speedMultiplier)
end

RegisterNetEvent('dvr_snailus:requestSync', function()
    local source <const> = source

    for serverId, data in pairs(slowedPlayers) do
        SyncPlayerState(source, serverId, true, data.duration, data.speedMultiplier)
    end
end)

RegisterNetEvent('dvr_snailus:timeExpired', function(serverId)
    if not slowedPlayers[serverId] then
        return
    end

    slowedPlayers[serverId] = nil
    SyncPlayerState(-1, serverId, false, 0, 1.0)
end)

AddEventHandler('playerJoining', function()
    local source <const> = source

    Wait(2000)

    for serverId, data in pairs(slowedPlayers) do
        SyncPlayerState(source, serverId, true, data.duration, data.speedMultiplier)
    end
end)

AddEventHandler('playerDropped', function()
    local source <const> = source

    if not slowedPlayers[source] then
        return
    end

    slowedPlayers[source] = nil
    SyncPlayerState(-1, source, false, 0, 1.0)
end)

local function ApplySlowness(sourceId, targetId, level)
    local duration = GetSlowDuration(level)
    local speedMultiplier = GetSpeedMultiplier(level)
    
    -- Si niveau 5 et déjà ralenti, on toggle (désactive)
    if level == 5 and slowedPlayers[targetId] then
        slowedPlayers[targetId] = nil
        SyncPlayerState(-1, targetId, false, 0, 1.0)
        return false
    end
    
    -- Sinon on applique/réapplique le ralentissement
    slowedPlayers[targetId] = {
        caster = sourceId,
        level = level,
        duration = duration,
        speedMultiplier = speedMultiplier,
        timestamp = os.time()
    }
    
    SyncPlayerState(-1, targetId, true, duration, speedMultiplier)
    
    -- Si ce n'est pas un toggle permanent, programmer la fin
    if duration > 0 then
        SetTimeout(duration, function()
            if slowedPlayers[targetId] then
                slowedPlayers[targetId] = nil
                SyncPlayerState(-1, targetId, false, 0, 1.0)
            end
        end)
    end
    
    return true
end

local function RegisterSnailusModule()
    local anim <const> = Config.Module.animation or {}
    local moduleData <const> = {
        id = Config.Module.id,
        name = Config.Module.name,
        description = Config.Module.description,
        icon = Config.Module.icon,
        color = Config.Module.color,
        cooldown = Config.Module.cooldown or 3000,
        type = Config.Module.type,
        isBasic = false,
        selfCast = false,
        image = Config.Module.image or 'images/power/dvr_snailus.png',
        professor = Config.Module.professor ~= false,
        sound = "YOUR_SOUND_URL_HERE",
        soundType = "3d",
        hidden = false,
        isWand = true,
        animation = {
            dict = anim.dict,
            name = anim.name,
            flag = anim.flag or 0,
            duration = anim.duration or 1500,
            speedMultiplier = anim.speedMultiplier or 1.0
        },
        onCast = function(hasItem, raycast, source, target, level)
            if not target or target == 0 then
                return false
            end
            
            local targetServerId = target
            local applied = ApplySlowness(source, targetServerId, level or 1)

            exports['dvr_power']:LogSpellCast({
                professor = { source = source },
                spell = { id = Config.Module.id, name = Config.Module.name, level = level or 1 },
                target = { source = targetServerId },
                context = { 
                    temp = level ~= 5,
                    duration = GetSlowDuration(level or 1),
                    speedMultiplier = GetSpeedMultiplier(level or 1),
                    coords = source and GetEntityCoords(GetPlayerPed(source)) or nil 
                }
            })

            return true
        end
    }

    exports['dvr_power']:registerModule(moduleData, 0)
    print('[dvr_snailus] Module enregistré avec succès')
end

CreateThread(function()
    while GetResourceState('dvr_power') ~= 'started' do
        Wait(100)
    end

    Wait(500)
    RegisterSnailusModule()
end)

AddEventHandler('onResourceStart', function(resourceName)
    if resourceName == 'dvr_power' then
        Wait(1000)
        RegisterSnailusModule()
    end
end)
