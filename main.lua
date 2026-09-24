local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local Event = game:GetService("ReplicatedStorage").Remotes.TranciverRemote

local LocalPlayer = Players.LocalPlayer

if _G.TrapScriptRunning then
    return
end

_G.TrapScriptRunning = true

local Enabled = true

local LastTrigger = 0
local Cooldown = 0.2
local CLOSE_DISTANCE = 55

--// GUI
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "TrapStatusGui"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = game:GetService("CoreGui")

local Frame = Instance.new("Frame")
Frame.Size = UDim2.new(0, 120, 0, 40)
Frame.Position = UDim2.new(0, 15, 0, 15)
Frame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
Frame.BorderSizePixel = 0
Frame.Parent = ScreenGui

local Corner = Instance.new("UICorner")
Corner.CornerRadius = UDim.new(0, 8)
Corner.Parent = Frame

local Status = Instance.new("TextLabel")
Status.Size = UDim2.new(1, 0, 1, 0)
Status.BackgroundTransparency = 1
Status.Font = Enum.Font.GothamBold
Status.TextSize = 16
Status.Text = "TRAP: ON"
Status.TextColor3 = Color3.fromRGB(85, 255, 85)
Status.Parent = Frame

local function UpdateGUI()
    if Enabled then
        Status.Text = "TRAP: ON"
        Status.TextColor3 = Color3.fromRGB(85, 255, 85)
    else
        Status.Text = "TRAP: OFF"
        Status.TextColor3 = Color3.fromRGB(255, 80, 80)
    end
end

--// F2 Toggle
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then
        return
    end

    if input.KeyCode == Enum.KeyCode.F2 then
        Enabled = not Enabled
        UpdateGUI()

        print("Trap Script:", Enabled and "ON" or "OFF")
    end
end)

--// Trap detection
Event.OnClientEvent:Connect(function(action, player, style, skill, ball)

    if not Enabled then
        return
    end

    if action ~= "Hold" then
        return
    end

    if player == LocalPlayer then
        return
    end

    if skill ~= "Impact Shot" and skill ~= "Explosive Kick" then
        return
    end

    if os.clock() - LastTrigger < Cooldown then
        return
    end

    local MyCharacter = LocalPlayer.Character
    local TheirCharacter = player.Character

    local MyRoot = MyCharacter and MyCharacter:FindFirstChild("HumanoidRootPart")
    local TheirRoot = TheirCharacter and TheirCharacter:FindFirstChild("HumanoidRootPart")

    if not MyRoot or not TheirRoot then
        return
    end

    LastTrigger = os.clock()

    local Distance = (MyRoot.Position - TheirRoot.Position).Magnitude

    if Distance <= CLOSE_DISTANCE then
        Event:FireServer(
            "UseSkill",
            "Creative Trap"
        )
    else
        Event:FireServer(
            "UseSkill",
            "Black Hole Trap"
        )
    end
end)
