callbacks.Register("Draw", function() end)-- 为了随参数加载脚本, 保持脚本加载

ScriptName = GetScriptName()

LuaCheckURL = "https://raw.githubusercontent.com/XiaoYeCK/aimware_lua/refs/heads/test/ExampleLoader.lua"

TargetName = "ExampleLoader.lua"

Space = " "

function NewPrint(...)
    gui.SetValue("misc.master", true)
    gui.SetValue("misc.log.console", true)
    print(..., Enter)
end

if ScriptName ~= TargetName then
    CurrentScript = file.Read(ScriptName)
    file.Write(TargetName, CurrentScript)
    file.Delete(ScriptName)
    NewPrint("脚本已重命名为:" .. Space .. TargetName)
    NewPrint("请刷新脚本列表后手动重载")
    -- 已加载脚本文件名和改动后不一致无法自行重载，若一致则可以
    -- 后续可以识别是否是TargetName，如果原名称和TargetName一致直接重载，不一致才提示刷新列表手动重载
end

function FetchURL(url)
    FetchData = http.Get(url)

    if not FetchData then
        NewPrint("请求失败:" .. Space .. url)
        return false
    end

    return FetchData
end

function CompareWithOnline(localText, url)
    remote = FetchURL(url)

    if not remote then
        return "Skip"
    end

    -- 移除换行和空格再检查一致性
    cleanLocal = localText:gsub("[\n\r\t ]", "")
    cleanRemote = remote:gsub("[\n\r\t ]", "")
    
    if cleanRemote ~= cleanLocal then
        return false
    end
    return true
end

function ValidateOnline()
    localScript = file.Read(ScriptName)

    LuaResult = CompareWithOnline(localScript, LuaCheckURL)
    if LuaResult == "Skip" then
        return false
    elseif LuaResult == false then
        NewPrint("同步在线脚本")
        LuaData = FetchURL(LuaCheckURL)
        if not LuaData then
            NewPrint("无法获取在线脚本, 请检查网络连接")
            return false
        end
            file.Write(ScriptName, LuaData)
            LoadScript(ScriptName)
    end
        return true
end

function CorePayload()
    NewPrint("已加载脚本")
end

if ValidateOnline() then
    CorePayload()
else
    NewPrint("已阻止加载")
end