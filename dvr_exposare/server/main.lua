---@diagnostic disable: undefined-global, trailing-space, unused-local
local hiddenPlayers = {}

local function Notify(sourceId, payload)
    if not payload then
        return
    end
    TriggerClientEvent('ox_lib:notify', sourceId, payload)
end

local function IsPlayerHidden(serverId)
    return hiddenPlayers[serverId] == true
end

RegisterNetEvent('dvr_hiddenis:setHidden', function(hidden)
    local source <const> = source
    if hidden then
        hiddenPlayers[source] = true
    else
        hiddenPlayers[source] = nil
    end
end)

AddEventHandler('dvr_hiddenis:syncHidden', function(serverId, hidden)
    if hidden then
        hiddenPlayers[serverId] = true
    else
        hiddenPlayers[serverId] = nil
    end
end)


local function RevealPlayer(targetServerId, casterServerId)
    hiddenPlayers[targetServerId] = nil
    
    TriggerClientEvent('dvr_exposare:forceReveal', targetServerId)
    
    Notify(targetServerId, Config.Messages.revealed)
    
    TriggerClientEvent('dvr_exposare:showRevealEffect', -1, targetServerId)
    
    return true
end

local function GetRevealRadius(level)
    local lvl = math.max(1, math.min(5, math.floor(tonumber(level) or 1)))
    return Config.Reveal.radiusByLevel[lvl] or 1.0
end

local function ScanAndRevealPlayers(casterServerId, casterCoords, radius)
    local revealedCount = 0
    local players = GetPlayers()
    
    for _, playerIdStr in ipairs(players) do
        local playerServerId = tonumber(playerIdStr)
        if playerServerId and playerServerId ~= casterServerId then
            local playerPed = GetPlayerPed(playerServerId)
            if playerPed and DoesEntityExist(playerPed) then
                local playerCoords = GetEntityCoords(playerPed)
                local distance = #(casterCoords - playerCoords)
                
                if distance <= radius then
                    if IsPlayerHidden(playerServerId) then
                        RevealPlayer(playerServerId, casterServerId)
                        revealedCount = revealedCount + 1
                    end
                end
            end
        end
    end
    
    return revealedCount
end

local function RegisterExposareModule()
    local moduleData <const> = {
        id = Config.Module.id,
        name = Config.Module.name,
        description = Config.Module.description,
        icon = Config.Module.icon,
        color = Config.Module.color,
        cooldown = Config.Module.cooldown or 15000,
        type = Config.Module.type,
        isBasic = false,
        image = Config.Module.image or 'images/power/nvision.png',
        video = Config.Module.video or "YOUR_VIDEO_URL_HERE",
        professor = Config.Module.professor ~= false,
        soundType = '3d',
        sound = '',
        animation = {
            dict = (Config.Animation and Config.Animation.dict) or 'export@nib@wizardsv_wand_attack_b2',
            name = (Config.Animation and Config.Animation.name) or 'nib@wizardsv_wand_attack_b2',
            flag = (Config.Animation and Config.Animation.flag) or 48,
            duration = (Config.Animation and Config.Animation.duration) or 2000,
            speedMultiplier = (Config.Animation and Config.Animation.speedMultiplier) or 1.5,
            effectDelay = (Config.Animation and Config.Animation.effectDelay) or 1000
        },
        onCast = function(hasItem, raycast, source, target, level)
            if not hasItem then
                Notify(source, Config.Messages and Config.Messages.noWand)
                return false
            end

            local casterServerId = source
            local casterPed = GetPlayerPed(casterServerId)
            if not casterPed or not DoesEntityExist(casterPed) then
                return false
            end
            
            local casterCoords = GetEntityCoords(casterPed)
            local spellLevel = level ~= nil and math.floor(tonumber(level) or 0) or GetCasterLevel(source)
            local radius = GetRevealRadius(spellLevel)
            
            local data = {
                professor = { source = casterServerId },
                spell = { id = 'exposare', name = 'Exposare', level = spellLevel },
                context = { temp = false, coords = casterCoords }
            }
            exports['dvr_power']:LogSpellCast(data)
            
            local revealedCount = ScanAndRevealPlayers(casterServerId, casterCoords, radius)
            
            if revealedCount > 0 then
                Notify(casterServerId, {
                    title = Config.Messages.revealSuccess.title,
                    description = string.format('%d joueur(s) révélé(s) dans un rayon de %.1fm', revealedCount, radius),
                    type = 'success',
                    icon = 'eye'
                })
            else
                Notify(casterServerId, Config.Messages and Config.Messages.noHiddenFound)
            end
            
            TriggerClientEvent('dvr_exposare:areaReveal', -1, casterCoords, radius)
            
            return true
        end
    }

    exports['dvr_power']:registerModule(moduleData, 0)
    print('[dvr_exposare] Module enregistré avec succès')
end

CreateThread(function()
    while GetResourceState('dvr_power') ~= 'started' do
        Wait(100)
    end

    Wait(500)
    RegisterExposareModule()
end)

AddEventHandler('onResourceStart', function(resourceName)
    if resourceName == 'dvr_power' then
        Wait(1000)
        RegisterExposareModule()
    end
end)

AddEventHandler('playerDropped', function()
    local source <const> = source
    if hiddenPlayers[source] then
        hiddenPlayers[source] = nil
    end
end)

