local userName = cheat.GetUserName()

print("Your ID is " .. userName)

local GITHUB_LIST_URL = "https://raw.githubusercontent.com/XiaoYeCK/aimware_lua/main/UserList"

http.Get(GITHUB_LIST_URL, function(data)

    print(data)

    if not data then return end

    local userList = {}

    for id in string.gmatch(data, '"(.-)"') do
        userList[id] = true
    end

    if userList[userName] then
        print("I Love U")
    end
end)
