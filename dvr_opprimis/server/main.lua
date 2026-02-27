---@diagnostic disable: undefined-global, trailing-space, param-type-mismatch
local Config <const> = Config
local GetEntityCoords = GetEntityCoords
local GetPlayerPed = GetPlayerPed
local GetPlayerName = GetPlayerName
local Wait = Wait
local CreateThread = CreateThread
local SetTimeout = SetTimeout
local math_floor = math.floor

local handcuffedPlayersTimeouts = {}

local function handcuffPlayer(playerId, duration, casterServerId)
    if not playerId then return false end

    local playerName = GetPlayerName(playerId) or ('ID ' .. playerId)

    if handcuffedPlayersTimeouts[playerId] then
        handcuffedPlayersTimeouts[playerId] = nil
    end

    Player(playerId).state.opprimis_handcuffed = true
    Player(playerId).state.opprimis_caster = casterServerId

    TriggerClientEvent('dvr_opprimis:onHandcuffed', playerId, duration, casterServerId)

    if duration > 0 then
        handcuffedPlayersTimeouts[playerId] = SetTimeout(duration * 1000, function()
            releasePlayer(playerId)
        end)
    end

    print(string.format('[dvr_opprimis] HANDCUFF: %s (ID: %d) menotte pour %d secondes par ID: %d',
        playerName, playerId, duration, casterServerId))

    return true
end

function releasePlayer(playerId)
    if not playerId then return end

    Player(playerId).state.opprimis_handcuffed = false
    Player(playerId).state.opprimis_caster = nil

    if handcuffedPlayersTimeouts[playerId] then
        handcuffedPlayersTimeouts[playerId] = nil
    end

    TriggerClientEvent('dvr_opprimis:onReleased', playerId)

    if Config.Messages and Config.Messages.released then
        lib.notify(playerId, Config.Messages.released)
    end

    print(string.format('[dvr_opprimis] RELEASE: Player %d released from handcuffs', playerId))
end

local function registerModule()
    local spell <const> = Config.Spell or {}

    local moduleData <const> = {
        id = spell.id or 'opprimis',
        name = spell.name or 'Opprimis',
        description = spell.description or "Entrave magiquement la cible.",
        icon = spell.icon or 'link',
        color = spell.color or 'gray',
        cooldown = spell.cooldown or 20000,
        type = spell.type or 'control',
        key = spell.key,
        image = spell.image,
        sound = spell.sound,
        soundType = spell.soundType,
        castTime = spell.castTime or 1500,
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

            -- Toggle: si deja menotte, on libere
            local targetPlayer = Player(target)
            if targetPlayer and targetPlayer.state.opprimis_handcuffed then
                releasePlayer(target)
                if Config.Messages and Config.Messages.releaseSuccess then
                    lib.notify(source, Config.Messages.releaseSuccess)
                end
                return true
            end

            -- Verifier le bouclier Prothea
            if exports['dvr_prothea'] and exports['dvr_prothea'].hasActiveShield and exports['dvr_prothea']:hasActiveShield(target) then
                print(string.format('[dvr_opprimis] Sort annule par Prothea pour %s', target))
                return false
            end

            local spellLevelNum = spellLevel ~= nil and math_floor(tonumber(spellLevel) or 0) or 0
            if spellLevelNum < 0 then spellLevelNum = 0 end
            if spellLevelNum > 5 then spellLevelNum = 5 end

            local duration = Config.DurationByLevel[spellLevelNum] or Config.DurationByLevel[0] or 30

            local casterPed = GetPlayerPed(source)
            local targetPed = GetPlayerPed(target)

            if not casterPed or casterPed == 0 or not targetPed or targetPed == 0 then
                return false
            end

            local casterCoords = GetEntityCoords(casterPed)
            local targetCoords = GetEntityCoords(targetPed)
            local distance = #(casterCoords - targetCoords)
            local maxDistance = Config.MaxDistance or 10.0

            if distance > maxDistance then
                if Config.Messages and Config.Messages.tooFar then
                    lib.notify(source, Config.Messages.tooFar)
                end
                return false
            end

            local data = {
                professor = { source = source },
                target = { source = target },
                spell = { id = 'opprimis', name = 'Opprimis', level = spellLevelNum },
                context = { temp = false, coords = targetCoords, duration = duration }
            }
            exports['dvr_power']:LogSpellCast(data)

            handcuffPlayer(target, duration, source)

            if Config.Messages and Config.Messages.handcuffed then
                lib.notify(target, Config.Messages.handcuffed)
            end

            if Config.Messages and Config.Messages.success then
                lib.notify(source, Config.Messages.success)
            end

            return true
        end
    }

    exports['dvr_power']:registerModule(moduleData, 0)
    print('[dvr_opprimis] Module enregistre avec succes')
end

AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then
        return
    end

    for playerId, _ in pairs(handcuffedPlayersTimeouts) do
        Player(playerId).state.opprimis_handcuffed = false
        Player(playerId).state.opprimis_caster = nil
        TriggerClientEvent('dvr_opprimis:onReleased', playerId)
    end
    handcuffedPlayersTimeouts = {}
end)

AddEventHandler('playerDropped', function()
    local playerId = source

    if handcuffedPlayersTimeouts[playerId] then
        handcuffedPlayersTimeouts[playerId] = nil
    end
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

exports('isHandcuffed', function(playerId)
    local player = Player(playerId)
    return player and player.state.opprimis_handcuffed == true
end)

exports('releasePlayer', function(playerId)
    releasePlayer(playerId)
end)
