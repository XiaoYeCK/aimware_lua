local text = {
    "高刷显示器",
    "广州打外地",
    "高敏手感好",
    "磁轴停的快",
    "昨天睡得早",
    "而且没有导",
    "高帧打低帧",
    "反正不是挂",
    "总之别尬黑",
    "#压制 #手法 #绝境",
    "#突破 #自我 #证明",
    "#巅峰 #枷锁 #答案",
    "#依赖 #尽头 #诠释",
    "#冷静 #逆境 #自信",
    "#无限 #打破 #困局",
    "#质疑 #逆转 #磨炼",
    "#极限 #止步 #假象",
    "#结果 #终将 #问鼎",
    "#冷静 #挣脱 #限制",
    "#领域 #绝巅 #过去",
    "#诀别 #回忆 #束缚",
    "#破镜 #零碎 #绝劣",
    "#缺口 #细节 #天赋",
    "#专注 #预判 #反打",
    "#磨砺 #成长 #蜕变",
    "#执着 #突破 #登顶",
    "#独立 #觉醒 #绽放",
    "#沉稳 #翻盘 #信念",
    "#潜能 #开拓 #新生",
    "#坚持 #逆袭 #成长",
    "#超越 #局限 #真相",
    "#汗水 #梦想 #加冕",
    "#理智 #突围 #自由",
    "#深耕 #极致 #未来",
    "#告别 #过往 #前行",
    "#重塑 #完整 #卓越",
    "#填补 #精准 #闪耀",
}

local say_delay = 1
local current_index = 1
local last_say_time = 0
local all_messages_sent = false

local function SayNext()
    local current_time = globals.CurTime()
    
    if current_time - last_say_time >= say_delay then
        client.ChatSay(text[current_index])
        current_index = current_index + 1

        if current_index > #text then
            all_messages_sent = true
            UnloadScript("自动发言-没开.lua")
        end
        
        last_say_time = current_time
    end
end

callbacks.Register("Draw", SayNext)

