-- REQUIRES: ESX Framework (es_extended) - Replace ESX.PlayerData calls with your framework
---@diagnostic disable: undefined-global, trailing-space, unused-local, deprecated, param-type-mismatch
local GetGameTimer = GetGameTimer
local GetActivePlayers = GetActivePlayers
local GetGamePool = GetGamePool
local GetEntityModel = GetEntityModel
local GetPlayerServerId = GetPlayerServerId
local GetPlayerPed = GetPlayerPed
local GetHashKey = GetHashKey
local GetEntityCoords = GetEntityCoords
local CreateObject = CreateObject
local SetEntityCollision = SetEntityCollision
local SetEntityAlpha = SetEntityAlpha
local PlayEntityAnim = PlayEntityAnim
local IsEntityPlayingAnim = IsEntityPlayingAnim
local DoesEntityExist = DoesEntityExist
local DeleteEntity = DeleteEntity
local DeleteObject = DeleteObject
local SetEntityAsMissionEntity = SetEntityAsMissionEntity
local AttachEntityToEntity = AttachEntityToEntity
local GetPedBoneIndex = GetPedBoneIndex
local DetachEntity = DetachEntity
local RequestModel = RequestModel
local HasModelLoaded = HasModelLoaded
local NetworkGetNetworkIdFromEntity = NetworkGetNetworkIdFromEntity
local NetworkGetEntityFromNetworkId = NetworkGetEntityFromNetworkId
local NetworkHasControlOfEntity = NetworkHasControlOfEntity
local NetworkRequestControlOfEntity = NetworkRequestControlOfEntity
local RequestNamedPtfxAsset = RequestNamedPtfxAsset
local HasNamedPtfxAssetLoaded = HasNamedPtfxAssetLoaded
local UseParticleFxAssetNextCall = UseParticleFxAssetNextCall
local UseParticleFxAsset = UseParticleFxAsset
local StartParticleFxNonLoopedAtCoord = StartParticleFxNonLoopedAtCoord
local StartParticleFxLoopedOnEntity = StartParticleFxLoopedOnEntity
local StopParticleFxLooped = StopParticleFxLooped
local SetParticleFxLoopedColour = SetParticleFxLoopedColour
local SetParticleFxLoopedAlpha = SetParticleFxLoopedAlpha
local DrawLightWithRange = DrawLightWithRange
local IsEntityDead = IsEntityDead
local IsPedFatallyInjured = IsPedFatallyInjured
local IsPedRagdoll = IsPedRagdoll
local CanPedRagdoll = CanPedRagdoll
local SetPedCanRagdoll = SetPedCanRagdoll
local ClearPedTasks = ClearPedTasks
local TaskStandStill = TaskStandStill
local SetPedCanRagdollFromPlayerImpact = SetPedCanRagdollFromPlayerImpact
local DisableControlAction = DisableControlAction
local DisablePlayerFiring = DisablePlayerFiring
local PlayerId = PlayerId
local PlayerPedId = PlayerPedId
local math_sin = math.sin
local math_pi = math.pi
local SPELL_ID <const> = 'prothea'

local activeShields = {}
local shieldProps = {}
local protegoActive = false
local allProps = {}
local protheaSound = nil
local controlLockToken = nil
local animLoopToken = nil
local shieldModelHash <const> = GetHashKey(Config.Shield.model)

local function SetLocalShieldState(active)
    if LocalPlayer and LocalPlayer.state then
        LocalPlayer.state:set('protheaShield', active == true, true)
    end
end

local function IsPedUnableToCast(ped)
    if not ped or ped == 0 or not DoesEntityExist(ped) then
        return false
    end

    if IsEntityDead(ped) or IsPedFatallyInjured(ped) or ESX.PlayerData.dead then
        return true, 'Vous êtes inconscient, impossible de lancer un sort.'
    end

    if IsPedRagdoll(ped) then
        return true, 'Vous êtes à terre, impossible de lancer un sort.'
    end

    return false
end

local function EnsureModelLoaded(modelHash, timeout)
    if not modelHash or modelHash == 0 then
        return false
    end

    RequestModel(modelHash)
    local start <const> = GetGameTimer()
    local deadline <const> = start + (timeout or 3000)

    while not HasModelLoaded(modelHash) do
        if GetGameTimer() > deadline then
            return false
        end
        Wait(0)
    end

    return true
end

local function DisablePedRagdoll(ped)
    if not ped or ped == 0 or not DoesEntityExist(ped) then
        return nil
    end

    local canRagdoll = CanPedRagdoll(ped)
    SetPedCanRagdoll(ped, false)
    SetPedCanRagdollFromPlayerImpact(ped, false)
    TaskStandStill(ped, -1)
    return canRagdoll
end

local function RestorePedRagdoll(ped, previousState)
    if not ped or ped == 0 or not DoesEntityExist(ped) then
        return
    end

    local allow = previousState
    if allow == nil then
        allow = true
    end

    SetPedCanRagdoll(ped, allow)
    SetPedCanRagdollFromPlayerImpact(ped, allow)
    ClearPedTasks(ped)
end

local function StopLocalControlLock()
    controlLockToken = nil
end

local function StartLocalControlLock(durationMs)
    local token = GetGameTimer()
    controlLockToken = token
    local expireAt = GetGameTimer() + (durationMs or 0)

    CreateThread(function()
        while controlLockToken == token and GetGameTimer() < expireAt do
            DisableControlAction(0, 30, true) -- move left/right
            DisableControlAction(0, 31, true) -- move forward/back
            DisableControlAction(0, 21, true) -- sprint
            DisableControlAction(0, 22, true) -- jump
            DisableControlAction(0, 24, true) -- attack
            DisableControlAction(0, 25, true) -- aim
            DisableControlAction(0, 44, true) -- cover
            DisableControlAction(0, 140, true)
            DisableControlAction(0, 141, true)
            DisableControlAction(0, 142, true)
            DisableControlAction(0, 257, true)
            DisableControlAction(0, 263, true)
            DisableControlAction(0, 264, true)
            DisableControlAction(0, 45, true) -- reload / alt action
            DisableControlAction(0, 23, true) -- enter vehicle
            DisablePlayerFiring(PlayerId(), true)
            Wait(0)
        end
    end)
end

local function StopLocalAnimLoop()
    animLoopToken = nil
end

local function StartLocalAnimLoop(ped)
    if not DoesEntityExist(ped) then return end

    local token = GetGameTimer()
    animLoopToken = token
    local animDict <const> = Config.Animation.dict
    local animName <const> = Config.Animation.name

    CreateThread(function()
        while animLoopToken == token and DoesEntityExist(ped) do
            if not IsEntityPlayingAnim(ped, animDict, animName, 3) then
                TaskPlayAnim(
                    ped,
                    animDict,
                    animName,
                    8.0, -8.0,
                    Config.Animation.duration,
                    Config.Animation.flag,
                    0,
                    false, false, false
                )
            end
            Wait(250)
        end
    end)
end

local function PulseLight(coords, settings)
    if not coords or not settings or not settings.color then
        return
    end

    local start <const> = GetGameTimer()
    local duration <const> = settings.duration or 400
    local color <const> = settings.color
    local radius <const> = settings.radius or 6.0
    local intensity <const> = settings.intensity or 10.0

    CreateThread(function()
        local now = GetGameTimer()
        while now - start < duration do
            local fade <const> = 1.0 - ((now - start) / duration)
            DrawLightWithRange(coords.x, coords.y, coords.z, color.r, color.g, color.b, radius, intensity * fade)
            Wait(0)
            now = GetGameTimer()
        end
    end)
end

local function PlayNonLoopedEffect(definition, coords)
    if not definition or not coords or not definition.asset or not definition.effect then
        return
    end

    RequestNamedPtfxAsset(definition.asset)
    while not HasNamedPtfxAssetLoaded(definition.asset) do
        Wait(0)
    end

    local repetitions <const> = definition.count or 1
    for _ = 1, repetitions do
        UseParticleFxAssetNextCall(definition.asset)
        StartParticleFxNonLoopedAtCoord(
            definition.effect,
            coords.x, coords.y, coords.z + (definition.zOffset or 0.0),
            0.0, 0.0, 0.0,
            definition.scale or 1.0,
            false, false, false
        )
    end

    if definition.light then
        PulseLight(coords, definition.light)
    end
end

local function PlayCastEffect(ped)
    local cfg = Config.Effects and Config.Effects.castFlash
    if not cfg or not DoesEntityExist(ped) then
        return
    end

    local coords <const> = GetEntityCoords(ped) + vector3(0.0, 0.0, 0.5)
    PlayNonLoopedEffect(cfg, coords)
end

local function ApplyLoopColour(handle, color)
    if not handle or not color then
        return
    end

    local r = color.r or 0.0
    local g = color.g or 0.0
    local b = color.b or 0.0

    if r > 1.0 or g > 1.0 or b > 1.0 then
        r = r / 255.0
        g = g / 255.0
        b = b / 255.0
    end

    SetParticleFxLoopedColour(handle, r, g, b, false)
end

local function StartShieldLoop(shieldProp)
    local loopCfg = Config.Effects and Config.Effects.shieldLoop
    if not loopCfg or not DoesEntityExist(shieldProp) then
        return nil
    end

    RequestNamedPtfxAsset(loopCfg.asset)
    while not HasNamedPtfxAssetLoaded(loopCfg.asset) do
        Wait(0)
    end

    UseParticleFxAsset(loopCfg.asset)
    local fxHandle = StartParticleFxLoopedOnEntity(
        loopCfg.effect,
        shieldProp,
        loopCfg.offset and loopCfg.offset.x or 0.0,
        loopCfg.offset and loopCfg.offset.y or 0.0,
        loopCfg.offset and loopCfg.offset.z or 0.0,
        0.0, 0.0, 0.0,
        loopCfg.scale or 1.0,
        false, false, false
    )

    ApplyLoopColour(fxHandle, loopCfg.color)

    if loopCfg.alpha then
        SetParticleFxLoopedAlpha(fxHandle, loopCfg.alpha)
    end

    return fxHandle
end

local function StopShieldLoop(shieldData)
    if shieldData and shieldData.loopFx then
        StopParticleFxLooped(shieldData.loopFx, false)
        shieldData.loopFx = nil
    end
end

local function PlayBreakEffect(coords)
    local cfg = Config.Effects and Config.Effects.breakFlash
    if not cfg then
        return
    end
    PlayNonLoopedEffect(cfg, coords)
end

local function SafeDeleteProp(propHandle)
    if not propHandle then
        return
    end

    if DoesEntityExist(propHandle) then
        DetachEntity(propHandle, true, true)

        if not NetworkHasControlOfEntity(propHandle) then
            local start <const> = GetGameTimer()
            local deadline <const> = start + 800
            NetworkRequestControlOfEntity(propHandle)
            while GetGameTimer() < deadline and not NetworkHasControlOfEntity(propHandle) do
                Wait(0)
                NetworkRequestControlOfEntity(propHandle)
            end
        end

        SetEntityAsMissionEntity(propHandle, true, true)
        DeleteEntity(propHandle)

        if DoesEntityExist(propHandle) then
            DeleteObject(propHandle)
        end

        if DoesEntityExist(propHandle) then
            local netId <const> = NetworkGetNetworkIdFromEntity(propHandle)
            if netId and netId > 0 then
                TriggerServerEvent('th_prothea:forceDeleteEntity', netId)
            end
            return -- keep tracking so sweeper can retry if deletion failed
        end
    end

    allProps[propHandle] = nil
end

local function IsTrackedShieldProp(entity)
    if not entity then
        return false
    end

    if allProps[entity] ~= nil then
        return true
    end

    for _, shieldData in pairs(shieldProps) do
        if shieldData.prop == entity then
            return true
        end
    end

    return false
end

local function CleanupShield(serverId, opts)
    opts = opts or {}
    local shieldData = shieldProps[serverId]
    if not shieldData then
        activeShields[serverId] = nil
        if serverId == GetPlayerServerId(PlayerId()) then
            StopLocalControlLock()
            StopLocalAnimLoop()
            SetLocalShieldState(false)
            protegoActive = false
        end
        return
    end

    if shieldData.prop then
        StopShieldLoop(shieldData)
        SafeDeleteProp(shieldData.prop)
        shieldData.prop = nil
    end

    if DoesEntityExist(shieldData.ped) then
        RestorePedRagdoll(shieldData.ped, shieldData.canRagdoll)

        if not opts.skipBreakEffect then
            PlayBreakEffect(GetEntityCoords(shieldData.ped) + vector3(0.0, 0.0, 0.5))
        end

        if serverId == GetPlayerServerId(PlayerId()) then
            if protheaSound then
                protheaSound:stop()
                protheaSound = nil
            end

            StopLocalControlLock()
            StopLocalAnimLoop()
            SetLocalShieldState(false)
            SetEntityInvincible(shieldData.ped, false)
            SetEntityCanBeDamaged(shieldData.ped, true)
            local contextSuffix = opts.context and (' (' .. opts.context .. ')') or ''
            lib.print.info('[PROTHEA] Godmode désactivé' .. contextSuffix)
        end
    end

    shieldProps[serverId] = nil
    activeShields[serverId] = nil

    if serverId == GetPlayerServerId(PlayerId()) then
        protegoActive = false
    end
end

local function AttachShieldToPed(shieldProp, ped)
    if not shieldProp or not ped or not DoesEntityExist(shieldProp) or not DoesEntityExist(ped) then
        return
    end

    local pelvisBone <const> = GetPedBoneIndex(ped, 11816) -- SKEL_Pelvis keeps the shield centered
    AttachEntityToEntity(shieldProp, ped, pelvisBone, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, false, false, false, true, 2, true)
end

local function HasLocalShield()
    local myServerId <const> = GetPlayerServerId(PlayerId())
    return protegoActive or (myServerId and activeShields[myServerId] ~= nil)
end

local function ShouldNegateIncomingSpell()
    return HasLocalShield()
end

CreateThread(function()
    while true do
        local hasPulse = false
        local pulseCfg = Config.Effects and Config.Effects.pulse
        if pulseCfg then
            local now <const> = GetGameTimer()
            for _, data in pairs(shieldProps) do
                if DoesEntityExist(data.ped) then
                    hasPulse = true
                    local coords <const> = GetEntityCoords(data.ped) + vector3(0.0, 0.0, 1.0)
                    local period <const> = pulseCfg.period or 1600
                    local phase = ((now - (data.pulseStart or now)) % period) / period
                    local wave <const> = 0.5 + 0.5 * math_sin(phase * 2.0 * math_pi)
                    DrawLightWithRange(
                        coords.x, coords.y, coords.z,
                        pulseCfg.color.r,
                        pulseCfg.color.g,
                        pulseCfg.color.b,
                        pulseCfg.radius or 6.5,
                        (pulseCfg.intensity or 10.0) * (0.6 + wave * 0.8)
                    )
                end
            end
        end

        if hasPulse then
            Wait(0)
        else
            Wait(250)
        end
    end
end)

local function IsProtheaUnlocked()
    if GetResourceState('th_power') ~= 'started' then
        return true
    end

    local ok, hasSpell = pcall(function()
        local unlocked = exports['th_power']:GetSpell(SPELL_ID)
        return unlocked
    end)

    if not ok then
        return true
    end

    return hasSpell == true
end

local function ResetStuckLocalShield()
    local myServerId <const> = GetPlayerServerId(PlayerId())
    if not myServerId then return false end

    local data = shieldProps[myServerId]
    local isStuck = protegoActive or (activeShields[myServerId] ~= nil)
    if not isStuck then
        return false
    end

    local propMissing = not data or not data.prop or not DoesEntityExist(data.prop)
    if propMissing then
        print('[PROTHEA] Bouclier local bloqué sans prop, on nettoie et on relance')
        CleanupShield(myServerId, { context = 'selfReset', skipBreakEffect = true })
        return true
    end

    return false
end

local function EnsureUnlocked()
    if IsProtheaUnlocked() then
        return true
    end

    return false
end

local function TryCastShield()
    print('[PROTHEA] Activation via commande/keymap (prothea_cast/prothea)')

    if LocalPlayer and LocalPlayer.state and LocalPlayer.state.staturion == true then
        print('[PROTHEA] Cast bloqué: pétrifié')
        return
    end

    local ped <const> = PlayerPedId()
    local blocked, reason = IsPedUnableToCast(ped)
    if blocked then
        if reason then
            if lib and lib.notify then
                lib.notify({ description = reason, type = 'error' })
            else
                print('[PROTHEA] ' .. reason)
            end
        end
        return
    end

    if HasLocalShield() then
        if not ResetStuckLocalShield() then
            print('[PROTHEA] Cast bloqué: bouclier déjà actif')
            return
        end
    end

    if not EnsureUnlocked() then
        print('[PROTHEA] Cast bloqué: sort non débloqué')
        return
    end

    TriggerServerEvent('th_prothea:castShield')
end

RegisterCommand('prothea_cast', function()
    TryCastShield()
end, false)

RegisterCommand('prothea', function()
    TryCastShield()
end, false)

RegisterKeyMapping('prothea_cast', '~g~(SORTS)~s~ Prothèa', 'keyboard', Config.Key)
print('[PROTHEA] Key mapping enregistré : prothea_cast -> ' .. tostring(Config.Key))

RegisterNetEvent('th_prothea:applyShield', function(targetServerId, duration, blockDamage, applyGodmode, spawnProps, spellLevel)
    local effectiveDuration = math.max(0, duration or 0)
    local shouldSpawnProps = spawnProps ~= false
    local shouldApplyGodmode = applyGodmode == true

    print(('[PROTHEA][client] applyShield sid=%s dur=%s props=%s god=%s lvl=%s'):format(
        tostring(targetServerId), tostring(effectiveDuration), tostring(shouldSpawnProps), tostring(shouldApplyGodmode), tostring(spellLevel)
    ))

    CleanupShield(targetServerId, { skipBreakEffect = true, context = 'override' })
    if effectiveDuration > 0 then
        activeShields[targetServerId] = GetGameTimer() + effectiveDuration
    end
    
    local targetPlayer = nil
    local players <const> = GetActivePlayers()
    for _, player in ipairs(players) do
        if GetPlayerServerId(player) == targetServerId then
            targetPlayer = player
            break
        end
    end
    
    if targetPlayer then
        local ped <const> = GetPlayerPed(targetPlayer)
        if not DoesEntityExist(ped) then
            print('[PROTHEA][client] ped introuvable pour serverId ' .. tostring(targetServerId))
            return
        end

        local coords <const> = GetEntityCoords(ped)

        PlayCastEffect(ped)

        if not shouldSpawnProps or effectiveDuration <= 0 then
            return
        end
        
        local propModel <const> = GetHashKey(Config.Shield.model)
        local modelLoaded = (lib and lib.requestModel and lib.requestModel(propModel, 5000)) or EnsureModelLoaded(propModel, 5000)
        if not modelLoaded then
            print('[PROTHEA][client] modèle introuvable: ' .. tostring(Config.Shield.model))
            return
        end
        
        local shieldProp <const> = CreateObject(propModel, coords.x, coords.y, coords.z-1.0, true, false, false)
        if not shieldProp or not DoesEntityExist(shieldProp) then
            print('[PROTHEA][client] échec création prop pour serverId ' .. tostring(targetServerId))
            return
        end
        SetEntityCollision(shieldProp, true, true)
        SetEntityAlpha(shieldProp, Config.Shield.alpha, false)
        AttachShieldToPed(shieldProp, ped)

        local loopFx <const> = StartShieldLoop(shieldProp)
        
        lib.requestAnimDict(Config.Animation.dict)
        TaskPlayAnim(
            ped,
            Config.Animation.dict,
            Config.Animation.name,
            8.0, -8.0,
            Config.Animation.duration,
            Config.Animation.flag,
            0,
            false, false, false
        )
        
        allProps[shieldProp] = {
            serverId = targetServerId,
            createdTime = GetGameTimer()
        }

        local canRagdoll = DisablePedRagdoll(ped)
        
        if targetServerId == GetPlayerServerId(PlayerId()) then
            if shouldApplyGodmode then
                SetEntityInvincible(ped, true)
                SetEntityCanBeDamaged(ped, false)
                lib.print.info('[PROTEGO] Godmode activé pour ' .. (effectiveDuration / 1000) .. 's')
            end

            StartLocalControlLock(effectiveDuration + 200)
            StartLocalAnimLoop(ped)
            SetLocalShieldState(true)
        end
        
        shieldProps[targetServerId] = {
            prop = shieldProp,
            ped = ped,
            serverId = targetServerId,
            loopFx = loopFx,
            pulseStart = GetGameTimer(),
            canRagdoll = canRagdoll
        }
        
        if targetServerId == GetPlayerServerId(PlayerId()) then
            if protheaSound then
                protheaSound:stop()
            end
            
            -- REPLACE WITH YOUR SOUND SYSTEM
            -- protheaSound = exports['lo_audio']:playSound({
            -- id = 'prothea_activate_' .. GetGameTimer(),
            -- url = 'YOUR_SOUND_URL_HERE',
            -- volume = 0.2,
            -- distance = 10.0,
            -- loop = false
            -- })
            
            protegoActive = true
        end
    end
end)

CreateThread(function()
    while true do
        Wait(5000)
        
        local currentTime = GetGameTimer()
        local propsToRemove = {}
        
        for propHandle, propData in pairs(allProps) do
            if DoesEntityExist(propHandle) then
                if currentTime - propData.createdTime > 5000 then
                    local found = false
                    for _, shieldData in pairs(shieldProps) do
                        if shieldData.prop == propHandle then
                            found = true
                            break
                        end
                    end
                    
                    if not found then
                        table.insert(propsToRemove, propHandle)
                    end
                end
            else
                table.insert(propsToRemove, propHandle)
            end
        end
        
        for _, propHandle in ipairs(propsToRemove) do
            if DoesEntityExist(propHandle) then
                SafeDeleteProp(propHandle)
                lib.print.info('[PROTEGO] Prop orphelin supprimé')
            else
                allProps[propHandle] = nil
            end
        end
    end
end)

CreateThread(function()
    while true do
        Wait(7000)

        local objects <const> = GetGamePool('CObject')
        if objects then
            for _, object in ipairs(objects) do
                if DoesEntityExist(object) and GetEntityModel(object) == shieldModelHash and not IsTrackedShieldProp(object) then
                    SafeDeleteProp(object)
                end
            end
        end
    end
end)

CreateThread(function()
    while true do
        Wait(100)
        
        local currentTime <const> = GetGameTimer()
        
        for serverId, endTime in pairs(activeShields or {}) do
            local timeLeft = endTime - currentTime
            
            if timeLeft <= 0 then
                local isLocal = serverId == GetPlayerServerId(PlayerId())
                CleanupShield(serverId, { context = 'timer' })
            end
        end
    end
end)

RegisterNetEvent('th_prothea:forceDeleteEntityClient', function(netId)
    if not netId or netId == 0 then return end

    local entity <const> = NetworkGetEntityFromNetworkId(netId)
    if not entity or entity == 0 or not DoesEntityExist(entity) then
        return
    end

    if not NetworkHasControlOfEntity(entity) then
        local start <const> = GetGameTimer()
        local deadline <const> = start + 800
        NetworkRequestControlOfEntity(entity)
        while GetGameTimer() < deadline and not NetworkHasControlOfEntity(entity) do
            Wait(0)
            NetworkRequestControlOfEntity(entity)
        end
    end

    DetachEntity(entity, true, true)
    SetEntityAsMissionEntity(entity, true, true)
    DeleteEntity(entity)
    if DoesEntityExist(entity) then
        DeleteObject(entity)
    end

    if not DoesEntityExist(entity) then
        allProps[entity] = nil
    end
end)

local function BlockedSpellEvent(eventName, reason)
    print(('[PROTHEA] Sort bloqué (%s): %s'):format(eventName, reason or 'bouclier actif'))
end

-- Staturion petrify
RegisterNetEvent('th_staturion:applyPetrify', function()
    if ShouldNegateIncomingSpell() then
        BlockedSpellEvent('th_staturion:applyPetrify', 'petrify annulé')
        CancelEvent()
    end
end)

-- Repulsar knockback
RegisterNetEvent('th_repulsar:receiveForce', function()
    if ShouldNegateIncomingSpell() then
        BlockedSpellEvent('th_repulsar:receiveForce', 'repoussé ignoré')
        CancelEvent()
    end
end)

-- Levionis levitation
RegisterNetEvent('th_levionis:startLevitation', function(targetServerId)
    if ShouldNegateIncomingSpell() and targetServerId == GetPlayerServerId(PlayerId()) then
        BlockedSpellEvent('th_levionis:startLevitation', 'lévitation annulée')
        CancelEvent()
    end
end)

-- Levionis fall/stop cleanup events ignored while shielded
RegisterNetEvent('th_levionis:stopLevitation', function(targetServerId)
    if ShouldNegateIncomingSpell() and targetServerId == GetPlayerServerId(PlayerId()) then
        BlockedSpellEvent('th_levionis:stopLevitation', 'stop levitation ignoré')
        CancelEvent()
    end
end)

-- Animarion forced transformation
RegisterNetEvent('th_animarion:applyTransform', function()
    if ShouldNegateIncomingSpell() then
        BlockedSpellEvent('th_animarion:applyTransform', 'transformation annulée')
        CancelEvent()
    end
end)

-- Accyra projectile visuals hitting player (ignore if shielded)
RegisterNetEvent('th_accyra:fireProjectile', function(sourceServerId)
    local myServerId <const> = GetPlayerServerId(PlayerId())
    if sourceServerId ~= myServerId and ShouldNegateIncomingSpell() then
        BlockedSpellEvent('th_accyra:fireProjectile', 'projectile ignoré')
        CancelEvent()
    end
end)

RegisterNetEvent('th_prothea:castResult', function(status, data)
    if status == 'ok' then
        print(('[PROTHEA][client] cast ok: dur=%s props=%s god=%s lvl=%s'):format(
            tostring(data.duration), tostring(data.props), tostring(data.godmode), tostring(data.level)
        ))
        return
    end

    print(('[PROTHEA][client] cast bloqué: %s %s'):format(tostring(status), json.encode(data or {})))
end)

RegisterNetEvent('th_prothea:removeShield', function(targetServerId)
    if targetServerId then
        CleanupShield(targetServerId, { context = 'removeShield' })
    else
        local cleanupQueue = {}
        for serverId in pairs(shieldProps or {}) do
            table.insert(cleanupQueue, serverId)
        end

        for _, serverId in ipairs(cleanupQueue) do
            CleanupShield(serverId, { context = 'removeShield' })
        end

        shieldProps = {}
        activeShields = {}
    end
end)

AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    
    local cleanupQueue = {}
    for serverId in pairs(shieldProps or {}) do
        table.insert(cleanupQueue, serverId)
    end

    for _, serverId in ipairs(cleanupQueue) do
        CleanupShield(serverId, { skipBreakEffect = true, context = 'onResourceStop' })
    end

    shieldProps = {}
    activeShields = {}
    allProps = {}
    StopLocalControlLock()
    StopLocalAnimLoop()
    SetLocalShieldState(false)
    protegoActive = false
end)

exports('hasLocalShield', HasLocalShield)
exports('hasActiveShield', HasLocalShield)
