local menu_root = gui.Reference()

local function has_non_ascii_name(node)
    local name = node:GetName()
    for i = 1, #name do
        if string.byte(name, i) > 127 then
            return true
        end
    end

    for child in node:Children() do
        if has_non_ascii_name(child) then
            return true
        end
    end

    return false
end

local menu_is_translated = has_non_ascii_name(menu_root)
local misc_name = menu_is_translated and "杂项" or "Miscellaneous"
local features_name = menu_is_translated and "功能" or "Features"
local limiter_label = menu_is_translated and "击杀限制器" or "Kill limiter"
local feature_root = gui.Reference(misc_name, features_name)
local limiter_group = gui.Groupbox(feature_root, limiter_label)
local cooldown_slider = gui.Slider(
    limiter_group,
    "kill_limiter_cooldown",
    menu_is_translated and "冷却时间 (秒)" or "Cooldown (s)",
    30,
    1,
    60,
    1
)

local cooldown_until = nil
local cooldown_duration = 0
local last_time = nil
local active = true
local state = {
    in_game = false,
    cooling = false,
    remaining = 0,
    duration = 0,
}

local RING_SEGMENTS = 48
local indicator_font = nil

local function draw_ring(cx, cy, radius, fraction, red, green, blue)
    draw.Color(45, 45, 45, 220)
    for i = 0, RING_SEGMENTS - 1 do
        local angle1 = -math.pi / 2 + i * 2 * math.pi / RING_SEGMENTS
        local angle2 = -math.pi / 2 + (i + 1) * 2 * math.pi / RING_SEGMENTS
        draw.Line(
            cx + math.cos(angle1) * radius,
            cy + math.sin(angle1) * radius,
            cx + math.cos(angle2) * radius,
            cy + math.sin(angle2) * radius
        )
    end

    draw.Color(red, green, blue, 255)
    local visible_segments = math.floor(RING_SEGMENTS * fraction + 0.5)
    for i = 0, visible_segments - 1 do
        local angle1 = -math.pi / 2 + i * 2 * math.pi / RING_SEGMENTS
        local angle2 = -math.pi / 2 + (i + 1) * 2 * math.pi / RING_SEGMENTS
        draw.Line(
            cx + math.cos(angle1) * radius,
            cy + math.sin(angle1) * radius,
            cx + math.cos(angle2) * radius,
            cy + math.sin(angle2) * radius
        )
    end
end

local function draw_indicator()
    if not state.in_game then
        return
    end

    local screen_width, screen_height = draw.GetScreenSize()
    if not screen_width or not screen_height then
        return
    end

    local red, green, blue = 145, 196, 68
    local fraction = 1
    local center_label = "KL"

    if state.cooling then
        red, green, blue = 245, 70, 70
        fraction = state.duration > 0
            and math.max(0, math.min(1, state.remaining / state.duration))
            or 0
        center_label = tostring(math.ceil(state.remaining))
    end

    local center_x = screen_width - 30
    local center_y = math.floor(screen_height / 2)
    local radius = 18
    draw_ring(center_x, center_y, radius, fraction, red, green, blue)

    if not indicator_font then
        indicator_font = draw.CreateFont("Segoe UI", 13, 700)
    end
    draw.SetFont(indicator_font)

    local center_width, center_height = draw.GetTextSize(center_label)
    draw.Color(red, green, blue, 255)
    draw.Text(
        center_x - math.floor(center_width / 2),
        center_y - math.floor(center_height / 2),
        center_label
    )
end

local function get_player_pawn_index_by_user_id(user_id)
    if user_id == nil or user_id < 0 then
        return nil
    end

    local controller = entities.GetByIndex(user_id + 1)
    if not controller then
        return nil
    end

    local ok_class, class = pcall(function()
        return controller:GetClass()
    end)
    if not ok_class or class ~= "CCSPlayerController" then
        return nil
    end

    local ok_handle, pawn_handle = pcall(function()
        return controller:GetFieldInt("m_hPlayerPawn")
    end)
    if not ok_handle or not pawn_handle or pawn_handle <= 0 then
        return nil
    end

    return pawn_handle % 32768
end

local function get_team(index, user_id)
    if index and index > 0 then
        local player = entities.GetByIndex(index)
        if player then
            local ok, team = pcall(function()
                return player:GetFieldInt("m_iTeamNum")
            end)
            if ok and (team == 2 or team == 3) then
                return team
            end
        end
    end

    if user_id ~= nil and user_id >= 0 then
        local controller = entities.GetByIndex(user_id + 1)
        if controller then
            local ok, team = pcall(function()
                return controller:GetFieldInt("m_iTeamNum")
            end)
            if ok and (team == 2 or team == 3) then
                return team
            end
        end
    end

    return nil
end

client.AllowListener("player_death")

callbacks.Register("FireGameEvent", function(event)
    if not active then
        return
    end

    if event:GetName() ~= "player_death" then
        return
    end

    local local_index = client.GetLocalPlayerIndex()
    if not local_index or local_index <= 0 then
        return
    end

    local attacker_user_id = event:GetInt("attacker")
    local victim_user_id = event:GetInt("userid")
    local attacker_index = get_player_pawn_index_by_user_id(attacker_user_id)
    local victim_index = get_player_pawn_index_by_user_id(victim_user_id)
    local local_kill = attacker_index ~= nil
        and attacker_index == local_index
        and victim_user_id ~= attacker_user_id
    if not local_kill then
        return
    end

    local local_team = get_team(local_index)
    local victim_team = get_team(victim_index, victim_user_id)
    if not local_team or not victim_team or local_team == victim_team then
        return
    end

    local now = globals.RealTime()
    cooldown_duration = cooldown_slider:GetValue()
    cooldown_until = now + cooldown_duration
    last_time = now
    gui.SetValue("lbot.trg.enable", false)

    state.cooling = true
    state.remaining = cooldown_duration
    state.duration = cooldown_duration
end)

callbacks.Register("Draw", "KillLimiter_Update", function()
    local now = globals.RealTime()
    local local_index = client.GetLocalPlayerIndex()
    state.in_game = local_index ~= nil and local_index > 0

    if cooldown_until then
        if last_time and now < last_time then
            cooldown_until = now + math.max(0, cooldown_until - last_time)
        end
        last_time = now

        local remaining = cooldown_until - now
        if remaining <= 0 then
            cooldown_until = nil
            gui.SetValue("lbot.trg.enable", true)
            state.cooling = false
            state.remaining = 0
        else
            state.cooling = true
            state.remaining = remaining
            state.duration = cooldown_duration
        end
    else
        last_time = now
        state.cooling = false
        state.remaining = 0
    end

    draw_indicator()
end)

callbacks.Register("Unload", "KillLimiter_Unload", function()
    active = false
    if cooldown_until then
        gui.SetValue("lbot.trg.enable", true)
    end

    callbacks.Unregister("Draw", "KillLimiter_Update")
end)
