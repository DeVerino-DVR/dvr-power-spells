---@diagnostic disable: undefined-global, trailing-space, param-type-mismatch
local Config <const> = Config
local string_lower = string.lower
-- REPLACE WITH YOUR DOOR LOCK SYSTEM (e.g. ox_doorlock: https://github.com/overextended/ox_doorlock)
local doorlockExports = exports['ox_doorlock']
local castCache = {}

local function clampLevel(level)
    local numeric = math.floor(tonumber(level) or 0)
    if numeric < 0 then
        return 0
    elseif numeric > 5 then
        return 5
    end
    return numeric
end

local function buildLookup(list, transform)
    local lookup = {}

    if not list or type(list) ~= 'table' then
        return lookup
    end

    for key, value in pairs(list) do
        if type(key) == 'number' then
            if value ~= nil then
                local entry = transform and transform(value) or value
                lookup[entry] = true
            end
        elseif value then
            local entry = value == true and key or value
            entry = transform and transform(entry) or entry
            lookup[entry] = true
        end
    end

    return lookup
end

local blacklistIdLookup = buildLookup(Config.Blacklist and Config.Blacklist.ids, tostring)
local blacklistNameLookup = buildLookup(Config.Blacklist and Config.Blacklist.names, function(val)
    return string_lower(val)
end)

local function doorIsBlacklisted(doorId, doorName)
    if doorId and blacklistIdLookup[tostring(doorId)] then
        return true
    end

    if doorName and blacklistNameLookup[string_lower(doorName)] then
        return true
    end

    return false
end

local function registerModule()
    local spell <const> = Config.Spell or {}

    local moduleData <const> = {
        id = spell.id or 'aloharis',
        name = spell.name or 'Aloharis',
        description = spell.description or "Contraint une serrure à céder sous la pression d’une impulsion arcanique brute.",
        icon = spell.icon or 'key',
        color = spell.color or 'yellow',
        cooldown = spell.cooldown or 8000,
        type = spell.type or 'utility',
        key = spell.key,
        image = spell.image,
        video = spell.video,
        sound = spell.sound,
        soundType = spell.soundType,
        castTime = spell.castTime or 1800,
        animation = spell.animation,
        selfCast = false,
        onCast = function(hasWand, _, source, _, spellLevel)
            if not hasWand then
                if Config.Messages and Config.Messages.noWand then
                    lib.notify(source, Config.Messages.noWand)
                end
                return false
            end

            local level = clampLevel(spellLevel)

            castCache[source] = {
                level = level
            }

            local data = {
                professor = { source = source },
                --target = { source = target }, -- f
                spell = { id = 'aloharis', name = 'Aloharis', level = spellLevel },
                context = { temp = false, coords = source and GetEntityCoords(GetPlayerPed(source)) or nil}
            }
            exports['dvr_power']:LogSpellCast(data)

            TriggerClientEvent('dvr_aloharis:onCast', source, level)
            return true
        end
    }

    exports['dvr_power']:registerModule(moduleData, 0)
    print('[dvr_aloharis] Module enregistré avec succès')
end

local function sanitiseCoords(coords)
    if not coords or coords.x == nil then
        return nil
    end

    return {
        x = coords.x + 0.0,
        y = coords.y + 0.0,
        z = coords.z + 0.0
    }
end

RegisterNetEvent('dvr_aloharis:unlockDoor', function(payload)
    local src = source

    if type(payload) ~= 'table' then
        return
    end

    local doorId = payload.id
    if doorId == nil then
        TriggerClientEvent('dvr_aloharis:doorUnlocked', src, { success = false, source = src, reason = 'failed' })
        return
    end

    local doorName = payload.name
    if doorIsBlacklisted(doorId, doorName) then
        TriggerClientEvent('dvr_aloharis:doorUnlocked', src, { success = false, source = src, reason = 'blacklisted' })
        return
    end

    if payload.state == 0 then
        TriggerClientEvent('dvr_aloharis:doorUnlocked', src, { success = false, source = src, reason = 'alreadyUnlocked' })
        return
    end

    local numericId = tonumber(doorId) or doorId
    local success = false

    if doorlockExports and doorlockExports.setDoorState then
        success = doorlockExports:setDoorState(numericId, 0)
    else
        success = exports.ox_doorlock:setDoorState(numericId, 0)
    end

    if not success then
        TriggerClientEvent('dvr_aloharis:doorUnlocked', src, { success = false, source = src, reason = 'failed' })
        return
    end

    local coords = sanitiseCoords(payload.coords)

    local castInfo = castCache[src]
    castCache[src] = nil

    TriggerClientEvent('dvr_aloharis:doorUnlocked', -1, {
        success = true,
        source = src,
        id = numericId,
        coords = coords,
        level = clampLevel(castInfo and castInfo.level or 0)
    })

    TriggerEvent('dvr_aloharis:doorUnlockedServer', src, numericId, coords)
end)

CreateThread(function()
    while GetResourceState('dvr_power') ~= 'started' do
        Wait(250)
    end

    Wait(500)
    registerModule()
end)

AddEventHandler('onResourceStart', function(resourceName)
    if resourceName == 'dvr_power' or resourceName == GetCurrentResourceName() then
        Wait(1000)
        registerModule()
    end
end)
