---@diagnostic disable: undefined-global, trailing-space, unused-local
local castCache = {}

local function Notify(sourceId, payload)
    if not payload then
        return
    end
    TriggerClientEvent('ox_lib:notify', sourceId, payload)
end

local function clampNumber(value)
    local n = tonumber(value)
    if not n then
        return nil
    end
    if n ~= n or n == math.huge or n == -math.huge then
        return nil
    end
    return n
end

RegisterNetEvent('th_fumora:cast', function(coords)
    local sourceId <const> = source
    if not coords then
        return
    end

    local x = clampNumber(coords.x)
    local y = clampNumber(coords.y)
    local z = clampNumber(coords.z)
    if not x or not y or not z then
        return
    end

    local casterPed = GetPlayerPed(sourceId)
    if not casterPed or casterPed == 0 then
        return
    end

    local casterCoords = GetEntityCoords(casterPed)
    local maxDist = (Config.Raycast and Config.Raycast.maxDistance) or 60.0
    local dx = casterCoords.x - x
    local dy = casterCoords.y - y
    local dz = casterCoords.z - z
    local distSq = (dx * dx) + (dy * dy) + (dz * dz)
    if distSq > ((maxDist + 6.0) * (maxDist + 6.0)) then
        return
    end

    local duration = (Config.SmokeScreen and Config.SmokeScreen.duration) or 10000
    local screenId = ('fumora_%s_%s'):format(sourceId, GetGameTimer())

    local cached = castCache[sourceId]
    castCache[sourceId] = nil

    TriggerClientEvent('th_fumora:spawn', -1, screenId, { x = x, y = y, z = z }, duration)
end)

local function RegisterFumoraModule()
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
        sound = '',
        soundType = "3d",
        image = Config.Module.image or "images/power/th_fumania.png",
        video = Config.Module.video or "YOUR_VIDEO_URL_HERE", 
        professor = Config.Module.professor ~= false,
        animation = {
            dict = 'export@nib@wizardsv_avada_kedrava',
            name = 'nib@wizardsv_avada_kedrava',
            flag = 0,
            duration = 3000,
            speedMultiplier = 3.5
        },
        onCast = function(hasItem, _, sourceId, _, level)
            if not hasItem then
                Notify(sourceId, Config.Messages and Config.Messages.noWand)
                return false
            end

            castCache[sourceId] = { level = level }

            local spellLevel = level ~= nil and math.floor(tonumber(level) or 0) or GetCasterLevel(sourceId)
            local data = {
                professor = { source = sourceId },
                spell = { id = Config.Module.id, name = Config.Module.name, level = spellLevel },
                context = { temp = false, coords = sourceId and GetEntityCoords(GetPlayerPed(sourceId)) or nil }
            }
            exports['th_power']:LogSpellCast(data)

            TriggerClientEvent('th_fumora:otherPlayerCasting', -1, sourceId)
            TriggerClientEvent('th_fumora:prepare', sourceId)
            return true
        end
    }

    exports['th_power']:registerModule(moduleData, 0)
    print('[th_fumora] Module enregistré avec succès')
end

CreateThread(function()
    while GetResourceState('th_power') ~= 'started' do
        Wait(100)
    end
    Wait(500)
    RegisterFumoraModule()
end)

AddEventHandler('onResourceStart', function(resourceName)
    if resourceName == 'th_power' then
        Wait(1000)
        RegisterFumoraModule()
    end
end)

