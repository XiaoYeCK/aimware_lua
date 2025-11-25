local text = {
    "没挂就别叫",
    "有挂就得开",
    "开挂已是无敌路",
    "何须再用技术补",
    "开挂有路你不走",
    "绿玩无门你自来投",
    "强者总会被针对",
    "练枪是小径",
    "自瞄是大道",
    "意识会出错",
    "开挂秒全场",
    "不要问为什么开挂",
    "因为你已经习惯愚蠢",
    "开挂者人均天资聪颖",
    "真正的高手",
    "都善于走捷径",
    "当绿玩被无情击败",
    "才会明白",
    "他们离成功只差一个软件",
    "苦海无涯回头是挂",
    "外挂就是最踏实的那条路",
    "趁现在开挂还来得及",
    "什么你也要开挂?",
    "那赶紧加Q群获取啊",
    "加入我们 I 1038569891",
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
            UnloadScript("自动发言-开.lua")
        end
        
        last_say_time = current_time
    end
end

callbacks.Register("Draw", SayNext)
