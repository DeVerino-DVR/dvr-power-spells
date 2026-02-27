---@diagnostic disable: undefined-global, trailing-space, unused-local, param-type-mismatch, missing-parameter
local SPELL_ID <const> = Config.Module.id or 'liquid'
local EFFECT_DURATION <const> = Config.Effect and Config.Effect.duration or 20000
local BURST_COOLDOWN <const> = Config.Effect and Config.Effect.burstCooldown or 1200

local activePlayers = {}
local lastBurst = {}

local os_time = os.time
local tonumber = tonumber
local vector3 = vector3

local function Notify(sourceId, payload)
    if not payload then
        return
    end
    TriggerClientEvent('ox_lib:notify', sourceId, payload)
end

local function ResolveDuration(level)
    if Config.Levels and Config.Levels[level] and Config.Levels[level].duration then
        return Config.Levels[level].duration
    end
    return EFFECT_DURATION
end

local function NormalizeCoords(coords)
    if coords == nil then
        return nil
    end
    if type(coords) == 'vector3' then
        return coords
    end
    if type(coords) == 'table' and coords.x and coords.y and coords.z then
        return vector3(coords.x, coords.y, coords.z)
    end
    return nil
end

local function SetLiquidState(sourceId, enabled, level)
    local duration = ResolveDuration(level or 1)
    local infinite = not duration or duration <= 0

    if not enabled then
        activePlayers[sourceId] = nil
        print(('[dvr_liquid] disable | src=%s'):format(sourceId))
        TriggerClientEvent('dvr_liquid:apply', -1, sourceId, false, 0, level or 1)
        return
    end

    activePlayers[sourceId] = {
        expires = infinite and 0 or (os_time() * 1000) + duration,
        infinite = infinite,
        level = level or 1
    }

    print(('[dvr_liquid] enable | src=%s level=%s duration=%s'):format(sourceId, level or 1, duration))
    TriggerClientEvent('dvr_liquid:apply', -1, sourceId, true, duration, level or 1)

    if not infinite then
        SetTimeout(duration, function()
            local state = activePlayers[sourceId]
            if state and state.expires <= (os_time() * 1000) then
                activePlayers[sourceId] = nil
                TriggerClientEvent('dvr_liquid:apply', -1, sourceId, false, duration, level or 1)
            end
        end)
    end
end

local function ToggleLiquid(sourceId, level)
    if activePlayers[sourceId] then
        SetLiquidState(sourceId, false, level)
    else
        SetLiquidState(sourceId, true, level)
    end
end

RegisterNetEvent('dvr_liquid:burst', function(coords, targetNetId)
    local sourceId = tonumber(source)
    if not sourceId then
        return
    end

    local state = activePlayers[sourceId]
    if not state then
        return
    end

    local normalized = NormalizeCoords(coords)
    if not normalized then
        return
    end

    local now = os_time() * 1000
    local last = lastBurst[sourceId] or 0
    if (now - last) < BURST_COOLDOWN then
        return
    end
    lastBurst[sourceId] = now

    TriggerClientEvent('dvr_liquid:burstFx', -1, normalized, targetNetId or 0)
end)

RegisterNetEvent('dvr_liquid:toggle', function(desiredState)
    local sourceId = tonumber(source)
    if not sourceId then
        return
    end

    if desiredState == false and activePlayers[sourceId] then
        SetLiquidState(sourceId, false, activePlayers[sourceId].level or 1)
    end
end)

AddEventHandler('playerDropped', function()
    local sourceId = tonumber(source)
    if not sourceId then
        return
    end

    if activePlayers[sourceId] then
        activePlayers[sourceId] = nil
        TriggerClientEvent('dvr_liquid:apply', -1, sourceId, false, 0, 1)
    end
    lastBurst[sourceId] = nil
end)

local function RegisterLiquidModule()
    local moduleData <const> = {
        id = SPELL_ID,
        name = Config.Module.name,
        description = Config.Module.description,
        icon = Config.Module.icon,
        color = Config.Module.color,
        cooldown = Config.Module.cooldown or 15000,
        type = Config.Module.type or 'utility',
        selfCast = Config.Module.selfCast ~= false,
        isBasic = false,
        image = Config.Module.image or 'images/power/dvr_liquid.png',
        professor = Config.Module.professor ~= false,
        hidden = Config.Module.hidden == true,
        isWand = Config.Module.isWand,
        animation = nil,
        onCast = function(hasItem, _, sourceId, _, level)
            if Config.Module.isWand ~= false and not hasItem then
                Notify(sourceId, Config.Messages and Config.Messages.noWand)
                return false
            end

            print(('[dvr_liquid] onCast | src=%s level=%s'):format(sourceId, level or 1))
            ToggleLiquid(sourceId, level or 1)
            local spellLevel = level ~= nil and math.floor(tonumber(level) or 0) or GetCasterLevel(source)
            local data = {
                professor = { source = source },
                --target = { source = target }, -- f
                spell = { id = 'liquid', name = 'Liquid', level = spellLevel },
                context = { temp = false, coords = source and GetEntityCoords(GetPlayerPed(source)) or nil}
            }
            exports['dvr_power']:LogSpellCast(data)
            return true
        end
    }

    exports['dvr_power']:registerModule(moduleData, 0)
    print('[dvr_liquid] Module enregistré avec succès')
end

CreateThread(function()
    while GetResourceState('dvr_power') ~= 'started' do
        Wait(100)
    end

    Wait(500)
    RegisterLiquidModule()
end)

AddEventHandler('onResourceStart', function(resourceName)
    if resourceName == 'dvr_power' then
        Wait(1000)
        RegisterLiquidModule()
    end
end)