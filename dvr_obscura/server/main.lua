---@diagnostic disable: undefined-global, trailing-space, unused-local
local function Notify(sourceId, payload)
    if not payload then
        return
    end
    TriggerClientEvent('ox_lib:notify', sourceId, payload)
end

local levelProfiles <const> = {
    [1] = { mode = 'flash', flashDuration = 800 },
    [2] = { mode = 'blink', blinkInterval = 400, blinkCount = 8 },
    [3] = { mode = 'blackout', duration = 10000 },
    [4] = { mode = 'blackout', duration = Config.Duration or 30000 },
    [5] = { mode = 'blackout', duration = 60000 }
}

local function BuildBlackoutSettings(level)
    local lvl <const> = math.max(math.floor(tonumber(level) or 1), 1)
    local profile <const> = levelProfiles[math.min(lvl, 5)] or levelProfiles[1]

    return {
        mode = profile.mode or 'blackout',
        duration = profile.duration or Config.Duration or 30000,
        blinkInterval = profile.blinkInterval or 400,
        blinkCount = profile.blinkCount or 8,
        flashDuration = profile.flashDuration or 800
    }
end

RegisterNetEvent('dvr_obscura:startBlackout', function(level)
    local _source <const> = source
    local settings <const> = BuildBlackoutSettings(level)
    TriggerClientEvent('dvr_obscura:applyBlackout', -1, _source, settings)
end)

local function RegisterObscuraModule()
    local moduleData <const> = {
        id = Config.Module.id,
        name = Config.Module.name,
        description = Config.Module.description,
        icon = Config.Module.icon,
        color = Config.Module.color,
        cooldown = Config.Module.cooldown or 10000,
        type = Config.Module.type,
        isBasic = false,
        sound = '',
        soundType = "3d",
        image = Config.Module.image or "images/power/dvr_obscura.png",
        video = Config.Module.video or "YOUR_VIDEO_URL_HERE",
        professor = Config.Module.professor ~= false,
        animation = {
            dict = 'export@nib@wizardsv_avada_kedrava',
            name = 'nib@wizardsv_avada_kedrava',
            flag = 48,
            duration = 3000
        },
        onCast = function(hasItem, raycast, source, target, level)
            if not hasItem then
                Notify(source, Config.Messages and Config.Messages.noWand)
                return false
            end
            TriggerClientEvent('dvr_obscura:otherPlayerCasting', -1, source)
            local lvl <const> = math.max(math.floor(tonumber(level) or 1), 1)
            TriggerClientEvent('dvr_obscura:prepareBlackout', source, lvl)
            local spellLevel = level ~= nil and math.floor(tonumber(level) or 0) or GetCasterLevel(source)
            local data = {
                professor = { source = source },
                --target = { source = target }, -- f
                spell = { id = 'obscura', name = 'Obscura', level = spellLevel },
                context = { temp = false, coords = source and GetEntityCoords(GetPlayerPed(source)) or nil}
            }
            exports['dvr_power']:LogSpellCast(data)
            return true
        end
    }
    exports['dvr_power']:registerModule(moduleData, 0)
    print('[dvr_obscura] Module enregistré avec succès')
end

CreateThread(function()
    while GetResourceState('dvr_power') ~= 'started' do
        Wait(100)
    end
    Wait(500)
    RegisterObscuraModule()
end)

AddEventHandler('onResourceStart', function(resourceName)
    if resourceName == 'dvr_power' then
        Wait(1000)
        RegisterObscuraModule()
    end
end)
