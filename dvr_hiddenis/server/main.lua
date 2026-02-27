---@diagnostic disable: undefined-global, trailing-space, unused-local
local hiddenPlayers = {}
local math_floor = math.floor

local function Notify(sourceId, payload)
    if not payload then
        return
    end
    TriggerClientEvent('ox_lib:notify', sourceId, payload)
end

local function clampLevel(level)
    local numeric = math_floor(tonumber(level) or 1)
    if numeric < 1 then
        return 1
    end
    if numeric > 5 then
        return 5
    end
    return numeric
end

local function GetEffectProfile(level)
    local lvl = clampLevel(level)
    local levelCfg = (Config.Levels or {})[lvl] or {}
    local duration = levelCfg.duration
    local isInfinite = levelCfg.infinite == true or (duration ~= nil and duration <= 0)
    if isInfinite then
        duration = 0
    else
        duration = duration ~= nil and duration or (Config.Effect and Config.Effect.duration) or 15000
    end
    return {
        duration = duration,
        alpha = levelCfg.alpha or (Config.Effect and Config.Effect.alpha) or 51,
        broadcast = levelCfg.broadcast or 'full',
        flickerInterval = levelCfg.flickerInterval or 0,
        flickerChance = levelCfg.flickerChance or 0.5,
        level = lvl,
        infinite = isInfinite
    }
end

RegisterNetEvent('dvr_hiddenis:setHidden', function(hidden)
    local source <const> = source
    if hidden then
        hiddenPlayers[source] = true
    else
        hiddenPlayers[source] = nil
    end

    TriggerClientEvent('dvr_hiddenis:syncHidden', -1, source, hidden)
end)

RegisterNetEvent('dvr_hiddenis:applyToTarget', function(targetServerId, profile)
    local _source <const> = source
    local target = targetServerId and targetServerId > 0 and targetServerId or _source
    TriggerClientEvent('dvr_hiddenis:apply', target, profile)
end)

AddEventHandler('playerJoining', function()
    local source <const> = source
    Wait(2000)
    for serverId, _ in pairs(hiddenPlayers) do
        TriggerClientEvent('dvr_hiddenis:syncHidden', source, serverId, true)
    end
end)

AddEventHandler('playerDropped', function()
    local source <const> = source
    if hiddenPlayers[source] then
        hiddenPlayers[source] = nil
        TriggerClientEvent('dvr_hiddenis:syncHidden', -1, source, false)
    end
end)

local function RegisterHiddenisModule()
    local moduleData <const> = {
        id = Config.Module.id,
        name = Config.Module.name,
        description = Config.Module.description,
        icon = Config.Module.icon,
        color = Config.Module.color,
        cooldown = Config.Module.cooldown or 20000,
        type = Config.Module.type,
        isBasic = false,
        image = Config.Module.image or 'images/power/shadowform.png',
        video = Config.Module.video or "YOUR_VIDEO_URL_HERE",
        professor = Config.Module.professor ~= false,
        soundType = '3d',
        sound = '',
        animation = {
            dict = (Config.Animation and Config.Animation.dict) or 'export@nib@wizardsv_wand_attack_b2',
            name = (Config.Animation and Config.Animation.name) or 'nib@wizardsv_wand_attack_b2',
            flag = (Config.Animation and Config.Animation.flag) or 0,
            duration = (Config.Animation and Config.Animation.duration) or 2200,
            speedMultiplier = (Config.Animation and Config.Animation.speedMultiplier) or 1.5,
            effectDelay = (Config.Animation and Config.Animation.effectDelay) or 2000
        },
        onCast = function(hasItem, raycast, source, target, level)
            if not hasItem then
                Notify(source, Config.Messages and Config.Messages.noWand)
                return false
            end

            local profile = GetEffectProfile(level)
            local spellLevel = level ~= nil and math.floor(tonumber(level) or 0) or GetCasterLevel(source)
            local data = {
                professor = { source = source },
                spell = { id = 'hiddenis', name = 'Hiddenis', level = spellLevel },
                context = { temp = false, coords = source and GetEntityCoords(GetPlayerPed(source)) or nil}
            }
            exports['dvr_power']:LogSpellCast(data)
            TriggerClientEvent('dvr_hiddenis:otherPlayerCasting', -1, source)
            TriggerClientEvent('dvr_hiddenis:prepareHidden', source, target or 0, profile)
            return true
        end
    }

    exports['dvr_power']:registerModule(moduleData, 0)
    print('[dvr_hiddenis] Module enregistré avec succès')
end

CreateThread(function()
    while GetResourceState('dvr_power') ~= 'started' do
        Wait(100)
    end

    Wait(500)
    RegisterHiddenisModule()
end)

AddEventHandler('onResourceStart', function(resourceName)
    if resourceName == 'dvr_power' then
        Wait(1000)
        RegisterHiddenisModule()
    end
end)
