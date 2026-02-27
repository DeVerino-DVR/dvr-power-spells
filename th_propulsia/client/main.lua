---@diagnostic disable: undefined-global, trailing-space, unused-local, param-type-mismatch, missing-parameter
local wandParticles = {}
local allParticles = {}
local activePlayerEffects = {}

-- Native caching
local RequestNamedPtfxAsset = RequestNamedPtfxAsset
local HasNamedPtfxAssetLoaded = HasNamedPtfxAssetLoaded
local UseParticleFxAsset = UseParticleFxAsset
local UseParticleFxAssetNextCall = UseParticleFxAssetNextCall
local StartParticleFxLoopedOnEntity = StartParticleFxLoopedOnEntity
local StartNetworkedParticleFxLoopedOnEntity = StartNetworkedParticleFxLoopedOnEntity
local StartParticleFxNonLoopedAtCoord = StartParticleFxNonLoopedAtCoord
local StartNetworkedParticleFxNonLoopedAtCoord = StartNetworkedParticleFxNonLoopedAtCoord
local StopParticleFxLooped = StopParticleFxLooped
local RemoveParticleFx = RemoveParticleFx
local SetParticleFxLoopedColour = SetParticleFxLoopedColour
local GetEntityCoords = GetEntityCoords
local GetPlayerFromServerId = GetPlayerFromServerId
local GetPlayerPed = GetPlayerPed
local GetPlayerServerId = GetPlayerServerId
local PlayerId = PlayerId
local DoesEntityExist = DoesEntityExist
local SetPedToRagdoll = SetPedToRagdoll
local ApplyForceToEntity = ApplyForceToEntity
local ShakeGameplayCam = ShakeGameplayCam
local PlaySoundFromCoord = PlaySoundFromCoord
local GetPedBoneIndex = GetPedBoneIndex
local GetWorldPositionOfEntityBone = GetWorldPositionOfEntityBone
local GetGameTimer = GetGameTimer

--- Check if player has Prothea shield
local function HasProtheaShield()
    local hasShield = false
    if LocalPlayer and LocalPlayer.state then
        hasShield = LocalPlayer.state.protheaShield == true
    end
    if not hasShield and exports['th_prothea'] and exports['th_prothea'].hasLocalShield then
        local ok, result = pcall(function()
            return exports['th_prothea']:hasLocalShield()
        end)
        hasShield = ok and result == true
    end
    return hasShield
end

--- Stop wand particles
local function StopWandFx(playerPed)
    local handle = wandParticles[playerPed]
    if handle then
        StopParticleFxLooped(handle, false)
        RemoveParticleFx(handle, false)
        allParticles[handle] = nil
        wandParticles[playerPed] = nil
    end
end

--- Create wand glow (water bubbles - INTENSE)
local function CreateWandGlow(playerPed)
    local weapon = GetCurrentPedWeaponEntityIndex and GetCurrentPedWeaponEntityIndex(playerPed)
    if not weapon or not DoesEntityExist(weapon) then return nil end

    local fx = Config.FX.wand
    RequestNamedPtfxAsset(fx.dict)
    while not HasNamedPtfxAssetLoaded(fx.dict) do Wait(0) end

    UseParticleFxAsset(fx.dict)
    local handle = StartParticleFxLoopedOnEntity(
        fx.particle, weapon,
        0.95, 0.0, 0.1, 0.0, 0.0, 0.0,
        fx.scale or 1.5, false, false, false
    )

    if handle then
        -- Couleur bleu eau intense
        SetParticleFxLoopedColour(handle, 0.1, 0.5, 1.0, false)
        wandParticles[playerPed] = handle
        allParticles[handle] = { createdTime = GetGameTimer(), type = 'wand' }
    end

    return handle
end

--- Create spectacular water explosion sequence
local function PlaySpectacularWaterExplosion(coords, casterPed)
    local seq = Config.EffectSequence
    local fx = Config.FX

    -- Preload assets
    RequestNamedPtfxAsset('core')
    while not HasNamedPtfxAssetLoaded('core') do Wait(0) end

    CreateThread(function()
        -- PHASE 1: Montée d'eau progressive (water building up)
        Wait(seq.waterRiseStart or 0)
        for i = 1, 3 do
            UseParticleFxAssetNextCall('core')
            StartNetworkedParticleFxNonLoopedAtCoord(
                fx.waterRise.particle,
                coords.x + math.random(-20, 20) / 100,
                coords.y + math.random(-20, 20) / 100,
                coords.z - 0.5,
                0.0, 0.0, 0.0,
                fx.waterRise.scale or 2.5,
                false, false, false
            )
            Wait(80)
        end
    end)

    -- PHASE 2: Geyser retiré (le jet n'était pas beau)

    CreateThread(function()
        -- PHASE 3: EXPLOSION MASSIVE
        Wait(seq.explosionStart or 500)

        -- Explosion centrale ÉNORME
        UseParticleFxAssetNextCall('core')
        StartNetworkedParticleFxNonLoopedAtCoord(
            fx.waterExplosion.particle,
            coords.x, coords.y, coords.z,
            0.0, 0.0, 0.0,
            fx.waterExplosion.scale or 5.0,
            false, false, false
        )

        -- Explosions secondaires en cercle
        for angle = 0, 360, 60 do
            local rad = math.rad(angle)
            local offsetX = math.cos(rad) * 1.5
            local offsetY = math.sin(rad) * 1.5

            UseParticleFxAssetNextCall('core')
            StartNetworkedParticleFxNonLoopedAtCoord(
                fx.waterExplosion.particle,
                coords.x + offsetX,
                coords.y + offsetY,
                coords.z - 0.2,
                0.0, 0.0, 0.0,
                3.0,
                false, false, false
            )
        end

        -- Son explosion d'eau principal
        PlaySoundFromCoord(-1, "BASE_JUMP_SPLASH", "HUD_MINIGAME_SOUNDSET", coords.x, coords.y, coords.z, false, 0, false)
    end)

    CreateThread(function()
        -- PHASE 4: Vagues qui se propagent
        Wait(seq.wavesStart or 520)
        for ring = 1, 3 do
            for angle = 0, 360, 45 do
                local rad = math.rad(angle)
                local radius = ring * 2.0
                local offsetX = math.cos(rad) * radius
                local offsetY = math.sin(rad) * radius

                UseParticleFxAssetNextCall('core')
                StartNetworkedParticleFxNonLoopedAtCoord(
                    fx.waves.particle,
                    coords.x + offsetX,
                    coords.y + offsetY,
                    coords.z - 0.1,
                    0.0, 0.0, angle,
                    fx.waves.scale or 3.5,
                    false, false, false
                )
            end
            Wait(100)
        end
    end)

    CreateThread(function()
        -- PHASE 5: Éclaboussures massives
        Wait(seq.splashStart or 540)
        for i = 1, 8 do
            local angle = math.random(0, 360)
            local rad = math.rad(angle)
            local dist = math.random(10, 30) / 10

            UseParticleFxAssetNextCall('core')
            StartNetworkedParticleFxNonLoopedAtCoord(
                fx.splash.particle,
                coords.x + math.cos(rad) * dist,
                coords.y + math.sin(rad) * dist,
                coords.z + math.random(0, 15) / 10,
                0.0, 0.0, 0.0,
                fx.splash.scale or 3.0,
                false, false, false
            )
        end
    end)

    CreateThread(function()
        -- PHASE 6: Brouillard d'eau persistant
        Wait(seq.mistStart or 600)
        for i = 1, 5 do
            UseParticleFxAssetNextCall('core')
            StartNetworkedParticleFxNonLoopedAtCoord(
                fx.mist.particle,
                coords.x + math.random(-100, 100) / 100,
                coords.y + math.random(-100, 100) / 100,
                coords.z + 0.5,
                0.0, 0.0, 0.0,
                fx.mist.scale or 3.0,
                false, false, false
            )
            Wait(100)
        end
    end)

    -- PHASE 7: Plus d'effets qui suivent - juste la lévitation propre
    -- (Effets retirés car le jet n'était pas beau)
end

--- Apply camera shake (plus intense!)
local function ApplyCameraShake(coords)
    if HasProtheaShield() then return end

    local myCoords = GetEntityCoords(cache.ped)
    local dist = #(myCoords - coords)
    local maxDist = Config.Propulsion.shakeDistance or 25.0

    if dist < maxDist then
        local factor = 1.0 - (dist / maxDist)
        local intensity = (Config.Propulsion.shakeIntensity or 0.5) * factor
        ShakeGameplayCam('LARGE_EXPLOSION_SHAKE', intensity)
    end
end

--- Apply self levitation (gentle lift and hover slightly above ground)
RegisterNetEvent('th_propulsia:applySelfPropulsion', function()
    if HasProtheaShield() then return end

    local ped = cache.ped
    local liftForce = Config.Propulsion.selfLiftForce or 3.0
    local hoverDuration = Config.Propulsion.selfHoverDuration or 5000
    local hoverInterval = Config.Propulsion.hoverForceInterval or 50
    local hoverForce = Config.Propulsion.hoverForce or 2.5

    -- Levitation douce initiale (juste se soulever légèrement)
    Wait(50)
    ApplyForceToEntity(ped, 1, 0.0, 0.0, liftForce, 0.0, 0.0, 0.0, 0, false, true, true, false, true)

    -- Maintenir en lévitation légère pendant 5 secondes
    CreateThread(function()
        local startTime = GetGameTimer()
        local endTime = startTime + hoverDuration

        while GetGameTimer() < endTime do
            if DoesEntityExist(ped) then
                local pedCoords = GetEntityCoords(ped)
                local groundZ = GetGroundZFor_3dCoord(pedCoords.x, pedCoords.y, pedCoords.z, false)

                -- Si on est proche du sol, on applique une petite force pour rester au-dessus
                if pedCoords.z - groundZ < 0.6 then
                    ApplyForceToEntity(ped, 1, 0.0, 0.0, hoverForce, 0.0, 0.0, 0.0, 0, false, true, true, false, true)
                end
            else
                break
            end
            Wait(hoverInterval)
        end
    end)
end)

--- Apply knockback to nearby players
RegisterNetEvent('th_propulsia:applyKnockback', function(explosionCoords)
    if HasProtheaShield() then return end

    local ped = cache.ped
    local pedCoords = GetEntityCoords(ped)
    local radius = Config.Propulsion.knockbackRadius or 8.0

    local dist = #(pedCoords - explosionCoords)
    if dist > radius then return end

    -- Calculate direction away from explosion
    local dir = pedCoords - explosionCoords
    local dirLength = #dir
    if dirLength > 0.01 then
        dir = dir / dirLength
    else
        dir = vector3(0.0, 0.0, 1.0)
    end

    -- Apply ragdoll
    local ragdollTime = Config.Propulsion.ragdollTime or 3000
    SetPedToRagdoll(ped, ragdollTime, ragdollTime, 0, false, false, false)

    -- Apply knockback force
    local forceUp = Config.Propulsion.knockbackForceUp or 18.0
    local forceHorizontal = Config.Propulsion.knockbackForceHorizontal or 15.0

    Wait(50)
    ApplyForceToEntity(ped, 1, 0.0, 0.0, forceUp, 0.0, 0.0, 0.0, 0, false, true, true, false, true)
    ApplyForceToEntity(ped, 1, dir.x * forceHorizontal, dir.y * forceHorizontal, forceUp * 0.4, 0.0, 0.0, 0.0, 0, false, true, true, false, true)
end)

--- Broadcast spectacular water explosion to all clients
RegisterNetEvent('th_propulsia:playExplosionFx', function(coords, casterServerId)
    -- Trouver le ped du lanceur pour les effets qui le suivent
    local casterPed = nil
    if casterServerId then
        if casterServerId == GetPlayerServerId(PlayerId()) then
            casterPed = cache.ped
        else
            local casterPlayer = GetPlayerFromServerId(casterServerId)
            if casterPlayer ~= -1 then
                casterPed = GetPlayerPed(casterPlayer)
            end
        end
    end

    PlaySpectacularWaterExplosion(coords, casterPed)
    ApplyCameraShake(coords)
end)

--- Event: Prepare and cast
RegisterNetEvent('th_propulsia:prepareCast', function()
    local casterPed = cache.ped

    CreateWandGlow(casterPed)

    CreateThread(function()
        local castDelay = Config.Animation.castDelay or 600
        Wait(castDelay)

        -- Get position below the caster for water explosion
        local casterCoords = GetEntityCoords(casterPed)
        local explosionCoords = vector3(casterCoords.x, casterCoords.y, casterCoords.z - 0.2)

        -- Notify server to trigger explosion
        TriggerServerEvent('th_propulsia:trigger', explosionCoords)

        -- Stop wand glow
        Wait(200)
        StopWandFx(casterPed)
    end)
end)

--- Event: Other player casting
RegisterNetEvent('th_propulsia:otherPlayerCasting', function(sourceServerId)
    local myServerId = GetPlayerServerId(PlayerId())
    if sourceServerId == myServerId then return end

    local casterPlayer = GetPlayerFromServerId(sourceServerId)
    if casterPlayer == -1 then return end

    local casterPed = GetPlayerPed(casterPlayer)
    if not DoesEntityExist(casterPed) then return end

    CreateWandGlow(casterPed)
    SetTimeout(1200, function()
        StopWandFx(casterPed)
    end)
end)

--- Cleanup on stop
AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end

    for ped, handle in pairs(wandParticles) do
        StopParticleFxLooped(handle, false)
        RemoveParticleFx(handle, false)
    end
    wandParticles = {}
    allParticles = {}

    for ped, effects in pairs(activePlayerEffects) do
        for _, handle in ipairs(effects) do
            StopParticleFxLooped(handle, false)
            RemoveParticleFx(handle, false)
        end
    end
    activePlayerEffects = {}
end)
