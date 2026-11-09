--[[
    TODO:
    1. 军备竞赛模式需要额外适配
    2. 自动匹配指定模式，地图/地图组
]]

local DebugMode = false

RF = gui.Reference

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
local AutoMatchStarted = false
local AutoMatchDelayUntil = nil
local DisconnectIssued = false
local WasInGame = nil
local BotDisconnectPendingUntil = nil

local function DebugPrint(message)
    if DebugMode and gui.GetValue("misc.exadbot_debug") then
        print("[ExAdBot DEBUG] " .. message)
        gui.SetValue("misc.log.console", true)
    end
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

    gui.Groupbox(RF("杂项", "功能"), "ExAdBot")

    local debug_control = gui.Checkbox(RF("杂项", "功能", "ExAdBot"), "exadbot_debug", "调试打印", false)
        SD(RF("杂项", "功能", "ExAdBot", "调试打印"), "打印本地开火、受伤、击杀、死亡及切队判断信息")
    debug_control:SetInvisible(not DebugMode)

    gui.Checkbox(RF("杂项", "功能", "ExAdBot"), "exadbot_spam_enable", "定时发送", false)
        SD(RF("杂项", "功能", "ExAdBot", "定时发送"), "启用定时发送消息")
            local spam_onlyteam_control = gui.Checkbox(RF("杂项", "功能", "ExAdBot"), "exadbot_spam_onlyteam", "队内发送", false)
                SD(RF("杂项", "功能", "ExAdBot", "队内发送"), "仅队内发送消息")
            local spam_speed_control = gui.Slider(RF("杂项", "功能", "ExAdBot"), "exadbot_spam_speed", "发送间隔", 0.5, 0.5, 60.0, 0.5)
                SD(RF("杂项", "功能", "ExAdBot", "发送间隔"), "单位: 秒")
            local spam_msg_control = gui.Editbox(RF("杂项", "功能", "ExAdBot"), "exadbot_spam_msg", "内容")

    gui.Checkbox(RF("杂项", "功能", "ExAdBot"), "exadbot_showscores", "显示计分板", false)
        SD(RF("杂项", "功能", "ExAdBot", "显示计分板"), "开关计分板")

    gui.Checkbox(RF("杂项", "功能", "ExAdBot"), "exadbot_automatch", "自动匹配", false)
        SD(RF("杂项", "功能", "ExAdBot", "自动匹配"), "在大厅启用时立即匹配；从对局回到大厅后按匹配延迟设置触发")
            local automatch_delay_control = gui.Slider(RF("杂项", "功能", "ExAdBot"), "exadbot_automatch_delay", "匹配延迟", 10, 1, 10, 1)
                SD(RF("杂项", "功能", "ExAdBot", "匹配延迟"), "从对局回到大厅后等待时间；单位: 秒")

    gui.Multibox(RF("杂项", "功能", "ExAdBot"), "自动退出时机")
        gui.Checkbox(RF("杂项", "功能", "ExAdBot", "自动退出时机"), "exadbot_autodisconnect", "比赛结束", false)
        gui.Checkbox(RF("杂项", "功能", "ExAdBot", "自动退出时机"), "exadbot_botdisconnect", "出现机器人", false)

            local botdisconnect_delay_control = gui.Slider(RF("杂项", "功能", "ExAdBot"), "exadbot_botdisconnect_delay", "Bot退出等待时长", 1, 1, 10, 1)
                SD(RF("杂项", "功能", "ExAdBot", "Bot退出等待时长"), "检测到Bot后等待时间；单位: 秒")

    gui.Checkbox(RF("杂项", "功能", "ExAdBot"), "exadbot_kill_throttle", "击杀限速", false)
        SD(RF("杂项", "功能", "ExAdBot", "击杀限速"), "击杀他人后暂时关闭两种开火，达到死亡次数后恢复")
            local kill_throttle_deaths_control = gui.Slider(RF("杂项", "功能", "ExAdBot"), "exadbot_kill_throttle_deaths", "恢复所需死亡次数", 1, 1, 10, 1)
                SD(RF("杂项", "功能", "ExAdBot", "恢复所需死亡次数"), "单位: 次")

    gui.Checkbox(RF("杂项", "功能", "ExAdBot"), "exadbot_switcher_enable", "切换阵营", false)
        SD(RF("杂项", "功能", "ExAdBot", "切换阵营"), "自动切换阵营")
    local switcher_switchdelay_control = gui.Slider(RF("杂项", "功能", "ExAdBot"), "exadbot_switcher_switchdelay", "切换间隔", 1.5, 0.1, 30.0, 0.5)
        SD(RF("杂项", "功能", "ExAdBot", "切换间隔"), "单位: 秒")
    local switcher_fire_switchteam_control = gui.Checkbox(RF("杂项", "功能", "ExAdBot"), "exadbot_switcher_fire_switchteam", "开火切换阵营", false)
        SD(RF("杂项", "功能", "ExAdBot", "开火切换阵营"), "开火时立即切换阵营，并刷新定时切换倒计时")
    local switcher_hurt_switchteam_control = gui.Checkbox(RF("杂项", "功能", "ExAdBot"), "exadbot_switcher_hurt_switchteam", "受伤切换阵营", false)
        SD(RF("杂项", "功能", "ExAdBot", "受伤切换阵营"), "自身受到伤害时立即切换阵营，并刷新定时切换倒计时")
    local switcher_primaryweapon_control = gui.Combobox(RF("杂项", "功能", "ExAdBot"), "exadbot_switcher_primaryweapon", "自动购买-主武器", "禁用", "轮询", "大狙", "连狙", "鸟狙")
        SD(RF("杂项", "功能", "ExAdBot", "自动购买-主武器"), "切换阵营时购买主武器；轮询仅在主武器中循环")
    local switcher_secondaryweapon_control = gui.Combobox(RF("杂项", "功能", "ExAdBot"), "exadbot_switcher_secondaryweapon", "自动购买-副武器", "禁用", "轮询", "左轮", "沙鹰")
        SD(RF("杂项", "功能", "ExAdBot", "自动购买-副武器"), "切换阵营时购买副武器；轮询仅在副武器中循环")

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

function SendMsg(spam_onlyteam, msg)
    if spam_onlyteam then
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

local function RequestDisconnect(reason)
    if DisconnectIssued then
        return
    end

    DebugPrint(reason)
    DisconnectIssued = true
    client.Command("disconnect")
end

local function StartAutoMatchmaking()
    panorama.RunScript([[
        $.DispatchEvent("Activated",
            $.GetContextPanel().FindChildTraverse("MainMenuNavBarPlay"),
            "mouse"
        );

        LobbyAPI.StartMatchmaking("", "", "", "");
    ]])
    AutoMatchStarted = true
end

local function SwitchTeam(cur_time, switcher_primaryweapon, switcher_secondaryweapon, reason)
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
        switcher_primaryweapon,
        CurrentPrimaryBuybotOption,
        2,
        4,
        { [2] = "buy awp", [3] = "buy g3sg1;buy scar20", [4] = "buy ssg08" }
    )
    local secondary_buy_command
    secondary_buy_command, CurrentSecondaryBuybotOption = GetBuyCommand(
        switcher_secondaryweapon,
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

LastScoreboardEnable = showscores_enable
client.AllowListener("weapon_fire")
client.AllowListener("player_hurt")
client.AllowListener("player_death")
client.AllowListener("cs_win_panel_match")

callbacks.Register("FireGameEvent", function(e)
    local event_name = e:GetName()
    local local_index = client.GetLocalPlayerIndex()

    if event_name == "cs_win_panel_match" then
        if gui.GetValue("misc.exadbot_autodisconnect") then
            RequestDisconnect("比赛结束：退出当前对局")
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
            local fire_switch_enabled = gui.GetValue("misc.exadbot_switcher_fire_switchteam")
            DebugPrint(string.format("自身开火处理：切换阵营=%s，开火切换=%s",
                tostring(switcher_enable), tostring(fire_switch_enabled)))
            if switcher_enable and fire_switch_enabled then
                SwitchTeam(
                    globals.RealTime(),
                    switcher_primaryweapon,
                    switcher_secondaryweapon,
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
            local hurt_switch_enabled = gui.GetValue("misc.exadbot_switcher_hurt_switchteam")
            DebugPrint(string.format("自身受伤处理：切换阵营=%s，受伤切换=%s",
                tostring(switcher_enable), tostring(hurt_switch_enabled)))
            if switcher_enable and hurt_switch_enabled then
                SwitchTeam(
                    globals.RealTime(),
                    switcher_primaryweapon,
                    switcher_secondaryweapon,
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
        tostring(gui.GetValue("misc.exadbot_kill_throttle"))))

    if not gui.GetValue("misc.exadbot_kill_throttle") then
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
            DeathsSinceKill, kill_throttle_deaths))
        if DeathsSinceKill >= kill_throttle_deaths then
            RestoreKillThrottleState()
            DebugPrint("死亡次数达到设定值：已恢复三项功能")
        end
    end
end)

callbacks.Register("Draw", function()

    cur_time = globals.RealTime()

    spam_enable = gui.GetValue("misc.exadbot_spam_enable")
        spam_onlyteam = gui.GetValue("misc.exadbot_spam_onlyteam")
        spam_speed = gui.GetValue("misc.exadbot_spam_speed")
        spam_msg = gui.GetValue("misc.exadbot_spam_msg")
        spam_onlyteam_control:SetDisabled(not spam_enable)
        spam_speed_control:SetDisabled(not spam_enable)
        spam_msg_control:SetDisabled(not spam_enable)

    showscores_enable = gui.GetValue("misc.exadbot_showscores")

    automatch_enable = gui.GetValue("misc.exadbot_automatch")
        automatch_delay = gui.GetValue("misc.exadbot_automatch_delay")
        automatch_delay_control:SetDisabled(not automatch_enable)

    botdisconnect_enable = gui.GetValue("misc.exadbot_botdisconnect")
        botdisconnect_delay = gui.GetValue("misc.exadbot_botdisconnect_delay")
        botdisconnect_delay_control:SetDisabled(not botdisconnect_enable)

    kill_throttle = gui.GetValue("misc.exadbot_kill_throttle")
        kill_throttle_deaths = gui.GetValue("misc.exadbot_kill_throttle_deaths")
        kill_throttle_deaths_control:SetDisabled(not kill_throttle)

    switcher_enable = gui.GetValue("misc.exadbot_switcher_enable")
        switcher_switchdelay = gui.GetValue("misc.exadbot_switcher_switchdelay")
        switcher_primaryweapon = gui.GetValue("misc.exadbot_switcher_primaryweapon")
        switcher_secondaryweapon = gui.GetValue("misc.exadbot_switcher_secondaryweapon")
        switcher_switchdelay_control:SetDisabled(not switcher_enable)
        switcher_fire_switchteam_control:SetDisabled(not switcher_enable)
        switcher_hurt_switchteam_control:SetDisabled(not switcher_enable)
        switcher_primaryweapon_control:SetDisabled(not switcher_enable)
        switcher_secondaryweapon_control:SetDisabled(not switcher_enable)

    if showscores_enable ~= LastScoreboardEnable then
        client.Command(showscores_enable and "+showscores" or "-showscores")
        LastScoreboardEnable = showscores_enable
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
        RF("杂项", "功能", "ExAdBot", "广告"):SetValue(false)
        RF("杂项", "功能", "ExAdBot", "广告"):SetDisabled(true)
    end

    -- globals.RealTime() 返回的是游戏会话时间, 退出对局后时间会重置为0, 但 LastSendTime 仍保留着上一局的值, 导致 CurrentTime - LastSendTime 为负数
    if cur_time < LastSendTime or cur_time < LastTeamSwitchTime then
        LastSendTime = cur_time
        LastTeamSwitchTime = cur_time
    end

    if cur_time < LastAutoMatchCheckTime then
        LastAutoMatchCheckTime = cur_time
    end

    local local_index = client.GetLocalPlayerIndex()
    local is_in_game = local_index ~= nil and local_index > 0
    local auto_match_enabled = automatch_enable
    if WasInGame and not is_in_game and auto_match_enabled then
        AutoMatchDelayUntil = cur_time + automatch_delay
        DebugPrint(string.format("检测到从对局返回大厅：自动匹配将在%d秒后触发", automatch_delay))
    end
    WasInGame = is_in_game

    if BotDisconnectPendingUntil then
        if cur_time >= BotDisconnectPendingUntil then
            BotDisconnectPendingUntil = nil
            LastAutoMatchCheckTime = cur_time
            local bot_still_present = is_in_game and HasBotPlayer()
            if botdisconnect_enable and bot_still_present then
                RequestDisconnect("Bot退出倒计时结束：对局内仍有Bot，退出当前对局")
            else
                DebugPrint("Bot退出已取消：倒计时结束时选项未开启、已离开对局或Bot已消失")
            end
        end
    elseif cur_time - LastAutoMatchCheckTime >= 1 then
        LastAutoMatchCheckTime = cur_time
        if botdisconnect_enable and is_in_game and not DisconnectIssued and HasBotPlayer() then
            BotDisconnectPendingUntil = cur_time + botdisconnect_delay
            DebugPrint(string.format("检测到Bot：开始%d秒确认倒计时", botdisconnect_delay))
        end
    end

    if is_in_game then
        AutoMatchStarted = false
    elseif DisconnectIssued then
        DisconnectIssued = false
    end

    if not auto_match_enabled then
        AutoMatchStarted = false
        AutoMatchDelayUntil = nil
    elseif not is_in_game and not AutoMatchStarted
        and (AutoMatchDelayUntil == nil or cur_time >= AutoMatchDelayUntil) then
        StartAutoMatchmaking()
        AutoMatchDelayUntil = nil
        DebugPrint("已在大厅触发自动匹配")
    end

    if switcher_enable and cur_time - LastTeamSwitchTime >= switcher_switchdelay then
        SwitchTeam(cur_time, switcher_primaryweapon, switcher_secondaryweapon, "定时")
    end

    if spam_enable and not LastSpamEnable and spam_msg ~= "" then
        SendMsg(spam_onlyteam, spam_msg)
        LastSendTime = cur_time
    end

    if spam_enable and cur_time - LastSendTime >= spam_speed and spam_msg ~= "" then
        SendMsg(spam_onlyteam, spam_msg)
        LastSendTime = cur_time
    end

    LastSpamEnable = spam_enable
end)