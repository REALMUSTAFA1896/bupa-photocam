lib.locale(Config.Locale)

local controls = Config.Controls
local MOVE_KEYS = { 32, 33, 34, 35 }
local PUSH_TO_TALK = 249
local COLLISION_FLAGS = 1 | 2 | 16
local COLLISION_PADDING = 0.3

local cam
local active, disabled = false, false
local holding, closing = false, false
local savedView

local pos, pitch, roll, yaw
local fov, targetFov
local focus = Config.Focus.default
local filter = 1
local useFocus, showGrid, hidePlayer, showHelp = false, false, false, true
local blur = 0.0
local shownFocus

local function clamp(value, min, max)
    return value < min and min or value > max and max or value
end

local function forwardOf()
    local z, x = math.rad(yaw), math.rad(pitch)
    local flat = math.abs(math.cos(x))
    return vector3(-math.sin(z) * flat, math.cos(z) * flat, math.sin(x))
end

local function refreshButtons()
    if not showHelp then return end
    local current = Config.Filters[filter]
    local rows = {
        { controls = { controls.exit }, label = locale('exit') },
        { controls = { controls.toggleHelp }, label = locale('hide_help') },
        { controls = { controls.togglePlayer }, label = hidePlayer and locale('show_player') or locale('hide_player') },
        { controls = { controls.toggleGrid }, label = locale('grid') },
        { controls = { controls.toggleFocus }, label = useFocus and locale('focus_on') or locale('focus_off') },
    }
    if useFocus then
        rows[#rows + 1] = { controls = { controls.focusNear, controls.focusFar }, label = locale('focus_distance', shownFocus) }
    end
    rows[#rows + 1] = { controls = { controls.prevFilter, controls.nextFilter }, label = locale('filter', locale(current.label)) }
    rows[#rows + 1] = { controls = { controls.rollLeft, controls.rollRight, controls.resetRoll }, label = locale('roll') }
    rows[#rows + 1] = { controls = { controls.zoomIn, controls.zoomOut }, label = locale('zoom', math.floor(targetFov + 0.5)) }
    rows[#rows + 1] = { controls = { controls.fast, controls.slow }, label = locale('speed') }
    rows[#rows + 1] = { controls = { controls.up, controls.down }, label = locale('up_down') }
    rows[#rows + 1] = { controls = MOVE_KEYS, label = locale('move') }
    Buttons.set(rows)
end

local function applyFilter()
    local modifier = Config.Filters[filter].modifier
    if modifier then
        SetTimecycleModifier(modifier)
    else
        ClearTimecycleModifier()
    end
end

local function applyFocus()
    SetCamUseShallowDofMode(cam, useFocus)
    if not useFocus then return end
    SetCamNearDof(cam, math.max(0.1, focus - 1.0))
    SetCamFarDof(cam, focus + 2.0 + focus * 0.5)
    SetCamDofStrength(cam, 1.0)
end

local function blocked(from, to)
    local step = to - from
    local length = #step
    if length == 0 then return false end
    local tip = to + step / length * COLLISION_PADDING
    local probe = StartExpensiveSynchronousShapeTestLosProbe(from.x, from.y, from.z, tip.x, tip.y, tip.z, COLLISION_FLAGS, cache.ped, 4)
    local _, hit = GetShapeTestResult(probe)
    return hit == 1
end

local function keepNearPlayer(target)
    local center = GetEntityCoords(cache.ped)
    local offset = target - center
    local distance = #offset
    if distance > Config.MaxDistance then
        return center + offset * (Config.MaxDistance / distance), Config.MaxDistance
    end
    return target, distance
end

local function setBlur(distance)
    local start = Config.MaxDistance * Config.BlurStart
    local amount = clamp((distance - start) / (Config.MaxDistance - start), 0.0, 1.0)
    if amount == blur or (math.abs(amount - blur) < 0.02 and amount > 0.0 and amount < 1.0) then return end
    if amount == 0.0 then
        ClearExtraTimecycleModifier()
    elseif blur <= 0.0 then
        SetExtraTimecycleModifier('hud_def_blur')
    end
    blur = amount
    if blur > 0.0 then SetExtraTimecycleModifierStrength(blur) end
end

local function canOpen()
    if disabled or IsPauseMenuActive() then return false end
    local ped = cache.ped
    if IsPedDeadOrDying(ped, true) or IsPedCuffed(ped) or IsPedRagdoll(ped) or IsPedFalling(ped) then return false end
    if cache.vehicle and not Config.AllowInVehicle then return false end
    if IsPlayerFreeAiming(cache.playerId) or IsPedShooting(ped) then return false end
    return Config.CanOpen() ~= false
end

local function shouldClose()
    local ped = cache.ped
    return IsPedDeadOrDying(ped, true) or IsPedRagdoll(ped) or (cache.vehicle and not Config.AllowInVehicle)
end

local function close()
    if not active then return end
    active, closing = false, false
    RenderScriptCams(false, true, 300, true, false)
    ClearExtraTimecycleModifier()
    if Config.Filters[filter].modifier then ClearTimecycleModifier() end
    Buttons.release()

    local oldCam, view = cam, savedView
    cam = nil
    SetTimeout(350, function()
        DestroyCam(oldCam, false)
        if view then SetFollowPedCamViewMode(view) end
    end)
end

local function handleInput(frame)
    local moved, turned = false, false

    local lookX, lookY = GetDisabledControlNormal(0, 1), GetDisabledControlNormal(0, 2)
    if lookX ~= 0.0 or lookY ~= 0.0 then
        local sensitivity = Config.MouseSensitivity * (fov / Config.Fov.default)
        yaw = yaw - lookX * sensitivity
        pitch = clamp(pitch - lookY * sensitivity, -89.0, 89.0)
        turned = true
    end

    if IsDisabledControlPressed(0, controls.rollLeft) then
        roll = clamp(roll - Config.RollSpeed * frame, -45.0, 45.0)
        turned = true
    elseif IsDisabledControlPressed(0, controls.rollRight) then
        roll = clamp(roll + Config.RollSpeed * frame, -45.0, 45.0)
        turned = true
    end
    if IsDisabledControlJustPressed(0, controls.resetRoll) then
        roll = 0.0
        turned = true
    end

    local sideways, ahead = GetDisabledControlNormal(0, 30), -GetDisabledControlNormal(0, 31)
    local lift = (IsDisabledControlPressed(0, controls.up) and 1 or 0) - (IsDisabledControlPressed(0, controls.down) and 1 or 0)
    if sideways ~= 0.0 or ahead ~= 0.0 or lift ~= 0 then
        local speed = Config.Speed * frame
        if IsDisabledControlPressed(0, controls.fast) then
            speed = speed * Config.FastMultiplier
        elseif IsDisabledControlPressed(0, controls.slow) then
            speed = speed * Config.SlowMultiplier
        end
        local z = math.rad(yaw)
        local right = vector3(math.cos(z), math.sin(z), 0.0)
        local target, distance = keepNearPlayer(pos + (forwardOf() * ahead + right * sideways + vector3(0.0, 0.0, lift)) * speed)
        if not blocked(pos, target) then
            pos = target
            moved = true
            setBlur(distance)
        end
    end

    if moved then SetCamCoord(cam, pos.x, pos.y, pos.z) end
    if turned then SetCamRot(cam, pitch, roll, yaw, 2) end
end

local function handleToggles(frame)
    local labels = false

    if IsDisabledControlJustPressed(0, controls.zoomIn) then
        targetFov = math.max(Config.Fov.min, targetFov - Config.Fov.step)
        labels = true
    elseif IsDisabledControlJustPressed(0, controls.zoomOut) then
        targetFov = math.min(Config.Fov.max, targetFov + Config.Fov.step)
        labels = true
    end
    if fov ~= targetFov then
        fov = fov + (targetFov - fov) * math.min(1.0, frame * 10.0)
        if math.abs(targetFov - fov) < 0.05 then fov = targetFov end
        SetCamFov(cam, fov)
    end

    if IsDisabledControlJustPressed(0, controls.nextFilter) or IsDisabledControlJustPressed(0, controls.prevFilter) then
        local step = IsDisabledControlJustPressed(0, controls.nextFilter) and 1 or -1
        filter = (filter - 1 + step) % #Config.Filters + 1
        applyFilter()
        labels = true
    end

    if IsDisabledControlJustPressed(0, controls.toggleFocus) then
        useFocus = not useFocus
        applyFocus()
        labels = true
    end
    if useFocus then
        local change = (IsDisabledControlPressed(0, controls.focusFar) and 1 or 0) - (IsDisabledControlPressed(0, controls.focusNear) and 1 or 0)
        if change ~= 0 then
            focus = clamp(focus + change * Config.Focus.speed * frame, Config.Focus.min, Config.Focus.max)
            applyFocus()
            local rounded = math.floor(focus * 2 + 0.5) / 2
            if rounded ~= shownFocus then
                shownFocus = rounded
                labels = true
            end
        end
        SetUseHiDof()
    end

    if IsDisabledControlJustPressed(0, controls.toggleGrid) then
        showGrid = not showGrid
    end
    if IsDisabledControlJustPressed(0, controls.togglePlayer) then
        hidePlayer = not hidePlayer
        labels = true
    end
    if IsDisabledControlJustPressed(0, controls.toggleHelp) then
        showHelp = not showHelp
        labels = true
    end

    if labels then refreshButtons() end
end

local function drawGrid()
    for i = 1, 2 do
        DrawRect(i / 3, 0.5, 0.0006, 1.0, 255, 255, 255, 70)
        DrawRect(0.5, i / 3, 1.0, 0.001, 255, 255, 255, 70)
    end
end

local function run()
    while active do
        DisableAllControlActions(0)
        EnableControlAction(0, PUSH_TO_TALK, true)
        HideHudAndRadarThisFrame()

        if shouldClose() or IsDisabledControlJustReleased(0, controls.exit) then
            close()
            break
        end

        local frame = GetFrameTime()
        handleInput(frame)
        handleToggles(frame)

        if hidePlayer then SetEntityLocallyInvisible(cache.ped) end
        if showGrid then drawGrid() end
        if showHelp then Buttons.draw() end
        Wait(0)
    end
end

local function open(view)
    savedView = view
    local rotation = GetGameplayCamRot(2)
    local distance
    pos, distance = keepNearPlayer(GetGameplayCamCoord())
    pitch, roll, yaw = rotation.x, 0.0, rotation.z
    fov = clamp(GetGameplayCamFov(), Config.Fov.min, Config.Fov.max)
    targetFov = fov
    shownFocus = math.floor(focus * 2 + 0.5) / 2

    cam = CreateCamWithParams('DEFAULT_SCRIPTED_CAMERA', pos.x, pos.y, pos.z, pitch, roll, yaw, fov, true, 2)
    RenderScriptCams(true, true, 300, true, false)

    blur = 0.0
    ClearExtraTimecycleModifier()
    setBlur(distance)
    applyFilter()
    applyFocus()

    Buttons.load()
    active = true
    refreshButtons()
    CreateThread(run)
end

RegisterCommand('+bupa_photocam', function()
    if active then
        closing = true
        return
    end
    if holding then return end
    holding = true
    local view = GetFollowPedCamViewMode()
    local openAt = GetGameTimer() + Config.HoldTime
    CreateThread(function()
        while holding and GetGameTimer() < openAt do Wait(50) end
        if not holding then return end
        holding = false
        if canOpen() then
            open(view)
        else
            lib.notify({ description = locale('unavailable'), type = 'error' })
        end
    end)
end, false)

RegisterCommand('-bupa_photocam', function()
    holding = false
    if closing then close() end
end, false)

RegisterKeyMapping('+bupa_photocam', locale('keybind'), 'keyboard', Config.Key)

exports('isActive', function()
    return active
end)

exports('close', close)

exports('setDisabled', function(state)
    disabled = state == true
    if disabled then close() end
end)

AddEventHandler('onResourceStop', function(resource)
    if resource == cache.resource then close() end
end)
