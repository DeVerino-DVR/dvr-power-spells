---@diagnostic disable: trailing-space, undefined-global
local Config = require 'config'
local GetEntityCoords = GetEntityCoords
local GetPlayerPed = GetPlayerPed
local Wait = Wait
local CreateThread = CreateThread
local SetTimeout = SetTimeout
local madvr_floor = math.floor
local os_time = os.time

-- Table to store position history for each player
-- Structure: playerPositions[serverId] = {
--   [1] = { coords = vector3, timestamp = os.time() }, -- 1 minute ago
--   [2] = { coords = vector3, timestamp = os.time() }, -- 2 minutes ago
--   [3] = { coords = vector3, timestamp = os.time() }, -- 3 minutes ago
--   [4] = { coords = vector3, timestamp = os.time() }, -- 4 minutes ago
--   [5] = { coords = vector3, timestamp = os.time() }  -- 5 minutes ago
-- }
local playerPositions = {}

-- Function to get caster level
local function GetCasterLevel(sourceId)
    local ok, hasSpell, level = pcall(function()
        return exports['dvr_power']:GetSpell(sourceId, 'oublitix')
    end)

    if ok and hasSpell then
        return madvr_floor(tonumber(level) or 0)
    end

    return 0
end

-- Function to save player position (called every minute)
local function SavePlayerPosition(playerId)
    local ped = GetPlayerPed(playerId)
    if not ped or ped == 0 then
        return
    end
    
    local coords = GetEntityCoords(ped)
    local currentTime = os_time()
    
    if not playerPositions[playerId] then
        playerPositions[playerId] = {}
    end
    
    local positions = playerPositions[playerId]
    
    -- Shift positions: move all positions one index forward
    -- Position at index 5 is overwritten, position at index 1 moves to index 2, etc.
    for i = Config.MaxPositionHistory, 2, -1 do
        positions[i] = positions[i - 1]
    end
    
    -- Save current position at index 1 (most recent = 1 minute ago)
    positions[1] = {
        coords = coords,
        timestamp = currentTime
    }
end

-- Function to get position from X minutes ago
local function GetPositionFromMinutesAgo(playerId, minutesAgo)
    if not playerPositions[playerId] then
        return nil
    end
    
    local positions = playerPositions[playerId]
    
    -- Validate minutesAgo (1-5)
    minutesAgo = math.max(1, math.min(minutesAgo, Config.MaxPositionHistory))
    
    -- Return exact slot if present
    if positions[minutesAgo] and positions[minutesAgo].coords then
        return positions[minutesAgo].coords
    end

    -- If not enough history (player connecté depuis peu), fallback to the oldest available slot
    for i = Config.MaxPositionHistory, 1, -1 do
        if positions[i] and positions[i].coords then
            return positions[i].coords
        end
    end
    
    return nil
end

-- Initialize position for new players
AddEventHandler('playerJoining', function()
    local playerId = source
    -- Save initial position immediately
    CreateThread(function()
        Wait(1000) -- Wait a bit for player to fully load
        SavePlayerPosition(playerId)
    end)
end)

-- Thread to save positions every minute for all players
CreateThread(function()
    -- Initial save for all players already connected
    Wait(5000) -- Wait for resource to fully load
    local players = GetPlayers()
    for _, playerIdStr in ipairs(players) do
        local playerId = tonumber(playerIdStr)
        if playerId then
            SavePlayerPosition(playerId)
        end
    end
    
    -- Then save every minute
    while true do
        Wait(Config.PositionSaveInterval)
        
        -- Save position for all connected players
        local players = GetPlayers()
        for _, playerIdStr in ipairs(players) do
            local playerId = tonumber(playerIdStr)
            if playerId then
                SavePlayerPosition(playerId)
            end
        end
    end
end)

-- Cleanup position history when player disconnects
AddEventHandler('playerDropped', function()
    local playerId = source
    if playerPositions[playerId] then
        playerPositions[playerId] = nil
    end
end)

-- Event when spell is cast
RegisterNetEvent('dvr_oublitix:broadcastProjectile', function(finalTargetCoords, targetEntity)
    local _source <const> = source
    if not finalTargetCoords then
        return
    end

    local spellLevel = GetCasterLevel(_source)
    
    TriggerClientEvent('dvr_oublitix:fireProjectile', -1, _source, finalTargetCoords, targetEntity, spellLevel)
end)

-- Event to apply spell effect on target
RegisterNetEvent('dvr_oublitix:applySpell', function(targetServerId, spellLevel)
    local _source <const> = source
    if not targetServerId or targetServerId <= 0 then
        return
    end

    -- Check if target has active shield (Prothea protection)
    if exports['dvr_prothea'] and exports['dvr_prothea'].hasActiveShield and exports['dvr_prothea']:hasActiveShield(targetServerId) then
        print(string.format('[dvr_oublitix] Sort annulé par Prothea pour %s', targetServerId))
        return
    end

    local casterLevel = spellLevel or GetCasterLevel(_source)
    if casterLevel < 1 then casterLevel = 1 end
    if casterLevel > 5 then casterLevel = 5 end
    
    -- Get rollback minutes based on level
    local rollbackMinutes = Config.RollbackMinutesByLevel[casterLevel] or 1
    
    -- Get target position from X minutes ago
    local targetCoords = GetPositionFromMinutesAgo(targetServerId, rollbackMinutes)
    
    if not targetCoords then
        print(string.format('[dvr_oublitix] Aucune position trouvée pour le joueur %s (%d minutes)', targetServerId, rollbackMinutes))
        -- If no position found, use current position (fallback)
        local targetPed = GetPlayerPed(targetServerId)
        if targetPed and targetPed ~= 0 then
            targetCoords = GetEntityCoords(targetPed)
        else
            return
        end
    end
    
    -- Apply effect to target
    TriggerClientEvent('dvr_oublitix:applyEffect', targetServerId, rollbackMinutes, targetCoords)
    
    print(string.format('[dvr_oublitix] Sort appliqué sur le joueur %s - Rollback de %d minute(s) - Niveau %d', 
        targetServerId, rollbackMinutes, casterLevel))
end)

-- Function to register the spell module
local function RegisterOublitixModule()
    local moduleData <const> = {
        id = Config.Spell.id,
        name = Config.Spell.name,
        description = Config.Spell.description,
        icon = Config.Spell.icon,
        color = Config.Spell.color,
        cooldown = Config.Spell.cooldown,
        type = Config.Spell.type,
        level = 5,
        unforgivable = false,
        key = Config.Spell.key,
        sound = nil, -- Add sound if needed
        soundType = Config.Spell.soundType,
        image = Config.Spell.image,
        video = Config.Spell.video,
        castTime = Config.Spell.castTime,
        animation = Config.Spell.animation,
        onCast = function(hasItem, raycast, source, target, level)
            if not hasItem then
                TriggerClientEvent('ox_lib:notify', source, Config.Messages.noWand)
                return false
            end

            local spellLevel = level ~= nil and madvr_floor(tonumber(level) or 0) or GetCasterLevel(source)
            if spellLevel < 1 then spellLevel = 1 end
            if spellLevel > 5 then spellLevel = 5 end

            -- Log spell cast
            local data = {
                professor = { source = source },
                target = { source = target },
                spell = { id = 'oublitix', name = 'Oublitix', level = spellLevel },
                context = { temp = false, coords = source and GetEntityCoords(GetPlayerPed(source)) or nil }
            }
            exports['dvr_power']:LogSpellCast(data)
            
            -- Broadcast animation to other players
            TriggerClientEvent('dvr_oublitix:otherPlayerCasting', -1, source)
            -- Prepare projectile on caster client
            TriggerClientEvent('dvr_oublitix:prepareProjectile', source, spellLevel)
            
            return true
        end
    }

    exports['dvr_power']:registerModule(moduleData, 0)
    print('[dvr_oublitix] Module enregistré avec succès')
end

-- Wait for dvr_power to be ready
CreateThread(function()
    while GetResourceState('dvr_power') ~= 'started' do
        Wait(100)
    end
    
    Wait(500)
    RegisterOublitixModule()
end)

-- Re-register on resource start
AddEventHandler('onResourceStart', function(resourceName)
    if resourceName == 'dvr_power' then
        Wait(1000)
        RegisterOublitixModule()
    end
end)

