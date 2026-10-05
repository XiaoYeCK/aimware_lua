RF=gui.Reference

function DumpGUI()
    output = ""

    function traverse(obj, prefix)
        output = output .. prefix .. obj:GetName() .. "\n"
        for child in obj:Children() do
            traverse(child, prefix .. "\t")
        end
    end

    traverse(RF(), "")

    return output
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
    return NonASCII(DumpGUI())
end

if CheckTranslated() then
    translated = true
else
    translated = false
end

function TranslatedOutput(chinese, english)
    local text = translated and chinese or english
    local results = {}

    for value in string.gmatch(text, "([^,]+)") do
        value = string.gsub(value, "^%s+", "")
        value = string.gsub(value, "%s+$", "")

        value = string.gsub(value, "^'", "")
        value = string.gsub(value, "'$", "")

        table.insert(results, value)
    end

    return unpack(results)
end

ref = gui.Reference(
    TranslatedOutput("'杂项', '功能'", "'Miscellaneous', 'Features'")
)

ex_indicator = gui.Multibox(ref, TranslatedOutput("增强指示器", "ExIndicator"))

items_parent = ex_indicator or ref

ind_ragebot  = gui.Checkbox(items_parent, "mi_ragebot",  TranslatedOutput("暴力", "Ragebot"),  false)
ind_legitbot = gui.Checkbox(items_parent, "mi_legitbot", TranslatedOutput("合法", "Legitbot"), false)
ind_seed     = gui.Checkbox(items_parent, "mi_seed",     TranslatedOutput("种子", "Seed"),     false)
ind_fns      = gui.Checkbox(items_parent, "mi_fns",      TranslatedOutput("无扩散", "FNS"),      false)
ind_aw       = gui.Checkbox(items_parent, "mi_aw",       TranslatedOutput("扳机穿墙", "Triggerbot Auto Wall"), false)
ind_ts       = gui.Checkbox(items_parent, "mi_ts",       TranslatedOutput("扳机穿烟", "Triggerbot Through Smoke"), false)

local cp_ragebot  = gui.ColorPicker(ind_ragebot,  "mi_ragebot_color",  "Color", 145, 196, 68, 255)
local cp_legitbot = gui.ColorPicker(ind_legitbot, "mi_legitbot_color", "Color", 145, 196, 68, 255)
local cp_seed     = gui.ColorPicker(ind_seed,     "mi_seed_color",     "Color", 145, 196, 68, 255)
local cp_fns      = gui.ColorPicker(ind_fns,      "mi_fns_color",      "Color", 145, 196, 68, 255)
local cp_aw       = gui.ColorPicker(ind_aw,       "mi_aw_color",       "Color", 145, 196, 68, 255)
local cp_ts       = gui.ColorPicker(ind_ts,       "mi_ts_color",       "Color", 145, 196, 68, 255)

local ind_scale    = gui.Slider(ref, "mi_scale", TranslatedOutput("指示器大小", "Indicator Size"), 1.0, 0.5, 2.0, 0.05)

local function truthy(v)
    return v ~= nil and v ~= false and v ~= 0
end

local function safe_get(varname)
    local ok, v = pcall(gui.GetValue, varname)
    if not ok then return nil end
    return v
end

local WEAPON_FRAGMENTS = {
    ["Shared"]           = "shared",
    ["Zeus"]             = "zeus",
    ["Pistol"]           = "pistol",
    ["Heavy Pistol"]     = "hpistol",
    ["Submachine Gun"]   = "smg",
    ["Rifle"]            = "rifle",
    ["Shotgun"]          = "shotgun",
    ["Scout"]            = "scout",
    ["Auto Sniper"]      = "asniper",
    ["Sniper"]           = "sniper",
    ["Light Machine Gun"] = "lmg",
}

local ANTISPREAD_PATHS = {
    shared  = "lbot.trg.weapon.shared.antispreadtype",
    zeus    = "lbot.trg.weapon.zeus.antispreadtype",
    pistol  = "lbot.trg.weapon.pistol.antispreadtype",
    hpistol = "lbot.trg.weapon.hpistol.antispreadtype",
    smg     = "lbot.trg.weapon.smg.antispreadtype",
    rifle   = "lbot.trg.weapon.rifle.antispreadtype",
    shotgun = "lbot.trg.weapon.shotgun.antispreadtype",
    scout   = "lbot.trg.weapon.scout.antispreadtype",
    asniper = "lbot.trg.weapon.asniper.antispreadtype",
    sniper  = "lbot.trg.weapon.sniper.antispreadtype",
    lmg     = "lbot.trg.weapon.lmg.antispreadtype",
}
local AUTOWALL_PATHS = {
    shared  = "lbot.trg.vis.shared.autowall",
    zeus    = "lbot.trg.vis.zeus.autowall",
    pistol  = "lbot.trg.vis.pistol.autowall",
    hpistol = "lbot.trg.vis.hpistol.autowall",
    smg     = "lbot.trg.vis.smg.autowall",
    rifle   = "lbot.trg.vis.rifle.autowall",
    shotgun = "lbot.trg.vis.shotgun.autowall",
    scout   = "lbot.trg.vis.scout.autowall",
    asniper = "lbot.trg.vis.asniper.autowall",
    sniper  = "lbot.trg.vis.sniper.autowall",
    lmg     = "lbot.trg.vis.lmg.autowall",
}
local SMOKE_PATHS = {
    shared  = "lbot.trg.vis.shared.smoke",
    zeus    = "lbot.trg.vis.zeus.smoke",
    pistol  = "lbot.trg.vis.pistol.smoke",
    hpistol = "lbot.trg.vis.hpistol.smoke",
    smg     = "lbot.trg.vis.smg.smoke",
    rifle   = "lbot.trg.vis.rifle.smoke",
    shotgun = "lbot.trg.vis.shotgun.smoke",
    scout   = "lbot.trg.vis.scout.smoke",
    asniper = "lbot.trg.vis.asniper.smoke",
    sniper  = "lbot.trg.vis.sniper.smoke",
    lmg     = "lbot.trg.vis.lmg.smoke",
}

local function get_weapon_fragment()
    local w = safe_get("lbot.trg.weapon")
    if type(w) == "string" then
        local s = (w:gsub('"', "")):gsub("^%s+", ""):gsub("%s+$", "")
        return WEAPON_FRAGMENTS[s]
    end
    return nil
end

local function is_knife()
    local ok, id = pcall(function() return entities.GetLocalPlayer():GetWeaponID() end)
    if not ok or id == nil then return false end
    return id == 42 or id == 59 or (id >= 500 and id <= 527)
end

local function legit_mode()
    return truthy(safe_get("lbot.master")) and not truthy(safe_get("rbot.master"))
end

local function get_seed_fns()
    if is_knife() then return nil end
    if truthy(safe_get("rbot.master")) then
        local v = safe_get("rbot.antispread")
        if v == 2 then return "Seed" end
        if v == 1 then return "FNS" end
        return nil
    end
    if legit_mode() and truthy(safe_get("lbot.trg.enable")) then
        local frag = get_weapon_fragment()
        if frag then
            local v = safe_get(ANTISPREAD_PATHS[frag])
            if v == 1 then return "Seed" end
            if v == 2 then return "FNS" end
        end
        return nil
    end
    return nil
end

local WEAPON_GROUP_IDS = {
    [2] = "pistol",  [3] = "pistol",  [4] = "pistol",  [23] = "pistol",
    [30] = "pistol", [32] = "pistol", [61] = "pistol", [63] = "pistol",
    [1] = "hpistol", [64] = "hpistol",
    [17] = "smg",  [19] = "smg",  [24] = "smg",  [26] = "smg",  [33] = "smg",  [34] = "smg",
    [7] = "rifle", [8] = "rifle", [10] = "rifle", [13] = "rifle", [16] = "rifle", [27] = "rifle", [60] = "rifle",
    [25] = "shotgun", [29] = "shotgun", [35] = "shotgun", [39] = "shotgun",
    [40] = "scout",
    [11] = "asniper", [38] = "asniper",
    [9]  = "sniper",
    [14] = "lmg", [28] = "lmg",
    [31] = "zeus",
}

local function get_held_fragment()
    local ok, id = pcall(function() return entities.GetLocalPlayer():GetWeaponID() end)
    if not ok or id == nil then return nil end
    return WEAPON_GROUP_IDS[id]
end

local function get_trg_vis(paths)
    if is_knife() then return false end
    if not legit_mode() then return false end
    if not truthy(safe_get("lbot.trg.enable")) then return false end
    local frag = get_held_fragment()
    if not frag then return false end
    return truthy(safe_get(paths[frag]))
end

local DEFINITIONS = {
    { cb = ind_ragebot,  cp = cp_ragebot,  label = "Ragebot",  cond = function() return truthy(safe_get("rbot.master")) end },
    { cb = ind_legitbot, cp = cp_legitbot, label = "Legitbot", cond = function() return truthy(safe_get("lbot.master")) end },
    { cb = ind_seed,     cp = cp_seed,     label = "Seed",     cond = function() return get_seed_fns() == "Seed" end },
    { cb = ind_fns,      cp = cp_fns,      label = "FNS",      cond = function() return get_seed_fns() == "FNS" end },
    { cb = ind_aw,       cp = cp_aw,       label = "AW",       cond = function() return get_trg_vis(AUTOWALL_PATHS) end },
    { cb = ind_ts,       cp = cp_ts,       label = "TS",       cond = function() return get_trg_vis(SMOKE_PATHS) end },
}

local anim = {}
local smooth_y = nil
local BASE_FONT = 13
local cached_font, cached_size = nil, nil
local function get_font(size)
    if cached_font == nil or cached_size ~= size then
        cached_font = draw.CreateFont("Segoe UI", size, 700)
        cached_size = size
    end
    return cached_font
end

local BASE_FADE = 10
local SLICES    = 10
local BASE_H    = 22
local BASE_GAP  = 4
local BASE_PAD  = 4
local function draw_plate(xr, y, w, h, fade, a)
    local total = w + fade * 2
    local x0 = xr - total + (1 - a) * total
    for i = 0, SLICES - 1 do
        local t = (i + 1) / SLICES
        draw.Color(15, 15, 15, math.floor(140 * a * t))
        draw.FilledRect(x0 + fade * (i / SLICES), y, x0 + fade * t, y + h)
    end
    draw.Color(15, 15, 15, math.floor(140 * a))
    draw.FilledRect(x0 + fade, y, x0 + fade + w, y + h)
    for i = 0, SLICES - 1 do
        local t = i / SLICES
        draw.Color(15, 15, 15, math.floor(140 * a * (1 - t)))
        draw.FilledRect(x0 + fade + w + fade * t, y, x0 + fade + w + fade * ((i + 1) / SLICES), y + h)
    end
    return x0 + fade
end

callbacks.Register("Draw", "MoreIndicator_Draw", function()
    local ok, err = pcall(function()
        local ok_me, me = pcall(entities.GetLocalPlayer)
        if not ok_me or me == nil then return end
        local ok_hp, hp = pcall(function() return me:GetHealth() end)
        if not ok_hp or type(hp) ~= "number" or hp <= 0 then return end
        local sw, sh = draw.GetScreenSize()
        if not sw or not sh then return end
        local scale = ind_scale:GetValue()
        local fsize = math.max(6, math.floor(BASE_FONT * scale + 0.5))
        local fade  = math.floor(BASE_FADE * scale)
        local row_h = math.floor(BASE_H * scale)
        local gap   = math.floor(BASE_GAP * scale)
        local pad   = math.floor(BASE_PAD * scale)
        draw.SetFont(get_font(fsize))
        local xr = sw - 6
        local visible, total_h = {}, 0
        for _, def in ipairs(DEFINITIONS) do
            local target = (def.cb:GetValue() and def.cond()) and 1 or 0
            anim[def.label] = (anim[def.label] or 0) + (target - (anim[def.label] or 0)) * 0.15
            local a = anim[def.label]
            if a > 0.01 then
                local tw, th = draw.GetTextSize(def.label)
                visible[#visible + 1] = { def = def, a = a, tw = tw, th = th }
                total_h = total_h + row_h + gap
            end
        end
        if #visible == 0 then return end
        total_h = total_h - gap
        local target_y = (sh - total_h) / 2
        if smooth_y == nil then smooth_y = target_y end
        smooth_y = smooth_y + (target_y - smooth_y) * 0.12
        local y = math.floor(smooth_y)
        for _, it in ipairs(visible) do
            local def, a, tw, th = it.def, it.a, it.tw, it.th
            local w = tw + pad * 2
            local solid_x = draw_plate(xr, y, w, row_h, fade, a)
            local c_r, c_g, c_b, c_a = 145, 196, 68, 255
            if def.cp then
                c_r, c_g, c_b, c_a = def.cp:GetValue()
            end
            draw.Color(c_r, c_g, c_b, math.floor(c_a * a))
            draw.Text(solid_x + pad, y + math.floor((row_h - th) / 2) - math.floor(fsize * 0.15), def.label)

            y = y + row_h + gap
        end
    end)
    if not ok then
        print("[MoreIndicator] Draw error: " .. tostring(err))
    end
end)

callbacks.Register("Unload", "MoreIndicator_Unload", function()
    callbacks.Unregister("Draw", "MoreIndicator_Draw")
end)
