---@diagnostic disable: undefined-global, trailing-space, unused-local
local function Notify(sourceId, payload)
    if not payload then return end
    TriggerClientEvent('ox_lib:notify', sourceId, payload)
end

local bleeding = {}

local function RegisterSanguirisModule()
    local animCfg = Config.Animation or {}
    local moduleData = {
        id = Config.Module.id,
        name = Config.Module.name,
        description = Config.Module.description,
        icon = Config.Module.icon,
        color = Config.Module.color,
        cooldown = Config.Module.cooldown or 8000,
        type = Config.Module.type,
        isBasic = false,
        key = Config.Module.key,
        sound = '',
        soundType = "3d",
        image = Config.Module.image or "images/power/dvr_sanguiris.png",
        video = Config.Module.video or "YOUR_VIDEO_URL_HERE",
        professor = Config.Module.professor ~= false,
        animation = {
            dict = animCfg.dict or 'export@nib@wizardsv_avada_kedrava',
            name = animCfg.name or 'nib@wizardsv_avada_kedrava',
            flag = animCfg.flag or 48,
            duration = animCfg.duration or 3000,
            speedMultiplier = animCfg.speedMultiplier or 1.0
        },
        onCast = function(hasItem, raycast, source, target, level)
            if not hasItem then
                Notify(source, Config.Messages and Config.Messages.noWand)
                return false
            end
            local spellLevel = level ~= nil and math.floor(tonumber(level) or 0) or 0
            local data = {
                professor = { source = source },
                spell = { id = 'sanguiris', name = 'Sanguiris', level = spellLevel },
                context = { temp = false, coords = source and GetEntityCoords(GetPlayerPed(source)) or nil}
            }
            exports['dvr_power']:LogSpellCast(data)
            TriggerClientEvent('dvr_sanguiris:otherPlayerCasting', -1, source)
            TriggerClientEvent('dvr_sanguiris:prepareProjectile', source, target or 0, spellLevel)
            return true
        end
    }
    exports['dvr_power']:registerModule(moduleData, 0)
    print('[dvr_sanguiris] Module enregistré avec succès')
end

RegisterNetEvent('dvr_sanguiris:broadcastProjectile', function(targetCoords, targetId, level)
    local _source = source
    if not targetCoords then return end
    TriggerClientEvent('dvr_sanguiris:spawnProjectile', -1, _source, targetCoords, targetId or 0, level or 0)
end)

RegisterNetEvent('dvr_sanguiris:applyBleed', function(victimId, level)
    local _source = source
    if not victimId or victimId <= 0 then return end
    if victimId == _source then return end

    if exports['dvr_prothea'] and exports['dvr_prothea'].hasActiveShield and exports['dvr_prothea']:hasActiveShield(victimId) then
        return
    end

    local tickDamage = Config.Bleed.tickDamage or 5
    local tickInterval = Config.Bleed.tickInterval or 2000
    local maxDuration = Config.Bleed.maxDuration or 20000

    local endAt = GetGameTimer() + maxDuration
    bleeding[victimId] = { endAt = endAt, damage = tickDamage, interval = tickInterval }

    local ragdollDuration = Config.Bleed.ragdollDuration or 20000
    
    TriggerClientEvent('dvr_sanguiris:startBleed', victimId, tickDamage, tickInterval, maxDuration, Config.Bleed.fx or {})
    TriggerClientEvent('dvr_sanguiris:bleedImpactFx', -1, victimId, Config.Bleed.fx or {})
    TriggerClientEvent('dvr_sanguiris:ragdoll', victimId, ragdollDuration)
end)

RegisterNetEvent('dvr_sanguiris:stopBleed', function(targetId)
    local _source = source
    if not targetId or targetId <= 0 then
        targetId = _source
    end
    bleeding[targetId] = nil
    TriggerClientEvent('dvr_sanguiris:stopBleed', targetId)
    TriggerClientEvent('dvr_sanguiris:stopBleedFx', -1, targetId)
end)

CreateThread(function()
    while true do
        Wait(2000)
        local currentTime = GetGameTimer()
        local toRemove = {}
        
        for victimId, bleedData in pairs(bleeding) do
            if currentTime >= bleedData.endAt then
                toRemove[#toRemove + 1] = victimId
            else
                TriggerClientEvent('dvr_sanguiris:bleedRecurrentFx', -1, victimId, Config.Bleed.fx or {})
            end
        end
        
        for _, victimId in ipairs(toRemove) do
            bleeding[victimId] = nil
            TriggerClientEvent('dvr_sanguiris:stopBleed', victimId)
            TriggerClientEvent('dvr_sanguiris:stopBleedFx', -1, victimId)
        end
    end
end)

CreateThread(function()
    while GetResourceState('dvr_power') ~= 'started' do
        Wait(100)
    end
    Wait(500)
    RegisterSanguirisModule()
end)

AddEventHandler('onResourceStart', function(resourceName)
    if resourceName == 'dvr_power' then
        Wait(1000)
        RegisterSanguirisModule()
    end
end)
