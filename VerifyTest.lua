MyUserName = cheat.GetUserName()

print("Your ID is " .. MyUserName)

GITHUB_LIST_URL = "https://raw.githubusercontent.com/XiaoYeCK/aimware_lua/test/UserList"

http.Get(GITHUB_LIST_URL, function(data)

    print(data)

    if not data then return end

    UserList = {}

    for id in string.gmatch(data, '"(.-)"') do
        UserList[id] = true
    end

    if UserList[MyUserName] then
        print("I Love U")
    end
end)