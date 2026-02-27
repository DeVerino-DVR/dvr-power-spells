---@diagnostic disable: undefined-global, trailing-space, unused-local, param-type-mismatch, missing-parameter
local DoesEntityExist = DoesEntityExist
local IsEntityAPed = IsEntityAPed
local IsPedAPlayer = IsPedAPlayer
local GetPlayerPed = GetPlayerPed
local GetActivePlayers = GetActivePlayers
local GetPlayerServerId = GetPlayerServerId
local PlayerId = PlayerId
local GetEntityCoords = GetEntityCoords
local RequestNamedPtfxAsset = RequestNamedPtfxAsset
local HasNamedPtfxAssetLoaded = HasNamedPtfxAssetLoaded
local UseParticleFxAsset = UseParticleFxAsset
local StartNetworkedParticleFxLoopedOnEntity = StartNetworkedParticleFxLoopedOnEntity
local SetParticleFxLoopedColour = SetParticleFxLoopedColour
local SetParticleFxLoopedAlpha = SetParticleFxLoopedAlpha
local StopParticleFxLooped = StopParticleFxLooped
local RemoveParticleFx = RemoveParticleFx
local GetGameTimer = GetGameTimer

local activeParticles = {}
local GetEntityAlpha = GetEntityAlpha

local function Notify(payload)
    if payload then
        lib.notify(payload)
    end
end

-- Area reveal effect - show particles at the reveal location
RegisterNetEvent('dvr_exposare:areaReveal', function(centerCoords, radius)
    -- Optional: Add visual effect at the reveal location (particles, light, etc.)
    -- For now, the individual player particles will be shown by the server event
end)

local function CreateRevealParticles(targetPed, duration)
    if not targetPed or not DoesEntityExist(targetPed) then
        return nil
    end

    local effects = Config.Effects.revealParticles or {}
    local asset = effects.asset or 'scr_bike_adversary'
    local name = effects.name or 'scr_adversary_weap_smoke'
    local scale = (effects.scale or 1.0) * (Config.Reveal.particleScale or 1.0)
    local color = effects.color or {r = 255, g = 255, b = 100}
    local alpha = effects.alpha or 200

    RequestNamedPtfxAsset(asset)
    local attempts = 0
    while not HasNamedPtfxAssetLoaded(asset) and attempts < 50 do
        Wait(10)
        attempts = attempts + 1
    end

    if not HasNamedPtfxAssetLoaded(asset) then
        return nil
    end

    UseParticleFxAsset(asset)
    local handle = StartNetworkedParticleFxLoopedOnEntity(
        name,
        targetPed,
        0.0, 0.0, 0.0,
        0.0, 0.0, 0.0,
        scale,
        false, false, false
    )

    if handle then
        SetParticleFxLoopedColour(handle, color.r / 255, color.g / 255, color.b / 255, false)
        SetParticleFxLoopedAlpha(handle, alpha / 255)
        
        activeParticles[targetPed] = {
            handle = handle,
            expiresAt = GetGameTimer() + (duration or Config.Reveal.particleDuration or 3000)
        }

        CreateThread(function()
            while activeParticles[targetPed] and GetGameTimer() < activeParticles[targetPed].expiresAt do
                Wait(100)
            end
            
            if activeParticles[targetPed] then
                StopParticleFxLooped(activeParticles[targetPed].handle, false)
                RemoveParticleFx(activeParticles[targetPed].handle, false)
                activeParticles[targetPed] = nil
            end
        end)
    end

    return handle
end

RegisterNetEvent('dvr_exposare:forceReveal', function()
    -- Force clear hiddenis effect by applying a reveal effect
    -- This will trigger the ClearEffect function in hiddenis
    local myPed = cache and cache.ped or GetPlayerPed(PlayerId())
    if myPed and DoesEntityExist(myPed) then
        -- Apply hiddenis with duration 0 and alpha 255 to force reveal
        TriggerEvent('dvr_hiddenis:apply', 0, 255)
        
        -- Also create reveal particles
        CreateRevealParticles(myPed, Config.Reveal.particleDuration)
    end
end)

RegisterNetEvent('dvr_exposare:revealPlayer', function(targetServerId, casterServerId)
    local myServerId = GetPlayerServerId(PlayerId())
    
    if targetServerId == myServerId then
        Notify(Config.Messages.revealed)
        
        local myPed = cache and cache.ped or GetPlayerPed(PlayerId())
        if myPed and DoesEntityExist(myPed) then
            CreateRevealParticles(myPed, Config.Reveal.particleDuration)
        end
    end
end)

RegisterNetEvent('dvr_exposare:showRevealEffect', function(targetServerId)
    local myServerId = GetPlayerServerId(PlayerId())
    
    if targetServerId == myServerId then
        return
    end

    for _, playerId in ipairs(GetActivePlayers()) do
        local playerServerId = GetPlayerServerId(playerId)
        if playerServerId == targetServerId then
            local ped = GetPlayerPed(playerId)
            if ped and DoesEntityExist(ped) then
                CreateRevealParticles(ped, Config.Reveal.particleDuration)
            end
            break
        end
    end
end)

AddEventHandler('onResourceStop', function(resourceName)
    if resourceName ~= GetCurrentResourceName() then
        return
    end
    
    for ped, data in pairs(activeParticles) do
        if data.handle then
            StopParticleFxLooped(data.handle, false)
            RemoveParticleFx(data.handle, false)
        end
    end
    activeParticles = {}
end)

