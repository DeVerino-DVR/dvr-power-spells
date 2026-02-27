---@diagnostic disable: undefined-global, trailing-space, param-type-mismatch
local function registerModule()
    local spell <const> = Config.Spell or {}

    local moduleData <const> = {
        id = spell.id or 'desarmis',
        name = spell.name or 'Desarmis',
        description = spell.description or "Arrache l’objet tenu par la cible à son emprise par une impulsion magique précise.",
        icon = spell.icon or 'hand-sparkles',
        color = spell.color or 'red',
        cooldown = spell.cooldown or 8000,
        type = spell.type or 'attack',
        key = spell.key,
        image = spell.image,
        video = spell.video,
        sound = spell.sound,
        soundType = spell.soundType,
        castTime = spell.castTime or 2000,
        animation = spell.animation,
        selfCast = false,
        onCast = function(hasWand, _, source, target, spellLevel)
            if not hasWand then
                if Config.Messages and Config.Messages.noWand then
                    lib.notify(source, Config.Messages.noWand)
                end
                return false
            end

            if not target or target <= 0 then
                if Config.Messages and Config.Messages.noTarget then
                    lib.notify(source, Config.Messages.noTarget)
                end
                return false
            end

            if exports['th_prothea'] and exports['th_prothea'].hasActiveShield and exports['th_prothea']:hasActiveShield(target) then
                print(string.format('[th_desarmis] annule par Prothea pour %s', target))
                return false
            end

            local spellLevelNum = spellLevel ~= nil and math.floor(tonumber(spellLevel) or 0) or 0
            local data = {
                professor = { source = source },
                target = { source = target }, -- f
                spell = { id = 'desarmis', name = 'Desarmis', level = spellLevelNum },
                context = { temp = false, coords = source and GetEntityCoords(GetPlayerPed(source)) or nil}
            }
            exports['th_power']:LogSpellCast(data)

            TriggerClientEvent('th_desarmis:onCast', source, target, spellLevelNum)
            return true
        end
    }

    exports['th_power']:registerModule(moduleData, 0)
    print('[th_desarmis] Module enregistré avec succès')
end

RegisterNetEvent('th_desarmis:disarmTarget', function(targetId)
    local src = source

    if not targetId or targetId <= 0 then
        if Config.Messages and Config.Messages.failed then
            lib.notify(src, Config.Messages.failed)
        end
        return
    end

    local targetInventory = exports.ft_inventory:GetInventory(targetId)
    if not targetInventory then
        if Config.Messages and Config.Messages.failed then
            lib.notify(src, Config.Messages.failed)
        end
        return
    end

    local equippedWand = nil
    if targetInventory.items then
        for _, item in pairs(targetInventory.items) do
            if item.item == 'wand' and item.isWeared then
                equippedWand = item
                break
            end
        end
    end

    if not equippedWand then
        if Config.Messages and Config.Messages.targetNoWand then
            lib.notify(src, Config.Messages.targetNoWand)
        end
        return
    end

    if exports['th_prothea'] and exports['th_prothea'].hasActiveShield and exports['th_prothea']:hasActiveShield(targetId) then
        print(string.format('[th_desarmis] disarm annule par Prothea pour %s', targetId))
        if Config.Messages and Config.Messages.failed then
            lib.notify(src, Config.Messages.failed)
        end
        return
    end

    -- Utiliser le système holstered au lieu de retirer/rajouter l'item
    -- Cela simule l'appui sur G et évite les problèmes d'inventaire plein
    equippedWand.meta = equippedWand.meta or {}
    equippedWand.meta.holstered = true

    -- Mettre à jour l'item et rafraîchir l'arme équipée
    if targetInventory.OnItemUpdate then
        targetInventory:OnItemUpdate(equippedWand)
    end
    if targetInventory.refreshUsedWeapon then
        targetInventory:refreshUsedWeapon()
    end

    -- Notifier les observateurs du changement de meta
    if targetInventory.triggerObservers then
        targetInventory:triggerObservers(function(observer)
            TriggerClientEvent("PLAYER_SEND_NUI_MESSAGE", observer, {
                event = "SET_ITEM_META_FIELD",
                inventoryUniqueId = targetInventory.inventoryUniqueId,
                itemHash = equippedWand.itemHash,
                metaKey = "holstered",
                metaValue = true
            })
        end)
    end

    if Config.Messages and Config.Messages.success then
        lib.notify(src, Config.Messages.success)
    end

    TriggerClientEvent('th_desarmis:disarmed', targetId)
    TriggerClientEvent('th_desarmis:playImpact', -1, targetId)
end)

CreateThread(function()
    while GetResourceState('th_power') ~= 'started' do
        Wait(250)
    end

    Wait(500)
    registerModule()
end)

AddEventHandler('onResourceStart', function(resourceName)
    if resourceName == 'th_power' or resourceName == GetCurrentResourceName() then
        Wait(1000)
        registerModule()
    end
end)
