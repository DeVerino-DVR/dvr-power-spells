---@diagnostic disable: undefined-global, trailing-space
local playerShields = {}
local playerGodmode = {}
local playerCooldowns = {}
local madvr_ceil = math.ceil
local NetworkGetEntityFromNetworkId = NetworkGetEntityFromNetworkId
local NetworkGetEntityOwner = NetworkGetEntityOwner
local DoesEntityExist = DoesEntityExist
local DeleteEntity = DeleteEntity
local SPELL_ID <const> = 'prothea'
local MAX_LEVEL <const> = Config.MaxLevel or 3

local function SendCastResult(target, status, data)
    if not target then return end
    TriggerClientEvent('dvr_prothea:castResult', target, status, data or {})
end

local function RegisterProtheaModule()
    if GetResourceState('dvr_power') ~= 'started' then
        return
    end

    local cooldown = (Config and Config.Shield and Config.Shield.cooldown) or 1000

    exports['dvr_power']:registerModule({
        name = 'Prothèa',
        keys = Config and Config.Key or true,
        spells = {
            {
                id = SPELL_ID,
                name = 'Prothèa',
                description = 'Bouclier magique',
                color = 'blue',
                cooldown = cooldown,
                type = 'defense',
                selfCast = true,
                professor = true,
                image = 'images/power/dvr_prothea.png',
                keys = Config and Config.Key or nil
            }
        }
    }, 0)
    print('[dvr_prothea] Module enregistré avec succès')
end

local function HasUnlockedProthea(sourceId)
    if GetResourceState('dvr_power') ~= 'started' then
        return true
    end

    local ok, hasSpell = pcall(function()
        local unlocked = exports['dvr_power']:GetSpell(sourceId, SPELL_ID)
        return unlocked
    end)

    if not ok then
        return true
    end

    return hasSpell == true
end

local function ResolveProtheaLevel(sourceId)
    if GetResourceState('dvr_power') ~= 'started' then
        return 0
    end

    local ok, hasSpell, level = pcall(function()
        return exports['dvr_power']:GetSpell(sourceId, SPELL_ID)
    end)

    if ok and hasSpell and level then
        local normalized = math.floor(level + 0.0001)
        if normalized < 0 then
            normalized = 0
        elseif normalized > MAX_LEVEL then
            normalized = MAX_LEVEL
        end
        return normalized
    end

    return 0
end

local function GetShieldSettingsForLevel(level)
    local normalized = math.floor(level or 0)
    if normalized < 0 then
        normalized = 0
    elseif normalized > MAX_LEVEL then
        normalized = MAX_LEVEL
    end

    if Config.Levels and Config.Levels[normalized] then
        return Config.Levels[normalized]
    end

    return {
        duration = Config.Shield.duration or 1000,
        blockDamage = Config.Shield.blockDamage or 0.8,
        props = true,
        godmode = normalized >= MAX_LEVEL,
        cooldown = Config.Shield.cooldown or 1000
    }
end

local function GetCooldownForLevel(level)
    local settings = GetShieldSettingsForLevel(level)
    return settings.cooldown or Config.Shield.cooldown or 1000
end

local function IsOnCooldown(playerId, level)
    local lastCast = playerCooldowns[playerId]
    if not lastCast then
        return false, 0
    end

    local cooldownMs = GetCooldownForLevel(level)
    local currentTime = GetGameTimer()
    local elapsed = currentTime - lastCast
    local remaining = cooldownMs - elapsed

    if remaining > 0 then
        return true, remaining
    end

    return false, 0
end

local function SetCooldown(playerId)
    playerCooldowns[playerId] = GetGameTimer()
end

CreateThread(function()
    while true do
        Wait(1000)
        local currentTime <const> = os.time()
        
        for playerId, shield in pairs(playerShields or {}) do
            if shield.endTime <= currentTime then
                playerShields[playerId] = nil
                playerGodmode[playerId] = nil
                local source = tonumber(playerId)
                if source then
                    TriggerClientEvent('dvr_prothea:removeShield', -1, source)
                end
            end
        end
    end
end)

exports('hasActiveShield', function(playerId)
    local targetId <const> = tostring(playerId)
    return playerShields[targetId] ~= nil or false
end)

exports('hasGodmode', function(playerId)
    local targetId <const> = tostring(playerId)
    return playerGodmode[targetId] ~= nil or false
end)

exports('getShieldReduction', function(playerId)
    local targetId <const> = tostring(playerId)
    if playerShields[targetId] then
        return playerShields[targetId].blockPercentage or 0
    end
    return 0
end)

RegisterNetEvent('dvr_prothea:castShield', function()
    local source <const> = source
    local playerId <const> = tostring(source)

    print('[PROTHEA][server] castShield reçu de ' .. tostring(playerId))

    if not HasUnlockedProthea(source) then
        print('[PROTHEA][server] bloqué: spell non débloqué pour ' .. tostring(playerId))
        SendCastResult(source, 'locked', { reason = 'not_unlocked' })
        return
    end

    if playerShields[playerId] then
        print('[PROTHEA][server] bloqué: shield déjà actif pour ' .. tostring(playerId))
        SendCastResult(source, 'blocked', { reason = 'already_active' })
        return
    end

    if not playerId then return end

    local spellLevel = ResolveProtheaLevel(source)

    local onCooldown, remainingMs = IsOnCooldown(playerId, spellLevel)
    if onCooldown then
        local remainingSec = math.ceil(remainingMs / 1000)
        print(('[PROTHEA][server] bloqué: cooldown actif pour %s (%d secondes restantes)'):format(playerId, remainingSec))
        SendCastResult(source, 'cooldown', { reason = 'on_cooldown', remaining = remainingMs, level = spellLevel })
        return
    end

    local shieldCfg <const> = Config and Config.Shield
    local levelSettings <const> = GetShieldSettingsForLevel(spellLevel)
    local durationMs <const> = levelSettings.duration or (shieldCfg and shieldCfg.duration) or 1000
    local durationSeconds <const> = math.max(1, madvr_ceil(durationMs / 1000))
    local blockPercentage <const> = levelSettings.blockDamage or (shieldCfg and shieldCfg.blockDamage) or 0.8
    local useProps <const> = levelSettings.props ~= false and durationMs > 0
    local applyGodmode <const> = levelSettings.godmode == true and durationMs > 0

    if durationMs <= 0 then
        print('[PROTHEA][server] bloqué: durée <= 0 pour ' .. tostring(playerId))
        SendCastResult(source, 'blocked', { reason = 'duration_zero', level = spellLevel, duration = durationMs })
        return
    end

    local targetId <const> = tostring(source)
    if not targetId then return end
    
    playerShields[targetId] = {
        blockPercentage = blockPercentage,
        endTime = os.time() + durationSeconds
    }
    
    if applyGodmode then
        playerGodmode[targetId] = {
            endTime = os.time() + durationSeconds
        }
    end

    print(('[PROTHEA][server] applyShield -> %s dur=%s props=%s god=%s level=%s'):format(
        tostring(targetId), tostring(durationMs), tostring(useProps), tostring(applyGodmode), tostring(spellLevel)
    ))

    SetCooldown(playerId)

    local cooldownMs = GetCooldownForLevel(spellLevel)
    SendCastResult(source, 'ok', { duration = durationMs, props = useProps, godmode = applyGodmode, level = spellLevel, cooldown = cooldownMs })

    TriggerClientEvent('dvr_prothea:applyShield', -1, source, durationMs, blockPercentage, applyGodmode, useProps, spellLevel)
end)

AddEventHandler('playerDropped', function()
    local sourceId <const> = source
    local playerId <const> = tostring(sourceId)

    playerShields[playerId] = nil
    playerGodmode[playerId] = nil
    playerCooldowns[playerId] = nil
    TriggerClientEvent('dvr_prothea:removeShield', -1, sourceId)
end)

RegisterNetEvent('dvr_prothea:forceDeleteEntity', function(netId)
    if not netId or netId == 0 then return end

    local entity <const> = NetworkGetEntityFromNetworkId(netId)
    if entity and entity ~= 0 and DoesEntityExist(entity) then
        DeleteEntity(entity)

        Wait(0)

        if DoesEntityExist(entity) then
            local owner <const> = NetworkGetEntityOwner(entity)
            if owner and owner > 0 then
                TriggerClientEvent('dvr_prothea:forceDeleteEntityClient', owner, netId)
            end
            TriggerClientEvent('dvr_prothea:forceDeleteEntityClient', -1, netId)
            return
        end

        TriggerClientEvent('dvr_prothea:forceDeleteEntityClient', -1, netId)
        return
    end

    TriggerClientEvent('dvr_prothea:forceDeleteEntityClient', -1, netId)
end)

CreateThread(function()
    while GetResourceState('dvr_power') ~= 'started' do
        Wait(250)
    end

    RegisterProtheaModule()
end)

AddEventHandler('onResourceStart', function(resourceName)
    if resourceName == 'dvr_power' then
        Wait(500)
        RegisterProtheaModule()
    end
end)
