MyUserName = cheat.GetUserName()

-- DEBUG: Print your ID to console
print("Your ID is " .. MyUserName)

GITHUB_LIST_URL = "https://raw.githubusercontent.com/XiaoYeCK/aimware_lua/test/UserList"

http.Get(GITHUB_LIST_URL, function(data)

    --- DEBUG: Print the data received from GitHub to console
    print(data)

    if not data then return end

    UserList = {}

    for id in string.gmatch(data, '"(.-)"') do
        UserList[id] = true
    end

    if UserList[MyUserName] then
        --- DEBUG: Print a message to console if the user is verified
        print("I LOVE U")
    else
        --- DEBUG: Print a message to console if the user is not verified
        print("FUCK U LOSER")
    end
end)