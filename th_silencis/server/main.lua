---@diagnostic disable: undefined-global, trailing-space, param-type-mismatch
local Config <const> = Config
local GetEntityCoords = GetEntityCoords
local GetPlayerPed = GetPlayerPed
local GetPlayerName = GetPlayerName
local Wait = Wait
local CreateThread = CreateThread
local SetTimeout = SetTimeout
local math_floor = math.floor

local mutedPlayersTimeouts = {}

local function mutePlayer(playerId, duration, reason)
    if not playerId then return false end
    
    if not exports['pma-voice'] or not exports['pma-voice'].isValidPlayer then
        print('[th_silencis] ERROR: pma-voice export not available')
        return false
    end
    
    if not exports['pma-voice']:isValidPlayer(playerId) then
        print(string.format('[th_silencis] ERROR: Player %d is not valid', playerId))
        return false
    end
    
    local playerName = GetPlayerName(playerId) or ('ID ' .. playerId)
    
    if mutedPlayersTimeouts[playerId] then
        mutedPlayersTimeouts[playerId] = nil
    end
    
    Player(playerId).state.silencis_muted = true
    
    if duration > 0 then
        mutedPlayersTimeouts[playerId] = SetTimeout(duration * 1000, function()
            Player(playerId).state.silencis_muted = false
            mutedPlayersTimeouts[playerId] = nil
            
            if Config.Messages and Config.Messages.unmuted then
                lib.notify(playerId, Config.Messages.unmuted)
            end
        end)
    end
    
    print(string.format('[th_silencis] MUTE: %s (ID: %d) muté pour %d secondes - Raison: %s', 
        playerName, playerId, duration, reason or 'Silencis'))
    
    return true
end

local function registerModule()
    local spell <const> = Config.Spell or {}
    
    local moduleData <const> = {
        id = spell.id or 'silencis',
        name = spell.name or 'Silencis',
        description = spell.description or "Scelle la voix de la cible, l’empêchant de prononcer le moindre son.",
        icon = spell.icon or 'volume-xmark',
        color = spell.color or 'purple',
        cooldown = spell.cooldown or 15000,
        type = spell.type or 'control',
        key = spell.key,
        image = spell.image,
        sound = spell.sound,
        soundType = spell.soundType,
        castTime = spell.castTime or 1200,
        animation = spell.animation,
        selfCast = false,
        onCast = function(hasWand, _, source, target, spellLevel)
            if not hasWand then
                if Config.Messages and Config.Messages.noWand then
                    lib.notify(source, Config.Messages.noWand)
                end
                return false
            end
            
            if not target or target <= 0 then
                if Config.Messages and Config.Messages.noTarget then
                    lib.notify(source, Config.Messages.noTarget)
                end
                return false
            end
            
            if exports['th_prothea'] and exports['th_prothea'].hasActiveShield and exports['th_prothea']:hasActiveShield(target) then
                print(string.format('[th_silencis] Sort annulé par Prothea pour %s', target))
                return false
            end
            
            local spellLevelNum = spellLevel ~= nil and math_floor(tonumber(spellLevel) or 0) or 0
            if spellLevelNum < 1 then spellLevelNum = 1 end
            if spellLevelNum > 5 then spellLevelNum = 5 end
            
            local duration = Config.DurationByLevel[spellLevelNum] or Config.DurationByLevel[1]
            
            local casterPed = GetPlayerPed(source)
            local targetPed = GetPlayerPed(target)
            
            if not casterPed or casterPed == 0 or not targetPed or targetPed == 0 then
                return false
            end
            
            local casterCoords = GetEntityCoords(casterPed)
            local targetCoords = GetEntityCoords(targetPed)
            local distance = #(casterCoords - targetCoords)
            local maxDistance = Config.MaxDistance or 15.0
            
            if distance > maxDistance then
                if Config.Messages and Config.Messages.noTarget then
                    lib.notify(source, Config.Messages.noTarget)
                end
                return false
            end
            
            local data = {
                professor = { source = source },
                target = { source = target },
                spell = { id = 'silencis', name = 'Silencis', level = spellLevelNum },
                context = { temp = false, coords = targetCoords }
            }
            exports['th_power']:LogSpellCast(data)
            
            mutePlayer(target, duration, 'Silencis')
            
            if Config.Messages and Config.Messages.muted then
                lib.notify(target, Config.Messages.muted)
            end
            
            if Config.Messages and Config.Messages.success then
                lib.notify(source, Config.Messages.success)
            end
            
            return true
        end
    }
    
    exports['th_power']:registerModule(moduleData, 0)
    print('[th_silencis] Module enregistré avec succès')
end

AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then
        return
    end
    
    for playerId, _ in pairs(mutedPlayersTimeouts) do
        Player(playerId).state.silencis_muted = false
    end
    mutedPlayersTimeouts = {}
end)

AddEventHandler('playerDropped', function()
    local playerId = source
    if mutedPlayersTimeouts[playerId] then
        Player(playerId).state.silencis_muted = false
        mutedPlayersTimeouts[playerId] = nil
    end
end)

CreateThread(function()
    while GetResourceState('th_power') ~= 'started' do
        Wait(250)
    end
    
    Wait(500)
    registerModule()
end)

AddEventHandler('onResourceStart', function(resourceName)
    if resourceName == 'th_power' or resourceName == GetCurrentResourceName() then
        Wait(1000)
        registerModule()
    end
end)

