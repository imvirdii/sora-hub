local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LocalPlayer = Players.LocalPlayer
local Event = ReplicatedStorage.Remotes:WaitForChild("TranciverRemote")

local AutoTrap = false


--// =========================================
--// AUTO TRAP
--// =========================================

Event.OnClientEvent:Connect(function(
    action,
    player,
    style,
    skill,
    ball
)

    if not AutoTrap then
        return
    end


    -- Creative Trap
    if player ~= LocalPlayer
        and action == "Hold"
        and (
            skill == "Impact Shot"
            or skill == "Explosive Kick"
        ) then

        Event:FireServer(
            "UseSkill",
            "Creative Trap"
        )

    end


    -- Black Hole Trap
    if player ~= LocalPlayer
        and action == "UseSkill"
        and skill == "Impact Bicycle" then

        Event:FireServer(
            "UseSkill",
            "Black Hole Trap"
        )

    end

end)


--// =========================================
--// RAYFIELD TOGGLE
--// =========================================

local autoTrap = tab:CreateToggle({

    name = "Auto Trap",

    description = "Automatically activates Creative Trap and Black Hole Trap.",

    flag = "AutoTrap",

    value = false,

    callback = function(value)

        AutoTrap = value

        print("Auto Trap:", value)

    end,
})


--// =========================================
--// F KEY TOGGLE
--// =========================================

UserInputService.InputBegan:Connect(function(
    input,
    gameProcessed
)

    if gameProcessed then
        return
    end


    -- Don't activate while typing
    if UserInputService:GetFocusedTextBox() then
        return
    end


    if input.KeyCode == Enum.KeyCode.F then

        autoTrap:Set(not autoTrap.value)

    end

end)
