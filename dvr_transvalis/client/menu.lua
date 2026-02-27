---@diagnostic disable: trailing-space, undefined-global
local transvalisConfig = {}
local savedPositions = {}
local currentSpellLevel = 1
local isMenuClosing = false

local function LoadTransvalisConfig()
    if not exports['dvr_power'] then return end

    local hasGetSpellConfig = pcall(function() return exports['dvr_power'].GetSpellConfig end)
    if not hasGetSpellConfig then return end

    local loadedConfig = exports['dvr_power']:GetSpellConfig('transvalis')
    
    -- Copier d'abord les valeurs par défaut
    transvalisConfig = {}
    for k, v in pairs(Config.SpellConfig.default) do
        transvalisConfig[k] = v
    end
    
    -- Puis écraser avec les valeurs chargées (y compris nil pour customColor)
    for k, v in pairs(loadedConfig) do
        transvalisConfig[k] = v
    end
    
    -- S'assurer que customColor est explicitement défini (même si nil)
    if not rawget(transvalisConfig, 'customColor') then
        transvalisConfig.customColor = loadedConfig.customColor or Config.SpellConfig.default.customColor
    end
    
    -- Synchronize customColor to state bag for server access
    if LocalPlayer and LocalPlayer.state then
        LocalPlayer.state:set('transvalisCustomColor', transvalisConfig.customColor, true)
    end
    
    savedPositions = transvalisConfig.savedPositions or {}
    if type(savedPositions) ~= 'table' then
        savedPositions = {}
    end

    if exports['dvr_power'] and exports['dvr_power'].GetSpell then
        local ok, _, level = pcall(function() 
            return exports['dvr_power']:GetSpell('transvalis')
        end)
        
        if ok and level and tonumber(level) then
            currentSpellLevel = math.max(1, math.min(5, tonumber(level)))
        else
            currentSpellLevel = 1
        end
    else
        currentSpellLevel = 1
    end

    if currentSpellLevel < 1 then currentSpellLevel = 1 end
    if currentSpellLevel > 5 then currentSpellLevel = 5 end

    return transvalisConfig
end

local function SaveTransvalisConfig(skipCallback)
    if not exports['dvr_power'] then return false end

    local hasSaveSpellConfig = pcall(function() return exports['dvr_power'].SaveSpellConfig end)
    if not hasSaveSpellConfig then return false end

    transvalisConfig.savedPositions = savedPositions
    
    -- S'assurer que customColor est toujours présent dans la config à sauvegarder
    -- Même si nil, on veut le sauvegarder explicitement
    if not rawget(transvalisConfig, 'customColor') then
        transvalisConfig.customColor = nil
    end
    
    -- Synchronize customColor to state bag for server access
    if LocalPlayer and LocalPlayer.state then
        LocalPlayer.state:set('transvalisCustomColor', transvalisConfig.customColor, true)
    end
    
    return exports['dvr_power']:SaveSpellConfig('transvalis', transvalisConfig, skipCallback)
end

local function GetMaxPositions()
    local limits = Config.SpellConfig.levelLimits[currentSpellLevel]
    return limits and limits.maxPositions or 1
end

local function GetTrailColor()
    local config = transvalisConfig or {}
    
    -- Si une couleur personnalisée est définie, l'utiliser
    if config.customColor then
        for _, colorData in ipairs(Config.SpellConfig.customColors) do
            if colorData.value == config.customColor then
                return colorData.value
            end
        end
    end
    
    -- Sinon, utiliser la couleur du job
    return LocalPlayer.state.job and LocalPlayer.state.job.name or 'default'
end

local function SaveCurrentPosition(slot, positionName)
    if not slot or slot < 1 or slot > GetMaxPositions() then
        lib.notify({
            title = 'Erreur',
            description = 'Slot invalide ou niveau insuffisant',
            type = 'error'
        })
        return false
    end

    local playerPed = cache.ped
    if not playerPed then return false end

    local coords = GetEntityCoords(playerPed)
    local heading = GetEntityHeading(playerPed)

    savedPositions[tostring(slot)] = {
        x = coords.x,
        y = coords.y,
        z = coords.z,
        h = heading,
        name = positionName or string.format("Position %d", slot)
    }

    local saveResult = SaveTransvalisConfig()

    if saveResult then
        lib.notify({
            title = 'Position sauvegardée',
            description = string.format('Position "%s" sauvegardée avec succès', savedPositions[tostring(slot)].name),
            type = 'success'
        })
    else
        lib.notify({
            title = 'Erreur',
            description = 'Échec de la sauvegarde de la position',
            type = 'error'
        })
    end

    return saveResult
end

local function SavePositionWithName(slot, isUpdate)
    local existingPosition = savedPositions[tostring(slot)]
    local defaultName = existingPosition and existingPosition.name or string.format("Position %d", slot)
    
    local input = lib.inputDialog(isUpdate and 'Mettre à jour la position' or 'Sauvegarder la position', {
        { 
            type = 'input', 
            label = 'Nom de la position', 
            placeholder = 'Ex: Maison, École, Bureau...',
            default = defaultName,
            required = true,
            min = 1,
            max = 50
        }
    })

    if not input or not input[1] or input[1] == '' then
        return false
    end

    return SaveCurrentPosition(slot, input[1])
end

local function LoadSavedPosition(slot)
    local position = savedPositions[tostring(slot)]
    if not position then
        lib.notify({
            title = 'Erreur',
            description = 'Aucune position sauvegardée dans ce slot',
            type = 'error'
        })
        return false
    end

    local playerPed = cache.ped
    if not playerPed then return false end

    -- Vérifier que le sort est équipé
    local hasSpell, spellLevel = false, 0
    if exports['dvr_power'] and exports['dvr_power'].GetSpell then
        local ok, has, level = pcall(function()
            return exports['dvr_power']:GetSpell('transvalis')
        end)
        if ok and has and level then
            hasSpell = true
            spellLevel = tonumber(level) or 0
        end
    end

    if not hasSpell then
        lib.notify({
            title = 'Erreur',
            description = 'Vous devez avoir le sort Transvalis équipé',
            type = 'error'
        })
        return false
    end

    -- Vérifier que le sort est sélectionné
    local selectedSpell = nil
    if exports['dvr_power'] and exports['dvr_power'].getSelectedSpell then
        selectedSpell = exports['dvr_power']:getSelectedSpell()
    end

    if selectedSpell ~= 'transvalis' then
        lib.notify({
            title = 'Erreur',
            description = 'Vous devez avoir le sort Transvalis sélectionné',
            type = 'error'
        })
        return false
    end

    -- Vérifier que la baguette est équipée
    local weapon = cache.weapon
    local wandHash = GetHashKey('WEAPON_WAND')
    if weapon ~= wandHash then
        lib.notify({
            title = 'Erreur',
            description = 'Vous devez avoir la baguette en main',
            type = 'error'
        })
        return false
    end

    if exports['dvr_transvalis'] and exports['dvr_transvalis'].SaveReturnPosition then
        exports['dvr_transvalis']:SaveReturnPosition()
    else
        TriggerEvent('dvr_transvalis:saveReturnPosition')
    end
    
    Wait(10)

    local myServerId = GetPlayerServerId(PlayerId())
    TriggerServerEvent('dvr_transvalis:broadcastStart', myServerId, 2000, nil)

    CreateThread(function()
        Wait(2000)

        local ped = cache.ped
        if not ped then return end

        local currentCoords = GetEntityCoords(ped)
        local targets = {}

        if transvalisConfig.bringPlayers then
            local radius = transvalisConfig.bringRadius or 5.0
            local r2 = radius * radius

            for _, player in ipairs(GetActivePlayers()) do
                if player ~= PlayerId() then
                    local targetPed = GetPlayerPed(player)
                    if targetPed and targetPed ~= 0 then
                        local targetCoords = GetEntityCoords(targetPed)
                        local dx = targetCoords.x - currentCoords.x
                        local dy = targetCoords.y - currentCoords.y
                        if (dx * dx + dy * dy) <= r2 then
                            local serverId = GetPlayerServerId(player)
                            table.insert(targets, {
                                serverId = serverId,
                                originalCoords = {
                                    x = targetCoords.x,
                                    y = targetCoords.y,
                                    z = targetCoords.z,
                                    h = GetEntityHeading(targetPed)
                                }
                            })
                        end
                    end
                end
            end

            if #targets > 0 and exports['dvr_transvalis'] and exports['dvr_transvalis'].SetTeleportedPlayers then
                exports['dvr_transvalis']:SetTeleportedPlayers(targets)
            end
        end

        if exports['dvr_transvalis'] and exports['dvr_transvalis'].StopTransplanning then
            exports['dvr_transvalis']:StopTransplanning(false)
        end

        Wait(50)

        SetEntityCoords(ped, position.x, position.y, position.z, false, false, false, true)
        SetEntityHeading(ped, position.h)

        Wait(200) -- Délai pour laisser le temps au monde de charger/joueurs de streamer

        TriggerServerEvent('dvr_transvalis:broadcastStart', myServerId, 4000, nil)

        if #targets > 0 then
            Wait(100)
            
            local destinationCoords = { 
                x = tonumber(position.x), 
                y = tonumber(position.y), 
                z = tonumber(position.z) 
            }
            
            TriggerServerEvent('dvr_transvalis:teleportMultiplePlayers', targets, destinationCoords)

            lib.notify({
                title = 'Téléportation',
                description = string.format('Téléporté vers %s avec %d joueur(s)', position.name, #targets),
                type = 'success'
            })
        else
            lib.notify({
                title = 'Téléportation',
                description = string.format('Téléporté vers %s', position.name),
                type = 'success'
            })
        end

        Wait(4000)

        local arrivalCoords = {
            x = position.x,
            y = position.y,
            z = position.z
        }
        TriggerServerEvent('dvr_transvalis:broadcastArrivalEffects', myServerId, arrivalCoords)

        if exports['dvr_transvalis'] and exports['dvr_transvalis'].StopTransplanning then
            exports['dvr_transvalis']:StopTransplanning(false)
        end
    end)

    return true
end

local function DeleteSavedPosition(slot)
    if not savedPositions[tostring(slot)] then
        lib.notify({
            title = 'Erreur',
            description = 'Aucune position dans ce slot',
            type = 'error'
        })
        return false
    end

    savedPositions[tostring(slot)] = nil
    SaveTransvalisConfig()

    lib.notify({
        title = 'Position supprimée',
        description = string.format('Position %d supprimée', slot),
        type = 'success'
    })

    return true
end

local function ReloadSpellLevel()
    if exports['dvr_power'] and exports['dvr_power'].GetSpell then
        local ok, _, level = pcall(function() 
            return exports['dvr_power']:GetSpell('transvalis')
        end)
        
        if ok and level and tonumber(level) then
            currentSpellLevel = math.max(1, math.min(5, tonumber(level)))
            return currentSpellLevel
        end
    end
    
    if currentSpellLevel < 1 or currentSpellLevel > 5 then
        currentSpellLevel = 1
    end
    return currentSpellLevel
end

local function CreateTransvalisConfigMenu()
    LoadTransvalisConfig()
    ReloadSpellLevel()
    local maxPositions = GetMaxPositions()

    local menuOptions = {}

    menuOptions[#menuOptions + 1] = {
        label = transvalisConfig.bringPlayers and 'Désactiver Téléportation joueurs' or 'Activer Téléportation joueurs',
        description = 'Téléporter les joueurs autour de vous lors d\'une téléportation',
        icon = transvalisConfig.bringPlayers and 'fa-solid fa-toggle-on' or 'fa-solid fa-toggle-off',
        args = { action = 'toggle_bring_players' }
    }

    menuOptions[#menuOptions + 1] = {
        label = string.format('Rayon: %.1f mètres', transvalisConfig.bringRadius),
        description = 'Distance maximale pour téléporter les joueurs',
        icon = 'fa-solid fa-ruler',
        values = {
            { label = '2.5 mètres', description = 'Portée très courte' },
            { label = '5.0 mètres', description = 'Portée normale' },
            { label = '10.0 mètres', description = 'Portée étendue' },
            { label = '15.0 mètres', description = 'Portée large' },
            { label = '20.0 mètres', description = 'Portée maximale' }
        },
        args = { action = 'set_radius' }
    }

    menuOptions[#menuOptions + 1] = {
        label = "Retour à l'ancienne position",
        description = 'Renvoyer tous les joueurs téléportés à leur position initiale',
        icon = 'fa-solid fa-undo',
        args = { action = 'return_players' }
    }

    -- Option de couleur personnalisée (niveau 5 uniquement)
    if currentSpellLevel >= 5 then
        local customColorName = 'Couleur du job'
        if transvalisConfig.customColor then
            for _, colorData in ipairs(Config.SpellConfig.customColors) do
                if colorData.value == transvalisConfig.customColor then
                    customColorName = colorData.name
                    break
                end
            end
        end
        
        local colorOptions = {}
        table.insert(colorOptions, { label = 'Couleur du job', description = 'Utiliser la couleur de votre job', value = nil })
        for _, colorData in ipairs(Config.SpellConfig.customColors) do
            table.insert(colorOptions, { 
                label = colorData.name, 
                description = string.format('Couleur personnalisée: %s', colorData.name),
                value = colorData.value
            })
        end

        menuOptions[#menuOptions + 1] = {
            label = string.format('Couleur Transvalis: %s', customColorName),
            description = 'Choisir la couleur des effets du sort Transvalis',
            icon = 'fa-solid fa-palette',
            values = colorOptions,
            args = { action = 'set_custom_color' }
        }

        if transvalisConfig.customColor then
            menuOptions[#menuOptions + 1] = {
                label = 'Réinitialiser la couleur',
                description = 'Revenir à la couleur de votre job',
                icon = 'fa-solid fa-rotate-left',
                args = { action = 'reset_custom_color' }
            }
        end
    end

    menuOptions[#menuOptions + 1] = {
        label = 'Vos positions',
        description = string.format('Niveau %d - %d positions maximum', currentSpellLevel, maxPositions),
        icon = 'fa-solid fa-list',
        args = { action = 'separator' },
        disabled = true
    }

    for i = 1, maxPositions do
        local position = savedPositions[tostring(i)]
        local positionLabel = position and position.name or string.format('Slot %d (vide)', i)

        menuOptions[#menuOptions + 1] = {
            label = positionLabel,
            description = position and string.format('X: %.2f, Y: %.2f, Z: %.2f', position.x, position.y, position.z) or 'Cliquez pour sauvegarder votre position actuelle',
            icon = position and 'fa-solid fa-map-marker-alt' or 'fa-solid fa-save',
            values = position and {
                { label = 'Aller à cette position', description = 'Se téléporter vers cette position' },
                { label = 'Mettre à jour', description = 'Remplacer par la position actuelle' },
                { label = 'Supprimer', description = 'Supprimer cette position' }
            } or {
                { label = 'Sauvegarder position', description = 'Sauvegarder votre position actuelle' }
            },
            args = { action = 'position_action', slot = i }
        }
    end

    menuOptions[#menuOptions + 1] = {
        label = 'Retour au menu principal',
        description = 'Retourner à la liste des sorts configurables',
        icon = 'fa-solid fa-arrow-left',
        args = { action = 'back_to_main' }
    }

    lib.registerMenu({
        id = 'transvalis_config_menu',
        title = Config.SpellConfig.menu.title,
        subtitle = Config.SpellConfig.menu.subtitle,
        position = 'top-left',
        options = menuOptions,
        onClose = function()
            isMenuClosing = true
            SaveTransvalisConfig(true)
            SetTimeout(500, function()
                isMenuClosing = false
            end)
        end
    }, function(selected, scrollIndex, args)
        if not args then return end

        if args.action == 'toggle_bring_players' then
            transvalisConfig.bringPlayers = not (transvalisConfig.bringPlayers or false)
            SaveTransvalisConfig()
            CreateTransvalisConfigMenu()
            lib.showMenu('transvalis_config_menu')

        elseif args.action == 'set_radius' then
            local radiusOptions = {2.5, 5.0, 10.0, 15.0, 20.0}
            transvalisConfig.bringRadius = radiusOptions[scrollIndex] or 5.0
            SaveTransvalisConfig()
            CreateTransvalisConfigMenu()
            lib.showMenu('transvalis_config_menu')

        elseif args.action == 'return_players' then
            if exports['dvr_transvalis'] and exports['dvr_transvalis'].ReturnTeleportedPlayers then
                exports['dvr_transvalis']:ReturnTeleportedPlayers()
                lib.hideMenu()
            else
                lib.notify({
                    title = 'Erreur',
                    description = 'Fonction de retour non disponible',
                    type = 'error'
                })
            end

        elseif args.action == 'set_custom_color' then
            if currentSpellLevel < 5 then
                lib.notify({
                    title = 'Erreur',
                    description = 'Cette option est disponible uniquement au niveau 5',
                    type = 'error'
                })
                return
            end

            -- Reconstruire le même tableau que dans le menu
            local colorOptions = {}
            table.insert(colorOptions, { label = 'Couleur du job', description = 'Utiliser la couleur de votre job', value = nil })
            for _, colorData in ipairs(Config.SpellConfig.customColors) do
                table.insert(colorOptions, { 
                    label = colorData.name, 
                    description = string.format('Couleur personnalisée: %s', colorData.name),
                    value = colorData.value
                })
            end

            -- scrollIndex correspond à l'index dans le tableau values du menu
            local selectedOption = colorOptions[scrollIndex]
            local selectedColor = selectedOption and selectedOption.value or nil
            transvalisConfig.customColor = selectedColor
            
            SaveTransvalisConfig()
            
            local colorName = 'Couleur du job'
            if selectedColor then
                for _, colorData in ipairs(Config.SpellConfig.customColors) do
                    if colorData.value == selectedColor then
                        colorName = colorData.name
                        break
                    end
                end
            end
            
            lib.notify({
                title = 'Couleur modifiée',
                description = string.format('Couleur Transvalis définie sur: %s', colorName),
                type = 'success'
            })
            
            CreateTransvalisConfigMenu()
            lib.showMenu('transvalis_config_menu')

        elseif args.action == 'reset_custom_color' then
            if currentSpellLevel < 5 then
                lib.notify({
                    title = 'Erreur',
                    description = 'Cette option est disponible uniquement au niveau 5',
                    type = 'error'
                })
                return
            end

            transvalisConfig.customColor = nil
            SaveTransvalisConfig()
            
            lib.notify({
                title = 'Couleur réinitialisée',
                description = 'La couleur Transvalis utilise maintenant celle de votre job',
                type = 'success'
            })
            
            CreateTransvalisConfigMenu()
            lib.showMenu('transvalis_config_menu')

        elseif args.action == 'position_action' then
            local slot = args.slot
            local position = savedPositions[tostring(slot)]

            if not position then
                if SavePositionWithName(slot, false) then
                    CreateTransvalisConfigMenu()
                    lib.showMenu('transvalis_config_menu')
                end
            else
                if scrollIndex == 1 then
                    LoadSavedPosition(slot)
                    lib.hideMenu()
                elseif scrollIndex == 2 then
                    if SavePositionWithName(slot, true) then
                        CreateTransvalisConfigMenu()
                        lib.showMenu('transvalis_config_menu')
                    end
                elseif scrollIndex == 3 then
                    if DeleteSavedPosition(slot) then
                        CreateTransvalisConfigMenu()
                        lib.showMenu('transvalis_config_menu')
                    end
                end
            end

        elseif args.action == 'back_to_main' then
            lib.hideMenu()
        end
    end)

    lib.showMenu('transvalis_config_menu')
end

local function OpenTransvalisConfigMenu()
    CreateTransvalisConfigMenu()
end

exports('OpenTransvalisConfigMenu', OpenTransvalisConfigMenu)
exports('GetTransvalisConfig', function() return transvalisConfig end)
exports('GetSavedPositions', function() return savedPositions end)
exports('SaveCurrentPosition', SaveCurrentPosition)
exports('LoadSavedPosition', LoadSavedPosition)

CreateThread(function()
    while true do
        if exports['dvr_power'] then
            local hasGetSpellConfig = pcall(function() return exports['dvr_power'].GetSpellConfig end)
            local hasRegisterCallback = pcall(function() return exports['dvr_power'].RegisterSpellConfigCallback end)
            local hasRegisterConfigurable = pcall(function() return exports['dvr_power'].RegisterConfigurableSpell end)

            if hasGetSpellConfig and hasRegisterCallback and hasRegisterConfigurable then
                break
            end
        end
        Wait(100)
    end

    while not exports['dvr_power'].getPlayerSpells or #exports['dvr_power']:getPlayerSpells() == 0 do
        Wait(100)
    end

    local spellReady = false
    local attempts = 0
    while not spellReady and attempts < 50 do
        if exports['dvr_power'].GetSpell then
            local ok, _, level = pcall(function()
                return exports['dvr_power']:GetSpell('transvalis')
            end)
            if ok and level and tonumber(level) then
                spellReady = true
            end
        end
        attempts = attempts + 1
        Wait(100)
    end

    Wait(500)
    LoadTransvalisConfig()

    exports['dvr_power']:RegisterSpellConfigCallback('transvalis', function(config)
        transvalisConfig = config
        savedPositions = config.savedPositions or {}
        if not isMenuClosing then
            local currentMenu = lib.getOpenMenu()
            if not currentMenu or currentMenu ~= 'transvalis_config_menu' then
                OpenTransvalisConfigMenu()
            end
        end
    end)
end)
