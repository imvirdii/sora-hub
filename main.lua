local Rayfield = loadstring(game:HttpGet("https://sirius.menu/gen2"))()

local window = Rayfield:CreateWindow({
    name = "Sora Hub",
    subtitle = "fuck u mamaguevo",
    sidebarLayout = true,
    theme = "cobalt",
})

local tab = window:CreateTab({ name = "the good stuff", icon = 93364949241311 })

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

    description = "Automatically activates Creative Trap and Black Hole Trap. Keybind: F",

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
