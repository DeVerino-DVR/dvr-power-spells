---@diagnostic disable: undefined-global, trailing-space, unused-local
local castCache = {}

local function Notify(sourceId, payload)
    if not payload then
        return
    end

    TriggerClientEvent('ox_lib:notify', sourceId, payload)
end

local function clampLevel(level)
    local numeric = math.floor(tonumber(level) or 1)
    if numeric < 1 then
        return 1
    end
    if numeric > 5 then
        return 5
    end
    return numeric
end

RegisterNetEvent('dvr_cyclone:trigger', function(targetCoords)
    local _source <const> = source

    if not targetCoords then
        return
    end

    local cached = castCache[_source]
    local level = clampLevel(cached and cached.level or 1)
    castCache[_source] = nil

    TriggerClientEvent('dvr_cyclone:createCyclone', -1, _source, targetCoords, level)
end)

local function RegisterCycloneModule()
    local moduleData <const> = {
        id = Config.Module.id,
        name = Config.Module.name,
        description = Config.Module.description,
        icon = Config.Module.icon,
        color = Config.Module.color,
        cooldown = Config.Module.cooldown or 9000,
        type = Config.Module.type,
        isBasic = false,
        sound = 'YOUR_SOUND_URL_HERE',
        soundType = "3d",
        image = Config.Module.image or "images/power/dvr_cyclone.png",
        video = Config.Module.video or "YOUR_VIDEO_URL_HERE",
        professor = Config.Module.professor ~= false,
        hidden = true,
        animation = {
            dict = 'export@nib@wizardsv_wand_attack_lightning',
            name = 'nib@wizardsv_wand_attack_lightning',
            flag = 48,
            duration = 1500
        },
        onCast = function(hasItem, raycast, source, target, level)
            if not hasItem then
                Notify(source, Config.Messages and Config.Messages.noWand)
                return false
            end

            local clamped = clampLevel(level)
            castCache[source] = { level = clamped }

            local spellLevel = level ~= nil and math.floor(tonumber(level) or 0) or GetCasterLevel(source)
            local data = {
                professor = { source = source },
                --target = { source = target }, -- f
                spell = { id = 'cyclone', name = 'Cyclone', level = spellLevel },
                context = { temp = false, coords = source and GetEntityCoords(GetPlayerPed(source)) or nil}
            }
            exports['dvr_power']:LogSpellCast(data)

            TriggerClientEvent('dvr_cyclone:otherPlayerCasting', -1, source, clamped)
            TriggerClientEvent('dvr_cyclone:prepare', source, clamped)
            return true
        end
    }

    exports['dvr_power']:registerModule(moduleData, 0)
    print('[dvr_cyclone] Module enregistré avec succès')
end

CreateThread(function()
    while GetResourceState('dvr_power') ~= 'started' do
        Wait(100)
    end
    Wait(500)
    RegisterCycloneModule()
end)

AddEventHandler('onResourceStart', function(resourceName)
    if resourceName == 'dvr_power' then
        Wait(1000)
        RegisterCycloneModule()
    end
end)
