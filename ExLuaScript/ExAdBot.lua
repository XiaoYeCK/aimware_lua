--[[
    TODO:
    1. 军备竞赛模式需要额外适配
    2. 自动匹配指定模式，地图/地图组
]]

RF = gui.Reference

local DebugMode = false
LastSendTime = 0
LastTeamSwitchTime = 0
CurrentPrimaryBuybotOption = 2
CurrentSecondaryBuybotOption = 2
LastSpamEnable = false
local LastScoreboardEnable = false
local KillThrottleWaiting = false
local DeathsSinceKill = 0
local LastKillThrottleEnable = false
local KillThrottleWasInGame = false
local LastAutoMatchCheckTime = 0

local function DebugPrint(message)
    if DebugMode and gui.GetValue("misc.advanced_spam_debug") then
        print("[ExAdBot DEBUG] " .. message)
        gui.SetValue("misc.log.console", true)
    end
end

local function RestoreKillThrottleState()
    if not KillThrottleWaiting then
        return
    end

    gui.SetValue("lbot.trg.enable", true)
    gui.SetValue("rbot.enable", true)
    gui.SetValue("lbot.aim.autoaun", true)
    KillThrottleWaiting = false
    DeathsSinceKill = 0
    KillThrottleWasInGame = false
    DebugPrint("击杀限速恢复：已恢复 lbot.trg.enable、rbot.enable、lbot.aim.autoaun")
end

function SD(RF, Description)
    RF:SetDescription(Description)
end

function NonASCII(str)
    for i = 1, #str do
        byteVal = string.byte(str, i)
        if byteVal > 127 then
            return true
        end
    end
    return false
end

function CheckTranslated()
    function CheckChildren(obj)
        name = obj:GetName()
        if NonASCII(name) then
            return true
        end
        for child in obj:Children() do
            if CheckChildren(child) then
                return true
            end
        end
        return false
    end
    return CheckChildren(RF())
end

gui.Text(RF("杂项", "功能"), "--------------------------- ExAdBot ---------------------------")

    local debug_control = gui.Checkbox(RF("杂项", "功能"), "advanced_spam_debug", "调试打印", false)
        SD(RF("杂项", "功能", "调试打印"), "打印本地开火、受伤、击杀、死亡及切队判断信息")
    debug_control:SetInvisible(not DebugMode)

    gui.Checkbox(RF("杂项", "功能"), "advanced_spam_enable", "开关", false)
        SD(RF("杂项", "功能", "开关"), "启用刷屏")
    gui.Checkbox(RF("杂项", "功能"), "advanced_spam_onlyteam", "仅队内", false)
        SD(RF("杂项", "功能", "仅队内"), "仅队内刷屏")
    gui.Slider(RF("杂项", "功能"), "advanced_spam_speed", "发送间隔", 0.5, 0.5, 60.0, 0.5)
        SD(RF("杂项", "功能", "发送间隔"), "单位: 秒")
    gui.Editbox(RF("杂项", "功能"), "advanced_spam_msg", "内容")

    gui.Checkbox(RF("杂项", "功能"), "advanced_spam_showscores", "显示计分板", false)
        SD(RF("杂项", "功能", "显示计分板"), "开关计分板")

    gui.Checkbox(RF("杂项", "功能"), "advanced_spam_automatch", "自动匹配", false)
        SD(RF("杂项", "功能", "自动匹配"), "回到大厅后每秒检测一次并自动匹配")

    gui.Checkbox(RF("杂项", "功能"), "advanced_spam_autodisconnect", "自动退出", false)
        SD(RF("杂项", "功能", "自动退出"), "比赛结束自动退出至大厅")

    gui.Checkbox(RF("杂项", "功能"), "advanced_spam_botdisconnect", "出现Bot退出", false)
        SD(RF("杂项", "功能", "出现Bot退出"), "每秒检查玩家控制器；检测到m_steamID为0时退出当前对局")

    gui.Checkbox(RF("杂项", "功能"), "advanced_spam_kill_throttle", "击杀限速", false)
        SD(RF("杂项", "功能", "击杀限速"), "击杀他人后暂时关闭两种开火，达到死亡次数后恢复")
    gui.Slider(RF("杂项", "功能"), "advanced_spam_kill_throttle_deaths", "恢复所需死亡次数", 1, 1, 10, 1)
        SD(RF("杂项", "功能", "恢复所需死亡次数"), "单位: 次")

    gui.Checkbox(RF("杂项", "功能"), "advanced_spam_admode_switchteam", "切换阵营", false)
        SD(RF("杂项", "功能", "切换阵营"), "自动切换阵营")
    local switch_delay_control = gui.Slider(RF("杂项", "功能"), "advanced_spam_admode_switchdelay", "切换间隔", 1.5, 0.1, 30.0, 0.5)
        SD(RF("杂项", "功能", "切换间隔"), "单位: 秒")
    local fire_switch_control = gui.Checkbox(RF("杂项", "功能"), "advanced_spam_admode_fire_switchteam", "开火切换阵营", false)
        SD(RF("杂项", "功能", "开火切换阵营"), "开火时立即切换阵营，并刷新定时切换倒计时")
    local hurt_switch_control = gui.Checkbox(RF("杂项", "功能"), "advanced_spam_admode_hurt_switchteam", "受伤切换阵营", false)
        SD(RF("杂项", "功能", "受伤切换阵营"), "自身受到伤害时立即切换阵营，并刷新定时切换倒计时")
    local primary_weapon_control = gui.Combobox(RF("杂项", "功能"), "advanced_spam_admode_primaryweapon", "自动购买-主武器", "禁用", "轮询", "大狙", "连狙", "鸟狙")
        SD(RF("杂项", "功能", "自动购买-主武器"), "切换阵营时购买主武器；轮询仅在主武器中循环")
    local secondary_weapon_control = gui.Combobox(RF("杂项", "功能"), "advanced_spam_admode_secondaryweapon", "自动购买-副武器", "禁用", "轮询", "左轮", "沙鹰")
        SD(RF("杂项", "功能", "自动购买-副武器"), "切换阵营时购买副武器；轮询仅在副武器中循环")

gui.Text(RF("杂项", "功能"), "---------------------------------------------------------------")

function SendMsg(team_only, msg)
    if team_only then
        client.ChatTeamSay(msg)
    else
        client.ChatSay(msg)
    end
end

local function GetBuyCommand(option, current_option, first_option, last_option, commands)
    if option == 1 then
        local command = commands[current_option]
        current_option = current_option == last_option and first_option or current_option + 1
        return command, current_option
    end
    return commands[option] or "", current_option
end

local function GetLocalTeam()
    local local_index = client.GetLocalPlayerIndex()
    if not local_index or local_index <= 0 then
        return nil
    end

    local player = entities.GetByIndex(local_index)
    if not player then
        return nil
    end

    local ok, team = pcall(function()
        return player:GetFieldInt("m_iTeamNum")
    end)
    if not ok then
        return nil
    end
    return team
end

local function GetPlayerPawnIndexByUserID(user_id)
    if user_id == nil or user_id < 0 then
        return nil
    end

    -- UserID 对应玩家控制器；通过控制器的 pawn 句柄取得玩家实体索引。
    local controller = entities.GetByIndex(user_id + 1)
    if not controller then
        return nil
    end

    local ok, class = pcall(function()
        return controller:GetClass()
    end)
    if not ok or class ~= "CCSPlayerController" then
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

local function HasBotPlayer()
    for index = 1, 64 do
        local controller = entities.GetByIndex(index)
        if controller then
            local class_ok, class = pcall(function()
                return controller:GetClass()
            end)
            if class_ok and class == "CCSPlayerController" then
                local steam_id_ok, steam_id = pcall(function()
                    return controller:GetFieldInt("m_steamID")
                end)
                if steam_id_ok and steam_id == 0 then
                    return true
                end
            end
        end
    end
    return false
end

local function SwitchTeam(cur_time, primary_weapon_option, secondary_weapon_option, reason)
    local current_team = GetLocalTeam()
    if current_team ~= 2 and current_team ~= 3 then
        DebugPrint(string.format("%s切队取消：自身队伍无效(%s)", reason, tostring(current_team)))
        return false
    end

    local next_team = current_team == 2 and 3 or 2
    local buy_commands = {
        "jointeam " .. next_team,
        "cl_dm_buyrandomweapons 0"
    }
    local primary_buy_command
    primary_buy_command, CurrentPrimaryBuybotOption = GetBuyCommand(
        primary_weapon_option,
        CurrentPrimaryBuybotOption,
        2,
        4,
        { [2] = "buy awp", [3] = "buy g3sg1;buy scar20", [4] = "buy ssg08" }
    )
    local secondary_buy_command
    secondary_buy_command, CurrentSecondaryBuybotOption = GetBuyCommand(
        secondary_weapon_option,
        CurrentSecondaryBuybotOption,
        2,
        3,
        { [2] = "buy revolver", [3] = "buy deagle" }
    )
    if primary_buy_command ~= "" then
        table.insert(buy_commands, primary_buy_command)
    end
    if secondary_buy_command ~= "" then
        table.insert(buy_commands, secondary_buy_command)
    end
    local command = table.concat(buy_commands, ";")
    DebugPrint(string.format("%s切队：当前队伍=%d，目标队伍=%d，命令=%s",
        reason, current_team, next_team, command))
    client.Command(command)
    LastTeamSwitchTime = cur_time
    return true
end

LastScoreboardEnable = gui.GetValue("misc.advanced_spam_showscores")
client.AllowListener("weapon_fire")
client.AllowListener("player_hurt")
client.AllowListener("player_death")
client.AllowListener("cs_win_panel_match")

callbacks.Register("FireGameEvent", function(e)
    local event_name = e:GetName()
    local local_index = client.GetLocalPlayerIndex()

    if event_name == "cs_win_panel_match" then
        if gui.GetValue("misc.advanced_spam_autodisconnect") then
            client.Command("disconnect")
        end
        return
    end

    if event_name == "weapon_fire" then
        local user_id = e:GetInt("userid")
        local player_index = GetPlayerPawnIndexByUserID(user_id)
        local is_local_fire = local_index and local_index > 0
            and player_index ~= nil and player_index == local_index
        DebugPrint(string.format("weapon_fire：UserID=%d，事件玩家实体索引=%s，本地玩家索引=%s，自身匹配=%s，武器=%s",
            user_id, tostring(player_index), tostring(local_index), tostring(is_local_fire), e:GetString("weapon")))
        if is_local_fire then
            local switch_enabled = gui.GetValue("misc.advanced_spam_admode_switchteam")
            local fire_switch_enabled = gui.GetValue("misc.advanced_spam_admode_fire_switchteam")
            DebugPrint(string.format("自身开火处理：切换阵营=%s，开火切换=%s",
                tostring(switch_enabled), tostring(fire_switch_enabled)))
            if switch_enabled and fire_switch_enabled then
                SwitchTeam(
                    globals.RealTime(),
                    gui.GetValue("misc.advanced_spam_admode_primaryweapon"),
                    gui.GetValue("misc.advanced_spam_admode_secondaryweapon"),
                    "开火"
                )
            end
        end
        return
    end

    if event_name == "player_hurt" then
        local victim_user_id = e:GetInt("userid")
        local attacker_user_id = e:GetInt("attacker")
        local victim_index = GetPlayerPawnIndexByUserID(victim_user_id)
        local attacker_index = GetPlayerPawnIndexByUserID(attacker_user_id)
        local is_local_hurt = local_index and local_index > 0
            and victim_index ~= nil and victim_index == local_index
        local damage = e:GetInt("dmg_health")
        local weapon = string.lower(e:GetString("weapon") or "")
        local environmental_damage = weapon == "world"
            or weapon == "worldspawn"
            or weapon == "fall"
            or weapon == "trigger_hurt"
            or attacker_user_id == 65535
            or attacker_index == nil
        local self_damage = attacker_user_id == victim_user_id
            or (attacker_index ~= nil and attacker_index == victim_index)
        local excluded_damage = self_damage or environmental_damage
        DebugPrint(string.format("player_hurt：攻击者UserID=%d/玩家实体%s，受害者UserID=%d/玩家实体%s，本地玩家索引=%s，自身受伤=%s，武器=%s，伤害=%d，自身伤害=%s，环境伤害=%s",
            attacker_user_id, tostring(attacker_index), victim_user_id, tostring(victim_index),
            tostring(local_index), tostring(is_local_hurt), weapon, damage,
            tostring(self_damage), tostring(environmental_damage)))
        if is_local_hurt and damage > 0 and not excluded_damage then
            local switch_enabled = gui.GetValue("misc.advanced_spam_admode_switchteam")
            local hurt_switch_enabled = gui.GetValue("misc.advanced_spam_admode_hurt_switchteam")
            DebugPrint(string.format("自身受伤处理：切换阵营=%s，受伤切换=%s",
                tostring(switch_enabled), tostring(hurt_switch_enabled)))
            if switch_enabled and hurt_switch_enabled then
                SwitchTeam(
                    globals.RealTime(),
                    gui.GetValue("misc.advanced_spam_admode_primaryweapon"),
                    gui.GetValue("misc.advanced_spam_admode_secondaryweapon"),
                    "受伤"
                )
            end
        end
        return
    end

    if event_name ~= "player_death" then
        return
    end

    local victim_user_id = e:GetInt("userid")
    local attacker_user_id = e:GetInt("attacker")
    local victim_index = GetPlayerPawnIndexByUserID(victim_user_id)
    local attacker_index = GetPlayerPawnIndexByUserID(attacker_user_id)
    local local_kill = local_index and local_index > 0
        and attacker_index ~= nil
        and attacker_index == local_index
        and victim_user_id ~= attacker_user_id
    local local_death = local_index and local_index > 0
        and victim_index ~= nil and victim_index == local_index
    DebugPrint(string.format("player_death：击杀者UserID=%d/玩家实体%s，受害者UserID=%d/玩家实体%s，本地玩家索引=%s，自身击杀=%s，自身死亡=%s，限速=%s",
        attacker_user_id, tostring(attacker_index), victim_user_id, tostring(victim_index),
        tostring(local_index), tostring(local_kill), tostring(local_death),
        tostring(gui.GetValue("misc.advanced_spam_kill_throttle"))))

    if not gui.GetValue("misc.advanced_spam_kill_throttle") then
        return
    end

    if local_kill then
        gui.SetValue("lbot.trg.enable", false)
        gui.SetValue("rbot.enable", false)
        gui.SetValue("lbot.aim.autoaun", false)
        KillThrottleWaiting = true
        DeathsSinceKill = 0
        DebugPrint("击杀他人：关闭三项功能并重置死亡计数")
    elseif KillThrottleWaiting and local_death then
        DeathsSinceKill = DeathsSinceKill + 1
        DebugPrint(string.format("自身死亡：死亡计数=%d/%d",
            DeathsSinceKill, gui.GetValue("misc.advanced_spam_kill_throttle_deaths")))
        if DeathsSinceKill >= gui.GetValue("misc.advanced_spam_kill_throttle_deaths") then
            RestoreKillThrottleState()
            DebugPrint("死亡次数达到设定值：已恢复三项功能")
        end
    end
end)

callbacks.Register("Draw", function()

    cur_time = globals.RealTime()

    enable = gui.GetValue("misc.advanced_spam_enable")
    team_only = gui.GetValue("misc.advanced_spam_onlyteam")
    admode = gui.GetValue("misc.advanced_spam_admode_switchteam")
    team_delay = gui.GetValue("misc.advanced_spam_admode_switchdelay")
    primary_weapon_option = gui.GetValue("misc.advanced_spam_admode_primaryweapon")
    secondary_weapon_option = gui.GetValue("misc.advanced_spam_admode_secondaryweapon")
    scoreboard_enable = gui.GetValue("misc.advanced_spam_showscores")
    send_speed = gui.GetValue("misc.advanced_spam_speed")
    msg = gui.GetValue("misc.advanced_spam_msg")
    kill_throttle = gui.GetValue("misc.advanced_spam_kill_throttle")

    switch_delay_control:SetInvisible(not admode)
    fire_switch_control:SetInvisible(not admode)
    hurt_switch_control:SetInvisible(not admode)
    primary_weapon_control:SetInvisible(not admode)
    secondary_weapon_control:SetInvisible(not admode)
    debug_control:SetInvisible(not DebugMode)

    if scoreboard_enable ~= LastScoreboardEnable then
        client.Command(scoreboard_enable and "+showscores" or "-showscores")
        LastScoreboardEnable = scoreboard_enable
    end

    local local_index = client.GetLocalPlayerIndex()
    local is_in_game = local_index and local_index > 0

    if kill_throttle and not LastKillThrottleEnable then
        gui.SetValue("lbot.trg.enable", false)
        gui.SetValue("rbot.enable", false)
        gui.SetValue("lbot.aim.autoaun", false)
        KillThrottleWaiting = true
        DeathsSinceKill = 0
        KillThrottleWasInGame = false
        DebugPrint("击杀限速已开启：关闭三项功能并开始统计自身死亡")
    end

    if not kill_throttle then
        if KillThrottleWaiting then
            KillThrottleWaiting = false
            DeathsSinceKill = 0
            KillThrottleWasInGame = false
            DebugPrint("击杀限速已关闭：清除等待状态，不更改三项功能")
        end
    elseif KillThrottleWaiting and is_in_game then
        KillThrottleWasInGame = true
    elseif KillThrottleWaiting and KillThrottleWasInGame then
        DebugPrint("击杀限速等待中玩家已断线：恢复三项功能")
        RestoreKillThrottleState()
    end
    LastKillThrottleEnable = kill_throttle

    if gui.GetValue("misc.chatspam") then
        RF("杂项", "功能", "广告"):SetValue(false)
    end

    -- globals.RealTime() 返回的是游戏会话时间, 退出对局后时间会重置为0, 但 LastSendTime 仍保留着上一局的值, 导致 CurrentTime - LastSendTime 为负数
    if cur_time < LastSendTime or cur_time < LastTeamSwitchTime then
        LastSendTime = cur_time
        LastTeamSwitchTime = cur_time
    end

    if cur_time < LastAutoMatchCheckTime then
        LastAutoMatchCheckTime = cur_time
    end

    if cur_time - LastAutoMatchCheckTime >= 1 then
        LastAutoMatchCheckTime = cur_time
        local local_index = client.GetLocalPlayerIndex()
        local is_in_game = local_index and local_index > 0

        if gui.GetValue("misc.advanced_spam_botdisconnect") and is_in_game and HasBotPlayer() then
            DebugPrint("检测到Bot：退出当前对局")
            client.Command("disconnect")
        end

        if gui.GetValue("misc.advanced_spam_automatch") and not is_in_game then
            panorama.RunScript([[
                $.DispatchEvent("Activated",
                    $.GetContextPanel().FindChildTraverse("MainMenuNavBarPlay"),
                    "mouse"
                );

                LobbyAPI.StartMatchmaking("", "", "", "");
            ]])
        end
    end

    if admode and cur_time - LastTeamSwitchTime >= team_delay then
        SwitchTeam(cur_time, primary_weapon_option, secondary_weapon_option, "定时")
    end

    if enable and not LastSpamEnable and msg ~= "" then
        SendMsg(team_only, msg)
        LastSendTime = cur_time
    end

    if enable and cur_time - LastSendTime >= send_speed and msg ~= "" then
        SendMsg(team_only, msg)
        LastSendTime = cur_time
    end

    LastSpamEnable = enable
end)