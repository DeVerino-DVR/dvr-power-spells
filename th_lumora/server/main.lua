---@diagnostic disable: undefined-global, trailing-space, unused-local
local SPELL_ID <const> = 'lumora'
local DEFAULT_KEY <const> = 'L'

local function RegisterLumoraModule()
    if GetResourceState('th_power') ~= 'started' then
        return
    end

    exports['th_power']:registerModule({
        name = 'Lumora',
        keys = DEFAULT_KEY,
        spells = {
            {
                id = SPELL_ID,
                name = 'Lumora',
                description = 'Projette une lumière continue',
                color = 'yellow',
                cooldown = 0,
                type = 'utility',
                selfCast = true,
                professor = true,
                image = 'images/power/th_lumora.png',
                keys = DEFAULT_KEY
            }
        }
    }, 0)
    print('[th_lumora] Module enregistré avec succès')
end

local function HasUnlockedLumora(sourceId)
    if GetResourceState('th_power') ~= 'started' then
        return true
    end

    local ok, hasSpell = pcall(function()
        local unlocked = exports['th_power']:GetSpell(sourceId, SPELL_ID)
        return unlocked
    end)

    if not ok then
        return true
    end

    return hasSpell == true
end

local function ResolveLumoraLevel(sourceId)
    if GetResourceState('th_power') ~= 'started' then
        return 0
    end

    local ok, hasSpell, level = pcall(function()
        return exports['th_power']:GetSpell(sourceId, SPELL_ID)
    end)

    if ok and hasSpell and level then
        return level
    end

    return 0
end

RegisterNetEvent('th_lumora:toggleLight', function()
    local source <const> = source

    if not HasUnlockedLumora(source) then
        return
    end

    local lightId = 'lumora_' .. source .. '_' .. os.time()
    local spellLevel = ResolveLumoraLevel(source)
    
    Player(source).state:set('lumos', {
        active = true,
        lightId = lightId,
        level = spellLevel
    }, true)
end)

RegisterNetEvent('th_lumora:removeLight', function()
    local source <const> = source
    Player(source).state:set('lumos', nil, true)
end)

RegisterNetEvent('th_lumora:fireProjectile', function(startCoords, targetCoords)
    local source <const> = source
    TriggerClientEvent('th_lumora:client:fireProjectile', -1, source, startCoords, targetCoords)
end)

CreateThread(function()
    while GetResourceState('th_power') ~= 'started' do
        Wait(250)
    end

    RegisterLumoraModule()
end)

AddEventHandler('onResourceStart', function(resourceName)
    if resourceName == 'th_power' then
        Wait(500)
        RegisterLumoraModule()
    end
end)
