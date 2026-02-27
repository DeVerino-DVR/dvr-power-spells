---@diagnostic disable: undefined-global, trailing-space
local math_max = math.max

local function RegisterLevionisModule()
    local animCfg = Config.Animation or {}
    local levCfg = Config.Levitation or {}
    local castDuration = animCfg.duration or 800
    local moduleData <const> = {
        id = 'levionis',
        name = 'Levionis',
        description = "Délie une cible ou un objet de l’emprise terrestre et le fait léviter.",
        icon = 'hand',
        color = 'blue',
        cooldown = 5000,
        type = 'control',
        level = 2,
        castTime = castDuration,
        sound = 'YOUR_SOUND_URL_HERE',
        soundType = "3d",
        key = nil,
        image = "images/power/darkpunch.png",
        video = "YOUR_VIDEO_URL_HERE",
        animation = {
            dict = animCfg.dict,
            name = animCfg.name,
            flag = animCfg.flag,
            duration = animCfg.duration
        },
        effect = {
            particle = true,
            sound = 'wingardium'
        },
        onCast = function(hasItem, raycast, source, target, level)
            if not hasItem then
                TriggerClientEvent('ox_lib:notify', source, {
                    title = 'Levionis',
                    description = 'Vous n\'avez pas de baguette équipée',
                    type = 'error',
                    icon = 'hand'
                })
                return false
            end
            
            if not raycast or not raycast.hitCoords then
                TriggerClientEvent('ox_lib:notify', source, {
                    title = 'Levionis',
                    description = 'Aucune cible détectée',
                    type = 'warning',
                    icon = 'hand'
                })
                return false
            end
            
            local spellLevel = tonumber(level) or 0
            if spellLevel <= 0 then
                return true
            end

            local controlDuration = nil
            if spellLevel == 2 then
                controlDuration = 2000
            elseif spellLevel == 3 then
                controlDuration = 10000
            end

            local desiredDuration = levCfg.duration or 5000
            if controlDuration then
                local riseBuffer = (levCfg.riseTime or 0) + 500
                desiredDuration = math_max(desiredDuration, controlDuration + riseBuffer)
            end
            
            local targetCoords = raycast.hitCoords

            
            
            if target and target ~= -1 then
                if exports['dvr_prothea'] and exports['dvr_prothea'].hasActiveShield and exports['dvr_prothea']:hasActiveShield(target) then
                    print(string.format('[Levionis] annulé par Prothea pour %s', target))
                    return false
                end
                TriggerClientEvent('dvr_levionis:startLevitation', -1, target, source, desiredDuration, levCfg.height or 1.5, targetCoords, spellLevel)
            else
                TriggerClientEvent('dvr_levionis:startLevitation', -1, -1, source, desiredDuration, levCfg.height or 1.5, targetCoords, spellLevel)
            end

            local spellLevel = level ~= nil and math.floor(tonumber(level) or 0) or GetCasterLevel(source)
            local data = {
                professor = { source = source },
                target = { source = target }, -- f
                spell = { id = 'levionis', name = 'Levionis', level = spellLevel },
                context = { temp = false, coords = source and GetEntityCoords(GetPlayerPed(source)) or nil}
            }
            exports['dvr_power']:LogSpellCast(data)
            
            return true
        end
    }

    exports['dvr_power']:registerModule(moduleData, 0)
    print('[dvr_levionis] Module enregistré avec succès')
end

CreateThread(function()
    while GetResourceState('dvr_power') ~= 'started' do
        Wait(100)
    end
    
    Wait(500)
    RegisterLevionisModule()
end)


AddEventHandler('onResourceStart', function(resourceName)
    if resourceName == 'dvr_power' then
        Wait(1000)
        RegisterLevionisModule()
    end
end)
