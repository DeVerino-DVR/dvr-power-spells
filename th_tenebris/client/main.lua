---@diagnostic disable: undefined-global, trailing-space, unused-local, param-type-mismatch, missing-parameter
local projectileProps = {}
local wandParticles = {}
local allParticles = {}

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
local GetGameplayCamCoord = GetGameplayCamCoord
local GetGameplayCamRot = GetGameplayCamRot
local GetPedBoneIndex = GetPedBoneIndex
local GetWorldPositionOfEntityBone = GetWorldPositionOfEntityBone
local GetEntityCoords = GetEntityCoords
local GetPlayerFromServerId = GetPlayerFromServerId
local GetPlayerPed = GetPlayerPed
local GetPlayerServerId = GetPlayerServerId
local PlayerId = PlayerId
local DoesEntityExist = DoesEntityExist
local GetHashKey = GetHashKey
local SetPedToRagdoll = SetPedToRagdoll
local ApplyForceToEntity = ApplyForceToEntity
local GetGameTimer = GetGameTimer
local CreateObject = CreateObject
local DeleteObject = DeleteObject
local SetEntityCoords = SetEntityCoords
local SetEntityRotation = SetEntityRotation
local SetEntityCollision = SetEntityCollision
local SetEntityAsMissionEntity = SetEntityAsMissionEntity
local SetEntityCompletelyDisableCollision = SetEntityCompletelyDisableCollision
local AddExplosion = AddExplosion
local PlaySoundFromCoord = PlaySoundFromCoord
local ShakeGameplayCam = ShakeGameplayCam
local DrawLightWithRange = DrawLightWithRange
local StartParticleFxLoopedAtCoord = StartParticleFxLoopedAtCoord

--- Pulse light effect (violet/noir)
local function PulseLight(coords, color, radius, intensity, duration)
    if not coords then return end

    local start = GetGameTimer()
    local total = duration or 800
    local range = radius or 10.0
    local power = intensity or 20.0
    local clr = color or Config.Lights.impact

    CreateThread(function()
        while true do
            local elapsed = GetGameTimer() - start
            if elapsed >= total then
                break
            end

            local fade = 1.0 - (elapsed / total)
            DrawLightWithRange(
                coords.x, coords.y, coords.z,
                clr.r, clr.g, clr.b,
                range,
                power * fade
            )
            Wait(0)
        end
    end)
end

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

--- Convert rotation to direction
local function RotationToDirection(rotation)
    local pitch = math.rad(rotation.x)
    local yaw = math.rad(rotation.z)
    return vector3(
        -math.sin(yaw) * math.cos(pitch),
        math.cos(yaw) * math.cos(pitch),
        math.sin(pitch)
    )
end

--- Stop wand particles
local function StopWandParticles(playerPed)
    local handles = wandParticles[playerPed]
    if handles then
        if type(handles) == "table" then
            -- Si c'est une table de handles
            for _, handle in ipairs(handles) do
                if handle then
                    StopParticleFxLooped(handle, false)
                    RemoveParticleFx(handle, false)
                end
            end
        else
            -- Si c'est un seul handle
            StopParticleFxLooped(handles, false)
            RemoveParticleFx(handles, false)
        end
        wandParticles[playerPed] = nil
    end
end

--- Create DARK charging aura (lanceur charge le sort)
local function CreateDarkChargingAura(playerPed)
    local seq = Config.EffectSequence
    local fx = Config.FX

    -- Précharger les assets
    RequestNamedPtfxAsset('scr_rcbarry1')
    RequestNamedPtfxAsset('core')
    RequestNamedPtfxAsset('scr_reconstructionaccident')

    CreateThread(function()
        while not HasNamedPtfxAssetLoaded('scr_rcbarry1') or
              not HasNamedPtfxAssetLoaded('core') or
              not HasNamedPtfxAssetLoaded('scr_reconstructionaccident') do
            Wait(0)
        end

        local particleHandles = {}

        -- Aura sombre autour du lanceur
        Wait(seq.auraStart or 0)
        UseParticleFxAsset(fx.casterAura.dict)
        local auraHandle = StartParticleFxLoopedOnEntity(
            fx.casterAura.particle, playerPed,
            0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
            fx.casterAura.scale or 2.0,
            false, false, false
        )
        if auraHandle then
            SetParticleFxLoopedColour(auraHandle, 0.3, 0.0, 0.5, false)
            table.insert(particleHandles, auraHandle)
        end

        -- Ténèbres qui montent
        Wait(seq.darknessStart or 100)
        for i = 1, 3 do
            UseParticleFxAssetNextCall(fx.casterDarkness.dict)
            StartParticleFxNonLoopedAtCoord(
                fx.casterDarkness.particle,
                GetEntityCoords(playerPed).x,
                GetEntityCoords(playerPed).y,
                GetEntityCoords(playerPed).z - 0.5,
                0.0, 0.0, 0.0,
                fx.casterDarkness.scale or 1.5,
                false, false, false
            )
            Wait(150)
        end

        -- Pouvoir de la baguette
        Wait(seq.wandPowerStart or 300)
        local weapon = GetCurrentPedWeaponEntityIndex and GetCurrentPedWeaponEntityIndex(playerPed)
        if weapon and DoesEntityExist(weapon) then
            UseParticleFxAsset(fx.wandPower.dict)
            local wandHandle = StartParticleFxLoopedOnEntity(
                fx.wandPower.particle, weapon,
                0.95, 0.0, 0.1, 0.0, 0.0, 0.0,
                fx.wandPower.scale or 1.2,
                false, false, false
            )
            if wandHandle then
                SetParticleFxLoopedColour(wandHandle, 0.5, 0.0, 0.8, false)
                table.insert(particleHandles, wandHandle)
            end
        end

        -- Stocker tous les handles pour cleanup
        wandParticles[playerPed] = particleHandles
    end)
end

--- Get real impact point via raycast
local function GetImpactPoint()
    local camPos = GetGameplayCamCoord()
    local camRot = GetGameplayCamRot(2)
    local dir = RotationToDirection(camRot)

    local maxDistance = Config.Projectile.maxDistance or 150.0
    local endPos = camPos + dir * maxDistance

    local rayHandle = StartShapeTestRay(camPos.x, camPos.y, camPos.z, endPos.x, endPos.y, endPos.z, -1, cache.ped, 0)
    local _, hit, hitCoords, _, _ = GetShapeTestResult(rayHandle)

    if hit then
        return hitCoords
    else
        return endPos
    end
end

--- Attach dark projectile trail
local function AttachDarkProjectileTrail(prop)
    if not prop or not DoesEntityExist(prop) then return end

    RequestNamedPtfxAsset('scr_rcbarry1')
    RequestNamedPtfxAsset('core')
    while not HasNamedPtfxAssetLoaded('scr_rcbarry1') or not HasNamedPtfxAssetLoaded('core') do
        Wait(0)
    end

    local fx = Config.FX
    local handles = {}

    -- Cœur de l'orbe (violet intense)
    UseParticleFxAsset(fx.orbCore.dict)
    local coreHandle = StartParticleFxLoopedOnEntity(
        fx.orbCore.particle, prop,
        0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
        fx.orbCore.scale or 2.0,
        false, false, false
    )
    if coreHandle then
        SetParticleFxLoopedColour(coreHandle, 0.5, 0.0, 0.8, false)
        table.insert(handles, coreHandle)
    end

    -- Trail de ténèbres
    UseParticleFxAsset(fx.orbTrail.dict)
    local trailHandle = StartParticleFxLoopedOnEntity(
        fx.orbTrail.particle, prop,
        0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
        fx.orbTrail.scale or 1.5,
        false, false, false
    )
    if trailHandle then
        SetParticleFxLoopedColour(trailHandle, 0.2, 0.0, 0.4, false)
        table.insert(handles, trailHandle)
    end

    -- Fumée noire
    UseParticleFxAsset(fx.orbSmoke.dict)
    local smokeHandle = StartParticleFxLoopedOnEntity(
        fx.orbSmoke.particle, prop,
        0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
        fx.orbSmoke.scale or 1.2,
        false, false, false
    )
    if smokeHandle then
        table.insert(handles, smokeHandle)
    end

    return handles
end

--- Create APOCALYPTIC impact explosion (VERSION MASSIVE!)
local function CreateApocalypticExplosion(coords)
    local seq = Config.EffectSequence
    local fx = Config.FX

    -- Précharger TOUS les assets
    RequestNamedPtfxAsset('scr_rcbarry1')
    RequestNamedPtfxAsset('core')
    RequestNamedPtfxAsset('scr_reconstructionaccident')
    RequestNamedPtfxAsset('scr_agencyheistb')
    RequestNamedPtfxAsset('scr_xm_orbital')
    RequestNamedPtfxAsset('des_vaultdoor')

    CreateThread(function()
        while not HasNamedPtfxAssetLoaded('scr_rcbarry1') or
              not HasNamedPtfxAssetLoaded('core') or
              not HasNamedPtfxAssetLoaded('scr_reconstructionaccident') or
              not HasNamedPtfxAssetLoaded('scr_agencyheistb') or
              not HasNamedPtfxAssetLoaded('scr_xm_orbital') or
              not HasNamedPtfxAssetLoaded('des_vaultdoor') do
            Wait(0)
        end

        -- ========== PHASE 0: IMPLOSION DE TÉNÈBRES ==========
        -- Implosion qui aspire l'énergie
        for i = 1, 3 do
            UseParticleFxAssetNextCall(fx.darkImplosion.dict)
            StartNetworkedParticleFxNonLoopedAtCoord(
                fx.darkImplosion.particle,
                coords.x, coords.y, coords.z,
                0.0, 0.0, math.random(0, 360),
                fx.darkImplosion.scale or 10.0,
                false, false, false
            )
            Wait(40)
        end

        -- Énergie noire qui tourbillonne
        for angle = 0, 360, 60 do
            local rad = math.rad(angle)
            local dist = 2.0

            UseParticleFxAssetNextCall(fx.darkEnergy.dict)
            StartNetworkedParticleFxNonLoopedAtCoord(
                fx.darkEnergy.particle,
                coords.x + math.cos(rad) * dist,
                coords.y + math.sin(rad) * dist,
                coords.z,
                0.0, 0.0, 0.0,
                fx.darkEnergy.scale or 8.0,
                false, false, false
            )
        end

        -- ========== PHASE 1: EXPLOSION NUCLÉAIRE CENTRALE ==========
        Wait(50)
        for i = 1, 3 do
            UseParticleFxAssetNextCall(fx.nuclearBlast.dict)
            StartNetworkedParticleFxNonLoopedAtCoord(
                fx.nuclearBlast.particle,
                coords.x, coords.y, coords.z,
                0.0, 0.0, math.random(0, 360),
                fx.nuclearBlast.scale or 10.0,
                false, false, false
            )
            Wait(80)
        end

        -- ========== PHASE 2: ONDES DE CHOC MULTIPLES ==========
        CreateThread(function()
            Wait(seq.shockwaveStart or 0)
            for ring = 1, 5 do
                -- Onde de choc qui s'étend
                for angle = 0, 360, 30 do
                    local rad = math.rad(angle)
                    local dist = ring * 3.0

                    UseParticleFxAssetNextCall(fx.shockwave.dict)
                    StartNetworkedParticleFxNonLoopedAtCoord(
                        fx.shockwave.particle,
                        coords.x + math.cos(rad) * dist,
                        coords.y + math.sin(rad) * dist,
                        coords.z,
                        0.0, 0.0, angle,
                        fx.shockwave.scale or 12.0,
                        false, false, false
                    )
                end
                Wait(120)
            end
        end)

        -- ========== PHASE 3: EXPLOSIONS PRINCIPALES MASSIVES ==========
        Wait(seq.mainExplosionStart or 50)
        -- Explosion centrale GIGANTESQUE
        for i = 1, 5 do
            UseParticleFxAssetNextCall(fx.mainExplosion.dict)
            StartNetworkedParticleFxNonLoopedAtCoord(
                fx.mainExplosion.particle,
                coords.x, coords.y, coords.z + (i * 0.5),
                0.0, 0.0, math.random(0, 360),
                fx.mainExplosion.scale or 10.0,
                false, false, false
            )
            Wait(60)
        end

        -- Explosions secondaires en cercles concentriques
        for ring = 1, 3 do
            for angle = 0, 360, 40 do
                local rad = math.rad(angle)
                local dist = ring * 2.5

                UseParticleFxAssetNextCall(fx.secondaryExplosion.dict)
                StartNetworkedParticleFxNonLoopedAtCoord(
                    fx.secondaryExplosion.particle,
                    coords.x + math.cos(rad) * dist,
                    coords.y + math.sin(rad) * dist,
                    coords.z,
                    0.0, 0.0, 0.0,
                    fx.secondaryExplosion.scale or 6.0,
                    false, false, false
                )
            end
            Wait(100)
        end

        -- ========== PHASE 4: ANNEAU DE FEU INFERNAL ==========
        CreateThread(function()
            Wait(seq.darkFireStart or 100)
            -- Anneau de feu qui s'étend
            for ring = 1, 4 do
                for angle = 0, 360, 20 do
                    local rad = math.rad(angle)
                    local dist = ring * 2.0

                    UseParticleFxAssetNextCall(fx.infernoRing.dict)
                    StartNetworkedParticleFxNonLoopedAtCoord(
                        fx.infernoRing.particle,
                        coords.x + math.cos(rad) * dist,
                        coords.y + math.sin(rad) * dist,
                        coords.z,
                        0.0, 0.0, 0.0,
                        fx.infernoRing.scale or 8.0,
                        false, false, false
                    )
                end
                Wait(90)
            end

            -- Flammes noires massives
            for i = 1, 20 do
                local angle = math.random(0, 360)
                local rad = math.rad(angle)
                local dist = math.random(10, 60) / 10

                UseParticleFxAssetNextCall(fx.darkFire1.dict)
                StartNetworkedParticleFxNonLoopedAtCoord(
                    fx.darkFire1.particle,
                    coords.x + math.cos(rad) * dist,
                    coords.y + math.sin(rad) * dist,
                    coords.z,
                    0.0, 0.0, 0.0,
                    fx.darkFire1.scale or 6.0,
                    false, false, false
                )

                Wait(40)
            end
        end)

        -- ========== PHASE 5: TEMPÊTE ÉLECTRIQUE ==========
        CreateThread(function()
            Wait(seq.lightningStart or 150)
            -- Éclairs continus
            for wave = 1, 3 do
                for i = 1, 15 do
                    local angle = math.random(0, 360)
                    local rad = math.rad(angle)
                    local dist = math.random(10, 70) / 10

                    -- Éclairs violets
                    UseParticleFxAssetNextCall(fx.lightning1.dict)
                    StartNetworkedParticleFxNonLoopedAtCoord(
                        fx.lightning1.particle,
                        coords.x + math.cos(rad) * dist,
                        coords.y + math.sin(rad) * dist,
                        coords.z + math.random(0, 40) / 10,
                        0.0, 0.0, 0.0,
                        fx.lightning1.scale or 5.0,
                        false, false, false
                    )

                    -- Tempête électrique
                    UseParticleFxAssetNextCall(fx.electricStorm.dict)
                    StartNetworkedParticleFxNonLoopedAtCoord(
                        fx.electricStorm.particle,
                        coords.x + math.cos(rad) * (dist * 0.8),
                        coords.y + math.sin(rad) * (dist * 0.8),
                        coords.z + math.random(0, 30) / 10,
                        0.0, 0.0, 0.0,
                        fx.electricStorm.scale or 6.0,
                        false, false, false
                    )
                end
                Wait(120)
            end
        end)

        -- ========== PHASE 6: NUAGE DE POUSSIÈRE MASSIF ==========
        Wait(seq.debrisStart or 200)
        for i = 1, 25 do
            local angle = math.random(0, 360)
            local rad = math.rad(angle)
            local dist = math.random(5, 50) / 10

            -- Débris
            UseParticleFxAssetNextCall(fx.debris.dict)
            StartNetworkedParticleFxNonLoopedAtCoord(
                fx.debris.particle,
                coords.x + math.cos(rad) * dist,
                coords.y + math.sin(rad) * dist,
                coords.z,
                0.0, 0.0, 0.0,
                fx.debris.scale or 4.0,
                false, false, false
            )

            -- Nuage de poussière
            UseParticleFxAssetNextCall(fx.dustCloud.dict)
            StartNetworkedParticleFxNonLoopedAtCoord(
                fx.dustCloud.particle,
                coords.x + math.cos(rad) * dist,
                coords.y + math.sin(rad) * dist,
                coords.z + 0.5,
                0.0, 0.0, 0.0,
                fx.dustCloud.scale or 8.0,
                false, false, false
            )
        end

        -- ========== PHASE 7: FUMÉE TOXIQUE PERSISTANTE (10 sec) ==========
        Wait(seq.persistentSmokeStart or 300)
        CreateThread(function()
            local endTime = GetGameTimer() + (seq.persistentSmokeDuration or 10000)
            while GetGameTimer() < endTime do
                for i = 1, 4 do
                    local angle = math.random(0, 360)
                    local rad = math.rad(angle)
                    local dist = math.random(0, 40) / 10

                    -- Fumée noire massive
                    UseParticleFxAssetNextCall(fx.persistentSmoke.dict)
                    StartNetworkedParticleFxNonLoopedAtCoord(
                        fx.persistentSmoke.particle,
                        coords.x + math.cos(rad) * dist,
                        coords.y + math.sin(rad) * dist,
                        coords.z + math.random(0, 20) / 10,
                        0.0, 0.0, 0.0,
                        fx.persistentSmoke.scale or 8.0,
                        false, false, false
                    )

                    -- Nuage toxique
                    UseParticleFxAssetNextCall(fx.toxicCloud.dict)
                    StartNetworkedParticleFxNonLoopedAtCoord(
                        fx.toxicCloud.particle,
                        coords.x + math.cos(rad) * dist,
                        coords.y + math.sin(rad) * dist,
                        coords.z + 0.3,
                        0.0, 0.0, 0.0,
                        fx.toxicCloud.scale or 7.0,
                        false, false, false
                    )
                end
                Wait(600)
            end
        end)

        -- ========== PHASE 8: VORTEX RÉSIDUEL (8 sec) ==========
        Wait(seq.residualAuraStart or 500)
        CreateThread(function()
            local endTime = GetGameTimer() + (seq.residualAuraDuration or 8000)
            while GetGameTimer() < endTime do
                -- Aura centrale
                UseParticleFxAssetNextCall(fx.residualAura.dict)
                StartNetworkedParticleFxNonLoopedAtCoord(
                    fx.residualAura.particle,
                    coords.x, coords.y, coords.z,
                    0.0, 0.0, 0.0,
                    fx.residualAura.scale or 6.0,
                    false, false, false
                )

                -- Vortex de ténèbres
                UseParticleFxAssetNextCall(fx.vortex.dict)
                StartNetworkedParticleFxNonLoopedAtCoord(
                    fx.vortex.particle,
                    coords.x, coords.y, coords.z + 0.5,
                    0.0, 0.0, 0.0,
                    fx.vortex.scale or 5.0,
                    false, false, false
                )

                Wait(1200)
            end
        end)

        -- ========== LUMIÈRE D'IMPACT MASSIVE ==========
        PulseLight(coords, Config.Lights.impact, Config.Lights.impact.radius, Config.Lights.impact.intensity, Config.Lights.impact.duration)

        -- ========== SONS APOCALYPTIQUES ==========
        PlaySoundFromCoord(-1, "DLC_XM_Explosions_Sounds", "Explosion_Alien", coords.x, coords.y, coords.z, false, 0, false)
        Wait(100)
        PlaySoundFromCoord(-1, "Explosion", "CARMOD_SOUNDS", coords.x, coords.y, coords.z, false, 0, false)
        Wait(150)
        PlaySoundFromCoord(-1, "DLC_XM_Explosions_Sounds", "Explosion_Alien", coords.x, coords.y, coords.z, false, 0, false)

        -- ========== FLAMMES NOIRES MODÉES (ns_ptfx!) ==========
        CreateThread(function()
            local darkFire = Config.FX.darkFireMod
            local effects = {}

            -- Précharger l'asset modé
            RequestNamedPtfxAsset(darkFire.asset)
            while not HasNamedPtfxAssetLoaded(darkFire.asset) do
                Wait(0)
            end

            -- Créer un anneau de flammes NOIRES modées
            for angle = 0, 360, (360 / darkFire.count) do
                local rad = math.rad(angle)
                local offsetX = math.cos(rad) * darkFire.radius
                local offsetY = math.sin(rad) * darkFire.radius

                UseParticleFxAssetNextCall(darkFire.asset)
                local fx = StartParticleFxLoopedAtCoord(
                    darkFire.name,
                    coords.x + offsetX,
                    coords.y + offsetY,
                    coords.z + 0.3,
                    0.0, 0.0, 0.0,
                    darkFire.scale,
                    false, false, false, false
                )
                -- Couleur NOIRE/VIOLETTE pour les flammes
                SetParticleFxLoopedColour(fx, 0.3, 0.0, 0.5, 1.0)
                table.insert(effects, fx)
            end

            -- Flammes au centre
            for i = 1, 3 do
                UseParticleFxAssetNextCall(darkFire.asset)
                local fx = StartParticleFxLoopedAtCoord(
                    darkFire.name,
                    coords.x,
                    coords.y,
                    coords.z + (i * 0.5),
                    0.0, 0.0, 0.0,
                    darkFire.scale * 1.2,
                    false, false, false, false
                )
                SetParticleFxLoopedColour(fx, 0.2, 0.0, 0.4, 1.0)
                table.insert(effects, fx)
            end

            -- Arrêter après la durée
            SetTimeout(darkFire.duration, function()
                for _, fx in ipairs(effects) do
                    StopParticleFxLooped(fx, 0)
                    RemoveParticleFx(fx, false)
                end
                RemoveNamedPtfxAsset(darkFire.asset)
            end)
        end)

        -- ========== EXPLOSIONS PHYSIQUES MASSIVES (AVEC SONS!) ==========
        -- Explosion centrale GIGANTESQUE avec son
        AddExplosion(coords.x, coords.y, coords.z, 59, 100.0, true, false, 8.0, false)

        Wait(80)
        -- Deuxième vague d'explosions en cercle
        for angle = 0, 360, 90 do
            local rad = math.rad(angle)
            local dist = 3.0
            AddExplosion(coords.x + math.cos(rad) * dist, coords.y + math.sin(rad) * dist, coords.z, 4, 50.0, true, false, 5.0, false)
        end

        Wait(100)
        -- Explosion sous-marine (son grave)
        AddExplosion(coords.x, coords.y, coords.z, 13, 80.0, true, false, 6.0, false)

        Wait(80)
        -- Explosions en hauteur
        AddExplosion(coords.x, coords.y, coords.z + 2.0, 59, 60.0, true, false, 4.0, false)
        AddExplosion(coords.x, coords.y, coords.z + 4.0, 59, 40.0, true, false, 3.0, false)

        Wait(100)
        -- Troisième vague - explosions massives aléatoires
        for i = 1, 6 do
            local angle = math.random(0, 360)
            local rad = math.rad(angle)
            local dist = math.random(15, 40) / 10
            AddExplosion(
                coords.x + math.cos(rad) * dist,
                coords.y + math.sin(rad) * dist,
                coords.z + math.random(0, 20) / 10,
                7,  -- Explosion type 7 (gros son)
                40.0,
                true,  -- AUDIBLE!
                false, -- VISIBLE!
                3.0,
                false
            )
            Wait(60)
        end

        Wait(120)
        -- Explosions finales massives
        AddExplosion(coords.x, coords.y, coords.z, 32, 70.0, true, false, 6.0, false)  -- Type 32 (très bruyant)
        Wait(100)
        AddExplosion(coords.x, coords.y, coords.z + 1.0, 59, 50.0, true, false, 5.0, false)

        Wait(80)
        -- Dernière explosion GÉANTE
        AddExplosion(coords.x, coords.y, coords.z, 59, 120.0, true, false, 10.0, false)
    end)
end

--- Create Tenebris projectile
local function CreateTenebrisProjectile(startCoords, targetCoords, sourceServerId, casterPed, spellLevel)
    local propModel = GetHashKey("prop_alien_egg_01")
    lib.requestModel(propModel, 5000)

    local prop = CreateObject(propModel, startCoords.x, startCoords.y, startCoords.z, false, false, false)
    SetEntityCollision(prop, false, false)
    SetEntityAsMissionEntity(prop, true, true)
    SetEntityCompletelyDisableCollision(prop, true, false)

    local direction = vector3(
        targetCoords.x - startCoords.x,
        targetCoords.y - startCoords.y,
        targetCoords.z - startCoords.z
    )
    local distance = #direction
    direction = direction / distance

    local heading = math.deg(math.atan2(direction.y, direction.x)) + 90.0
    local pitch = -math.deg(math.asin(direction.z))

    SetEntityCoords(prop, startCoords.x, startCoords.y, startCoords.z, false, false, false, false)
    SetEntityRotation(prop, pitch, 0.0, heading, 2, true)

    if casterPed and DoesEntityExist(casterPed) then
        StopWandParticles(casterPed)
    end

    local trailHandles = AttachDarkProjectileTrail(prop)

    local speed = Config.Projectile.speed or 60.0
    local duration = (distance / speed) * 1000.0
    local startTime = GetGameTimer()
    local endTime = startTime + duration

    projectileProps[prop] = {
        prop = prop,
        startCoords = startCoords,
        targetCoords = targetCoords,
        direction = direction,
        distance = distance,
        startTime = startTime,
        endTime = endTime,
        sourceServerId = sourceServerId,
        trailHandles = trailHandles,
        spellLevel = spellLevel or 1
    }
end

--- Projectile movement thread
CreateThread(function()
    while true do
        local currentTime = GetGameTimer()
        local projectilesToRemove = {}

        for prop, data in pairs(projectileProps) do
            if DoesEntityExist(prop) then
                local progress = math.min((currentTime - data.startTime) / (data.endTime - data.startTime), 1.0)

                if progress >= 1.0 then
                    -- IMPACT APOCALYPTIQUE!
                    local impactCoords = data.targetCoords

                    TriggerServerEvent('th_tenebris:onImpact', impactCoords, data.spellLevel)

                    -- Cleanup trails
                    if data.trailHandles then
                        for _, handle in ipairs(data.trailHandles) do
                            StopParticleFxLooped(handle, false)
                            RemoveParticleFx(handle, false)
                        end
                    end

                    DeleteObject(prop)
                    table.insert(projectilesToRemove, prop)
                else
                    -- Move projectile
                    local currentPos = vector3(
                        data.startCoords.x + data.direction.x * data.distance * progress,
                        data.startCoords.y + data.direction.y * data.distance * progress,
                        data.startCoords.z + data.direction.z * data.distance * progress
                    )

                    SetEntityCoords(prop, currentPos.x, currentPos.y, currentPos.z, false, false, false, false)

                    -- Lumière violette qui suit le projectile
                    local trail = Config.Lights.trail
                    DrawLightWithRange(
                        currentPos.x, currentPos.y, currentPos.z,
                        trail.r, trail.g, trail.b,
                        trail.radius,
                        trail.intensity
                    )
                end
            else
                table.insert(projectilesToRemove, prop)
            end
        end

        for _, prop in ipairs(projectilesToRemove) do
            projectileProps[prop] = nil
        end

        Wait(0)
    end
end)

--- Play impact effects for all clients
RegisterNetEvent('th_tenebris:playImpactFx', function(impactCoords)
    CreateApocalypticExplosion(impactCoords)

    -- Camera shake INTENSE
    if not HasProtheaShield() then
        local myCoords = GetEntityCoords(cache.ped)
        local dist = #(myCoords - impactCoords)
        local maxDist = Config.Impact.shakeDistance or 50.0

        if dist < maxDist then
            local factor = 1.0 - (dist / maxDist)
            local intensity = (Config.Impact.shakeIntensity or 1.2) * factor
            ShakeGameplayCam('LARGE_EXPLOSION_SHAKE', intensity)
        end
    end
end)

--- Create projectile for all clients
RegisterNetEvent('th_tenebris:createProjectile', function(startCoords, targetCoords, sourceServerId, spellLevel)
    local casterPed = nil
    if sourceServerId == GetPlayerServerId(PlayerId()) then
        casterPed = cache.ped
    else
        local casterPlayer = GetPlayerFromServerId(sourceServerId)
        if casterPlayer ~= -1 then
            casterPed = GetPlayerPed(casterPlayer)
        end
    end

    CreateTenebrisProjectile(startCoords, targetCoords, sourceServerId, casterPed, spellLevel)
end)

--- Apply knockback
RegisterNetEvent('th_tenebris:applyKnockback', function(impactCoords, level, forceUp, forceHorizontal, ragdollTime)
    if HasProtheaShield() then return end

    local ped = cache.ped
    local pedCoords = GetEntityCoords(ped)
    local radius = Config.Impact.knockbackRadius or 15.0

    local dist = #(pedCoords - impactCoords)
    if dist > radius then return end

    local dir = pedCoords - impactCoords
    local dirLength = #dir
    if dirLength > 0.01 then
        dir = dir / dirLength
    else
        dir = vector3(0.0, 0.0, 1.0)
    end

    SetPedToRagdoll(ped, ragdollTime, ragdollTime, 0, false, false, false)

    Wait(50)
    ApplyForceToEntity(ped, 1, 0.0, 0.0, forceUp, 0.0, 0.0, 0.0, 0, false, true, true, false, true)
    ApplyForceToEntity(ped, 1, dir.x * forceHorizontal, dir.y * forceHorizontal, forceUp * 0.5, 0.0, 0.0, 0.0, 0, false, true, true, false, true)
end)

--- Prepare and cast
RegisterNetEvent('th_tenebris:prepareCast', function(spellLevel)
    local casterPed = cache.ped

    CreateDarkChargingAura(casterPed)

    CreateThread(function()
        local castDelay = Config.Animation.castDelay or 800
        Wait(castDelay)

        local impactCoords = GetImpactPoint()

        TriggerServerEvent('th_tenebris:prepareImpact', impactCoords, spellLevel)

        Wait(50)

        local handBone = GetPedBoneIndex(casterPed, 28422)
        local startPos = GetWorldPositionOfEntityBone(casterPed, handBone)

        TriggerServerEvent('th_tenebris:createProjectile', startPos, impactCoords, spellLevel)

        Wait(300)
        StopWandParticles(casterPed)
    end)
end)

--- Other player casting
RegisterNetEvent('th_tenebris:otherPlayerCasting', function(sourceServerId)
    local myServerId = GetPlayerServerId(PlayerId())
    if sourceServerId == myServerId then return end

    local casterPlayer = GetPlayerFromServerId(sourceServerId)
    if casterPlayer == -1 then return end

    local casterPed = GetPlayerPed(casterPlayer)
    if not DoesEntityExist(casterPed) then return end

    CreateDarkChargingAura(casterPed)
    SetTimeout(1500, function()
        StopWandParticles(casterPed)
    end)
end)

--- Cleanup
AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end

    for ped, handles in pairs(wandParticles) do
        if type(handles) == "table" then
            for _, handle in ipairs(handles) do
                if handle then
                    StopParticleFxLooped(handle, false)
                    RemoveParticleFx(handle, false)
                end
            end
        else
            StopParticleFxLooped(handles, false)
            RemoveParticleFx(handles, false)
        end
    end
    wandParticles = {}

    for prop, data in pairs(projectileProps) do
        if data.trailHandles then
            for _, handle in ipairs(data.trailHandles) do
                StopParticleFxLooped(handle, false)
                RemoveParticleFx(handle, false)
            end
        end
        if DoesEntityExist(prop) then
            DeleteObject(prop)
        end
    end
    projectileProps = {}
end)
