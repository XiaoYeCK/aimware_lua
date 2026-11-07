client.AllowListener("player_hurt")
client.AllowListener("player_connect")
client.AllowListener("player_info")

local player_names = {}

callbacks.Register("FireGameEvent", function(e)
    local en = e:GetName()
    if en == "player_connect" or en == "player_info" then
        local userid = e:GetInt("userid")
        local name = e:GetString("name")
        player_names[userid] = name
    end
end)

callbacks.Register("FireGameEvent", function(e)
    if e:GetName() ~= "player_hurt" then return end

    local vic_uid = e:GetInt("userid")
    local atk_uid = e:GetInt("attacker")
    local hp = e:GetInt("health")
    local dmg = e:GetInt("dmg_health")
    local hitgroup = e:GetInt("hitgroup")
    local weapon = e:GetString("weapon")

    local atk_name = player_names[atk_uid] or "ID:" .. atk_uid
    local vic_name = player_names[vic_uid] or "ID:" .. vic_uid

    -- 部位中文
    local hit = {
        [0] = "全身",
        [1] = "头部",
        [2] = "胸部",
        [3] = "胃部",
        [4] = "左手",
        [5] = "右手",
        [6] = "左腿",
        [7] = "右腿"
    }
    local part = hit[hitgroup] or "部位" .. hitgroup

    -- 修正武器
    local local_idx = client.GetLocalPlayerIndex()
    local me = entities.GetByIndex(local_idx)
    if me and me:IsPlayer() then
        local wid = me:GetWeaponID()
        if wid == 32 then
            weapon = "P2000"
        elseif wid == 61 then
            weapon = "USP-S"
        end
    end

    -- 单行输出
    local line = string.format("%s 使用 %s 击中了 %s 的 %s | 伤害: %d", atk_name, weapon, vic_name, part, dmg)

    -- 血量 >0 才追加
    if hp > 0 then
        line = line .. string.format(" | 剩余血量: %d", hp)
    end

    print(line)
end)
-----
client.AllowListener("player_hurt")

callbacks.Register("FireGameEvent", function(e)
    if e:GetName() ~= "player_hurt" then
        return
    end

    local local_idx = client.GetLocalPlayerIndex()
    local me = entities.GetByIndex(local_idx)

    if me and me:IsPlayer() then
        print("WeaponID: " .. me:GetWeaponID())
    end
end)