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

local blindedPlayers = {}

local function GetBlindDuration(level)
    local lvl = tonumber(level) or 1
    if lvl < 1 then lvl = 1 end
    if lvl > 5 then lvl = 5 end
    
    return Config.BlindDurations[lvl] or Config.BlindDurations[1]
end

local function SyncPlayerState(target, serverId, enabled, durationMs)
    TriggerClientEvent('dvr_aveuglus:sync', target, serverId, enabled, durationMs)
end

RegisterNetEvent('dvr_aveuglus:requestSync', function()
    local source <const> = source

    for serverId, data in pairs(blindedPlayers) do
        SyncPlayerState(source, serverId, true, data.duration)
    end
end)

RegisterNetEvent('dvr_aveuglus:timeExpired', function(serverId)
    if not blindedPlayers[serverId] then
        return
    end

    blindedPlayers[serverId] = nil
    SyncPlayerState(-1, serverId, false, 0)
end)

AddEventHandler('playerJoining', function()
    local source <const> = source

    Wait(2000)

    for serverId, data in pairs(blindedPlayers) do
        SyncPlayerState(source, serverId, true, data.duration)
    end
end)

AddEventHandler('playerDropped', function()
    local source <const> = source

    if not blindedPlayers[source] then
        return
    end

    blindedPlayers[source] = nil
    SyncPlayerState(-1, source, false, 0)
end)

local function ApplyBlindness(sourceId, targetId, level)
    local duration = GetBlindDuration(level)
    
    -- Si niveau 5 et déjà aveuglé, on toggle (désactive)
    if level == 5 and blindedPlayers[targetId] then
        blindedPlayers[targetId] = nil
        SyncPlayerState(-1, targetId, false, 0)
        return false
    end
    
    -- Sinon on applique/réapplique l'aveuglement
    blindedPlayers[targetId] = {
        caster = sourceId,
        level = level,
        duration = duration,
        timestamp = os.time()
    }
    
    SyncPlayerState(-1, targetId, true, duration)
    
    -- Si ce n'est pas un toggle permanent, programmer la fin
    if duration > 0 then
        SetTimeout(duration, function()
            if blindedPlayers[targetId] then
                blindedPlayers[targetId] = nil
                SyncPlayerState(-1, targetId, false, 0)
            end
        end)
    end
    
    return true
end

local function RegisterAveuglusModule()
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
        image = Config.Module.image or 'images/power/dvr_aveuglus.png',
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
            local applied = ApplyBlindness(source, targetServerId, level or 1)

            exports['dvr_power']:LogSpellCast({
                professor = { source = source },
                spell = { id = Config.Module.id, name = Config.Module.name, level = level or 1 },
                target = { source = targetServerId },
                context = { 
                    temp = level ~= 5,
                    duration = GetBlindDuration(level or 1),
                    coords = source and GetEntityCoords(GetPlayerPed(source)) or nil 
                }
            })

            return true
        end
    }

    exports['dvr_power']:registerModule(moduleData, 0)
    print('[dvr_aveuglus] Module enregistré avec succès')
end

CreateThread(function()
    while GetResourceState('dvr_power') ~= 'started' do
        Wait(100)
    end

    Wait(500)
    RegisterAveuglusModule()
end)

AddEventHandler('onResourceStart', function(resourceName)
    if resourceName == 'dvr_power' then
        Wait(1000)
        RegisterAveuglusModule()
    end
end)
