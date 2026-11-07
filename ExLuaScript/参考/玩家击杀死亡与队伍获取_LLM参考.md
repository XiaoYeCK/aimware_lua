# 玩家击杀、死亡与队伍获取（LLM 参考）

以下代码展示通过 `player_death` 事件统计玩家击杀和死亡，以及读取玩家队伍编号的关键方式。

## 统计数据初始化

```lua
local global_stats = {}

-- 此项目使用 0-63 作为玩家 UserID 的统计表索引范围
for userid = 0, 63 do
    global_stats[userid] = {
        kills = 0,
        deaths = 0
    }
end
```

## 监听击杀与死亡事件

```lua
client.AllowListener("player_death")

callbacks.Register("FireGameEvent", function(e)
    if e:GetName() ~= "player_death" then
        return
    end

    local victim_userid = e:GetInt("userid")
    local attacker_userid = e:GetInt("attacker")

    -- 游戏事件中的 UserID 转换为实体索引时需要加 1
    local victim_controller = victim_userid
        and entities.GetByIndex(victim_userid + 1)
        or nil

    -- 受害者有效时累计死亡；自杀和世界击杀也仍然会计入死亡
    if victim_controller then
        local ok_class, class = pcall(function()
            return victim_controller:GetClass()
        end)

        if ok_class and class == "CCSPlayerController" then
            local stats = global_stats[victim_userid]
            if stats then
                stats.deaths = stats.deaths + 1
            end
        end
    end

    -- 自杀不计击杀；无效击杀者也不进入击杀统计
    if not attacker_userid or attacker_userid == victim_userid then
        return
    end

    local attacker_controller = entities.GetByIndex(attacker_userid + 1)
    if attacker_controller then
        local ok_class, class = pcall(function()
            return attacker_controller:GetClass()
        end)

        if ok_class and class == "CCSPlayerController" then
            local stats = global_stats[attacker_userid]
            if stats then
                stats.kills = stats.kills + 1
            end
        end
    end
end)
```

## 获取玩家队伍编号

```lua
local function GetPlayerTeamNum(userid)
    local controller = entities.GetByIndex(userid + 1)
    if not controller then
        return 0
    end

    local ok, team = pcall(function()
        return controller:GetFieldInt("m_iTeamNum")
    end)

    return (ok and team) and team or 0
end
```

在此项目中，队伍编号 `2` 表示 T，`3` 表示 CT；无法读取或实体不存在时函数返回 `0`。

## 使用要点

- `player_death` 事件的 `userid` 是受害者，`attacker` 是击杀者。
- 用事件 UserID 查询实体时，调用 `entities.GetByIndex(userid + 1)`。
- 先检查实体存在，并确认 `GetClass()` 为 `CCSPlayerController`，再读取字段或更新统计。
- 死亡计数独立于击杀者有效性；自杀或世界击杀仍可增加受害者死亡数，但不会增加玩家击杀数。
