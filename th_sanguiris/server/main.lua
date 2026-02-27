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
        image = Config.Module.image or "images/power/th_sanguiris.png",
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
            exports['th_power']:LogSpellCast(data)
            TriggerClientEvent('th_sanguiris:otherPlayerCasting', -1, source)
            TriggerClientEvent('th_sanguiris:prepareProjectile', source, target or 0, spellLevel)
            return true
        end
    }
    exports['th_power']:registerModule(moduleData, 0)
    print('[th_sanguiris] Module enregistré avec succès')
end

RegisterNetEvent('th_sanguiris:broadcastProjectile', function(targetCoords, targetId, level)
    local _source = source
    if not targetCoords then return end
    TriggerClientEvent('th_sanguiris:spawnProjectile', -1, _source, targetCoords, targetId or 0, level or 0)
end)

RegisterNetEvent('th_sanguiris:applyBleed', function(victimId, level)
    local _source = source
    if not victimId or victimId <= 0 then return end
    if victimId == _source then return end

    if exports['th_prothea'] and exports['th_prothea'].hasActiveShield and exports['th_prothea']:hasActiveShield(victimId) then
        return
    end

    local tickDamage = Config.Bleed.tickDamage or 5
    local tickInterval = Config.Bleed.tickInterval or 2000
    local maxDuration = Config.Bleed.maxDuration or 20000

    local endAt = GetGameTimer() + maxDuration
    bleeding[victimId] = { endAt = endAt, damage = tickDamage, interval = tickInterval }

    local ragdollDuration = Config.Bleed.ragdollDuration or 20000
    
    TriggerClientEvent('th_sanguiris:startBleed', victimId, tickDamage, tickInterval, maxDuration, Config.Bleed.fx or {})
    TriggerClientEvent('th_sanguiris:bleedImpactFx', -1, victimId, Config.Bleed.fx or {})
    TriggerClientEvent('th_sanguiris:ragdoll', victimId, ragdollDuration)
end)

RegisterNetEvent('th_sanguiris:stopBleed', function(targetId)
    local _source = source
    if not targetId or targetId <= 0 then
        targetId = _source
    end
    bleeding[targetId] = nil
    TriggerClientEvent('th_sanguiris:stopBleed', targetId)
    TriggerClientEvent('th_sanguiris:stopBleedFx', -1, targetId)
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
                TriggerClientEvent('th_sanguiris:bleedRecurrentFx', -1, victimId, Config.Bleed.fx or {})
            end
        end
        
        for _, victimId in ipairs(toRemove) do
            bleeding[victimId] = nil
            TriggerClientEvent('th_sanguiris:stopBleed', victimId)
            TriggerClientEvent('th_sanguiris:stopBleedFx', -1, victimId)
        end
    end
end)

CreateThread(function()
    while GetResourceState('th_power') ~= 'started' do
        Wait(100)
    end
    Wait(500)
    RegisterSanguirisModule()
end)

AddEventHandler('onResourceStart', function(resourceName)
    if resourceName == 'th_power' then
        Wait(1000)
        RegisterSanguirisModule()
    end
end)
