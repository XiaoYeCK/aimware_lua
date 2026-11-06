RF = gui.Reference

LastSendTime = 0
LastTeamSwitchTime = 0
CurrentTeam = 2
CurrentPrimaryBuybotOption = 2
CurrentSecondaryBuybotOption = 2
LastSpamEnable = false

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

gui.Text(RF("杂项", "功能"), "----------------------------- 刷屏 -----------------------------")

    gui.Checkbox(RF("杂项", "功能"), "advanced_spam_enable", "开关", false)
        SD(RF("杂项", "功能", "开关"), "启用刷屏")
    gui.Checkbox(RF("杂项", "功能"), "advanced_spam_onlyteam", "仅队内", false)
        SD(RF("杂项", "功能", "仅队内"), "仅队内刷屏")

    gui.Checkbox(RF("杂项", "功能"), "advanced_spam_admode_switchteam", "切换阵营", false)
        SD(RF("杂项", "功能", "切换阵营"), "自动切换阵营")
    gui.Slider(RF("杂项", "功能"), "advanced_spam_admode_switchdelay", "切换间隔", 1.5, 0.1, 30.0, 0.5)
        SD(RF("杂项", "功能", "切换间隔"), "单位: 秒")
    gui.Combobox(RF("杂项", "功能"), "advanced_spam_admode_primaryweapon", "自动购买-主武器", "禁用", "轮询", "大狙", "连狙", "鸟狙")
        SD(RF("杂项", "功能", "自动购买-主武器"), "切换阵营时购买主武器；轮询仅在主武器中循环")
    gui.Combobox(RF("杂项", "功能"), "advanced_spam_admode_secondaryweapon", "自动购买-副武器", "禁用", "轮询", "左轮", "沙鹰")
        SD(RF("杂项", "功能", "自动购买-副武器"), "切换阵营时购买副武器；轮询仅在副武器中循环")
    gui.Checkbox(RF("杂项", "功能"), "advanced_spam_admode_showscores", "显示计分板", false)
        SD(RF("杂项", "功能", "显示计分板"), "启用时按住计分板")

    gui.Slider(RF("杂项", "功能"), "advanced_spam_speed", "发送间隔", 0.5, 0.5, 60.0, 0.5)
        SD(RF("杂项", "功能", "发送间隔"), "单位: 秒")
    gui.Editbox(RF("杂项", "功能"), "advanced_spam_msg", "内容")

callbacks.Register("Draw", function()

    cur_time = globals.RealTime()

    enable = gui.GetValue("misc.advanced_spam_enable")
    team_only = gui.GetValue("misc.advanced_spam_onlyteam")
    admode = gui.GetValue("misc.advanced_spam_admode_switchteam")
    team_delay = gui.GetValue("misc.advanced_spam_admode_switchdelay")
    primary_weapon_option = gui.GetValue("misc.advanced_spam_admode_primaryweapon")
    secondary_weapon_option = gui.GetValue("misc.advanced_spam_admode_secondaryweapon")
    scoreboard_enable = gui.GetValue("misc.advanced_spam_admode_showscores")
    send_speed = gui.GetValue("misc.advanced_spam_speed")
    msg = gui.GetValue("misc.advanced_spam_msg")

    if gui.GetValue("misc.chatspam") then
        RF("杂项", "功能", "广告"):SetValue(false)
        gui.SetValue("misc.master", true)
        gui.SetValue("misc.log.console", true)
    end

    -- globals.RealTime() 返回的是游戏会话时间, 退出对局后时间会重置为0, 但 LastSendTime 仍保留着上一局的值, 导致 CurrentTime - LastSendTime 为负数
    if cur_time < LastSendTime or cur_time < LastTeamSwitchTime then
        LastSendTime = cur_time
        LastTeamSwitchTime = cur_time
    end

    if admode and cur_time - LastTeamSwitchTime >= team_delay then
        CurrentTeam = CurrentTeam == 2 and 3 or 2
        local buy_commands = {
            "jointeam " .. CurrentTeam,
            "cl_dm_buyrandomweapons 0",
            scoreboard_enable and "+showscores" or "-showscores"
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
        client.Command(table.concat(buy_commands, ";"))
        LastTeamSwitchTime = cur_time
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