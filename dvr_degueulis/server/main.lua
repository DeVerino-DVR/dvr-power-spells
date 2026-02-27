---@diagnostic disable: undefined-global, trailing-space
local function Notify(sourceId, payload)
    if not payload then
        return
    end

    TriggerClientEvent('ox_lib:notify', sourceId, payload)
end

local function RegisterDegueulisModule()
    local spell <const> = Config.Spell or {}
    local anim <const> = Config.Animation or {}

    local moduleData <const> = {
        id = spell.id or 'degueulis',
        name = spell.name or 'Degueulis',
        description = spell.description or "Sort de farce altérant brièvement l’organisme de la cible, provoquant une violente nausée.",
        icon = spell.icon or 'face-dizzy',
        color = spell.color or 'green',
        cooldown = spell.cooldown or 8000,
        type = spell.type or 'offensive',
        key = spell.key,
        image = spell.image,
        video = spell.video,
        sound = spell.sound,
        soundType = spell.soundType,
        castTime = spell.castTime or anim.duration or 1000,
        animation = {
            dict = anim.dict,
            name = anim.name,
            flag = anim.flag,
            duration = anim.duration,
            speedMultiplier = anim.speedMultiplier or 1.5
        },
        selfCast = false,
        onCast = function(hasItem, _, source, target, level)
            if not hasItem then
                Notify(source, Config.Messages and Config.Messages.noWand)
                return false
            end

            if not target or target <= 0 then
                Notify(source, Config.Messages and Config.Messages.noTarget)
                return false
            end

            if exports['dvr_prothea'] and exports['dvr_prothea'].hasActiveShield and exports['dvr_prothea']:hasActiveShield(target) then
                print(string.format('[dvr_degueulis] annule par Prothea pour %s', target))
                return false
            end

            local targetCoords = nil
            if target and target > 0 then
                local targetPed = GetPlayerPed(target)
                if targetPed and targetPed ~= 0 then
                    targetCoords = GetEntityCoords(targetPed)
                end
            end

            local spellLevel = level ~= nil and math.floor(tonumber(level) or 0) or GetCasterLevel(source)
            local data = {
                professor = { source = source },
                target = { source = target },
                spell = { id = spell.id or 'degueulis', name = spell.name or 'Degueulis', level = spellLevel },
                context = { temp = false, coords = source and GetEntityCoords(GetPlayerPed(source)) or nil }
            }
            exports['dvr_power']:LogSpellCast(data)

            if targetCoords then
                TriggerClientEvent('dvr_degueulis:fireProjectile', -1, source, targetCoords, target)
            end

            return true
        end
    }

    exports['dvr_power']:registerModule(moduleData, 0)
    print('[dvr_degueulis] Module enregistre avec succes')
end

RegisterNetEvent('dvr_degueulis:onImpact', function(targetId)
    local _source = source
    if not targetId or targetId <= 0 then
        return
    end

    if exports['dvr_prothea'] and exports['dvr_prothea'].hasActiveShield and exports['dvr_prothea']:hasActiveShield(targetId) then
        print(string.format('[dvr_degueulis] impact annule par Prothea pour %s', targetId))
        return
    end

    TriggerClientEvent('dvr_degueulis:playPuke', -1, targetId)
end)

CreateThread(function()
    while GetResourceState('dvr_power') ~= 'started' do
        Wait(100)
    end

    Wait(500)
    RegisterDegueulisModule()
end)

AddEventHandler('onResourceStart', function(resourceName)
    if resourceName == 'dvr_power' then
        Wait(1000)
        RegisterDegueulisModule()
    end
end)
