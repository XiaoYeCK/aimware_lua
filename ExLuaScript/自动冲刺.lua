local MOVEMENT_KEYS = {
    0x57,
    0x41,
    0x53,
    0x44,
}

local sprint_active = nil

local function any_movement_key_down()
    for _, key in ipairs(MOVEMENT_KEYS) do
        if input.IsButtonDown(key) then
            return true
        end
    end

    return false
end

local function any_movement_key_released()
    for _, key in ipairs(MOVEMENT_KEYS) do
        if input.IsButtonReleased(key) then
            return true
        end
    end

    return false
end

callbacks.Register("Draw", "AutoSprint_Update", function()
    local moving = any_movement_key_down()
    local released_movement_key = any_movement_key_released()
    local should_sprint = not moving

    if should_sprint == sprint_active then
        return
    end

    if should_sprint and sprint_active ~= nil and not released_movement_key then
        return
    end

    client.Command(should_sprint and "+sprint" or "-speed")
    sprint_active = should_sprint
end)

callbacks.Register("Unload", "AutoSprint_Unload", function()
    if sprint_active then
        client.Command("-sprint")
    end

    callbacks.Unregister("Draw", "AutoSprint_Update")
end)
