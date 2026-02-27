---@diagnostic disable: undefined-global, trailing-space, unused-local
local function Notify(sourceId, payload)
    if not payload then
        return
    end
    TriggerClientEvent('ox_lib:notify', sourceId, payload)
end

-- Get duration based on spell level
local function GetDurationForLevel(level)
    local levelNum = tonumber(level) or 0
    local durations = Config.DurationByLevel or {}
    return durations[levelNum] or durations[0] or Config.Buff.baseDuration or 10000
end

RegisterNetEvent('dvr_altis:applyJump', function(targetServerId, spellLevel)
    local _source <const> = source
    local target = targetServerId and targetServerId > 0 and targetServerId or _source
    
    -- Get spell level for duration calculation
    local level = spellLevel
    if not level then
        -- Fallback: use export to get spell level
        local hasSpell, levelFromExport = exports['dvr_power']:GetSpell(_source, 'altis')
        level = levelFromExport or 0
    end
    local duration = GetDurationForLevel(level)
    
    TriggerClientEvent('dvr_altis:grantJump', target, duration, _source ~= target)
end)

local function RegisterAltisModule()
    local moduleData <const> = {
        id = Config.Module.id,
        name = Config.Module.name,
        description = Config.Module.description,
        icon = Config.Module.icon,
        color = Config.Module.color,
        cooldown = Config.Module.cooldown or 10000,
        type = Config.Module.type,
        isBasic = false,
        key = Config.Module.key,
        sound = '',
        soundType = "3d",
        image = Config.Module.image or "images/power/dvr_altis.png",
        video = "YOUR_VIDEO_URL_HERE",
        professor = Config.Module.professor ~= false,
        animation = {
            dict = 'export@nib@wizardsv_wand_attack_b2',
            name = 'nib@wizardsv_wand_attack_b2',
            flag = 0,
            duration = 1500
        },
        onCast = function(hasItem, raycast, source, target, level)
            if not hasItem then
                Notify(source, Config.Messages and Config.Messages.noWand)
                return false
            end
            local spellLevel = level ~= nil and math.floor(tonumber(level) or 0) or 0
            -- Fallback: get level from export if not provided
            if spellLevel == 0 then
                local hasSpell, levelFromExport = exports['dvr_power']:GetSpell(source, 'altis')
                spellLevel = levelFromExport or 0
            end
            local data = {
                professor = { source = source },
                --target = { source = target }, -- f
                spell = { id = 'altis', name = 'Altis', level = spellLevel },
                context = { temp = false, coords = source and GetEntityCoords(GetPlayerPed(source)) or nil}
            }
            exports['dvr_power']:LogSpellCast(data)
            TriggerClientEvent('dvr_altis:otherPlayerCasting', -1, source)
            TriggerClientEvent('dvr_altis:prepareJump', source, target or 0, spellLevel)
            return true
        end
    }

    exports['dvr_power']:registerModule(moduleData, 0)
    print('[dvr_altis] Module enregistré avec succès')
end

CreateThread(function()
    while GetResourceState('dvr_power') ~= 'started' do
        Wait(100)
    end

    Wait(500)
    RegisterAltisModule()
end)

AddEventHandler('onResourceStart', function(resourceName)
    if resourceName == 'dvr_power' then
        Wait(1000)
        RegisterAltisModule()
    end
end)

