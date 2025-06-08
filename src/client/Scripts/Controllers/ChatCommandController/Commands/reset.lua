local Players = game:GetService("Players")

local command = {}

command = {
    Name = "reset",
    Permissions = "All",
    RawCommand = "!reset"
}

function command:Execute()
    local playerIndicator = Players.LocalPlayer.PlayerGui:WaitForChild("DamageStats")
    playerIndicator.Frame.Damage.Text = "0"
    return true
end

return command