function StartMatchmaking()
    panorama.RunScript([[
                $.DispatchEvent("Activated",
                    $.GetContextPanel().FindChildTraverse("MainMenuNavBarPlay"),
                    "mouse"
                );

                LobbyAPI.StartMatchmaking("", "", "", "");
            ]])
end

StartMatchmaking()