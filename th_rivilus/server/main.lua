---@diagnostic disable: undefined-global, trailing-space, unused-local
local function Notify(sourceId, payload)
    if not payload then
        return
    end
    TriggerClientEvent('ox_lib:notify', sourceId, payload)
end

local levelProfiles <const> = {
    [1] = {
        types = { object = true, vehicle = true },
        extraDuration = 0
    },
    [2] = {
        types = { object = true, vehicle = true, ped = true },
        extraDuration = 5000
    },
    [3] = {
        types = { object = true, vehicle = true, ped = true },
        extraDuration = 10000
    },
    [4] = {
        types = { object = true, vehicle = true, ped = true, player = true },
        extraDuration = 20000
    },
    [5] = {
        types = { object = true, vehicle = true, ped = true, player = true },
        extraDuration = 30000
    }
}

local function BuildScanSettings(level)
    local scan <const> = Config.Scan or {}
    local lvl <const> = math.max(tonumber(level) or 0, 0)
    local profileIdx <const> = math.min(math.max(math.floor(lvl), 1), 5)
    local profile <const> = levelProfiles[profileIdx] or levelProfiles[1]

    local radius = (scan.baseRadius or 30.0) + ((scan.perLevel or 0.0) * lvl)
    if scan.maxRadius then
        radius = math.min(radius, scan.maxRadius)
    end

    return {
        radius = radius,
        duration = (scan.duration or 8000) + (profile.extraDuration or 0),
        maxEntities = scan.maxEntities or 50,
        outline = Config.Outline or {},
        types = profile.types
    }
end

local function RegisterRivilusModule()
    local moduleData <const> = {
        id = Config.Module.id,
        name = Config.Module.name,
        description = Config.Module.description,
        icon = Config.Module.icon,
        color = Config.Module.color,
        cooldown = Config.Module.cooldown or 12000,
        type = Config.Module.type,
        isBasic = false,
        key = Config.Module.key,
        image = Config.Module.image or 'images/power/nvision.png',
        video = Config.Module.video or "YOUR_VIDEO_URL_HERE",
        professor = Config.Module.professor ~= false,
        soundType = '3d',
        sound = Config.Module.sound or 'YOUR_SOUND_URL_HERE',
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

            local spellLevel = level ~= nil and math.floor(tonumber(level) or 0) or GetCasterLevel(source)
            local settings <const> = BuildScanSettings(spellLevel)
            local data = {
                professor = { source = source },
                --target = { source = target }, -- f
                spell = { id = 'rivilus', name = 'Rivilus', level = spellLevel },
                context = { temp = false, coords = source and GetEntityCoords(GetPlayerPed(source)) or nil}
            }
            exports['th_power']:LogSpellCast(data)
            TriggerClientEvent('th_rivilus:reveal', source, settings)
            return true
        end
    }

    exports['th_power']:registerModule(moduleData, 0)
    print('[th_rivilus] Module enregistré avec succès')
end

CreateThread(function()
    while GetResourceState('th_power') ~= 'started' do
        Wait(100)
    end

    Wait(500)
    RegisterRivilusModule()
end)

AddEventHandler('onResourceStart', function(resourceName)
    if resourceName == 'th_power' then
        Wait(1000)
        RegisterRivilusModule()
    end
end)
