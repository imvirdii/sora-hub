--// =========================================
--// SORA HUB
--// =========================================

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local PunchRemote = Remotes:WaitForChild("PunchRemote")
local TranciverRemote = Remotes:WaitForChild("TranciverRemote")


--// =========================================
--// CLEAN UP OLD SORA HUB
--// =========================================

local OldHub = PlayerGui:FindFirstChild("SoraHub")

if OldHub then
    OldHub:Destroy()
end


--// =========================================
--// SETTINGS
--// =========================================

local LobPassEnabled = false
local TrapListenerEnabled = false

local LobPassDelay = 0.1


--// =========================================
--// UI
--// =========================================

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "SoraHub"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = PlayerGui


local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 280, 0, 175)
MainFrame.Position = UDim2.new(0, 20, 0.5, -87)
MainFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
MainFrame.BorderSizePixel = 0
MainFrame.Parent = ScreenGui


local Corner = Instance.new("UICorner")
Corner.CornerRadius = UDim.new(0, 10)
Corner.Parent = MainFrame


--// TITLE

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, 0, 0, 40)
Title.BackgroundTransparency = 1
Title.Text = "Sora Hub"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.TextSize = 21
Title.Font = Enum.Font.GothamBold
Title.Parent = MainFrame


--// LOB STATUS

local LobStatus = Instance.new("TextLabel")
LobStatus.Size = UDim2.new(1, -20, 0, 30)
LobStatus.Position = UDim2.new(0, 10, 0, 48)
LobStatus.BackgroundTransparency = 1
LobStatus.TextXAlignment = Enum.TextXAlignment.Left
LobStatus.Text = "U - Lob Pass: OFF"
LobStatus.TextColor3 = Color3.fromRGB(220, 220, 220)
LobStatus.TextSize = 14
LobStatus.Font = Enum.Font.Gotham
LobStatus.Parent = MainFrame


--// TRAP STATUS

local TrapStatus = Instance.new("TextLabel")
TrapStatus.Size = UDim2.new(1, -20, 0, 30)
TrapStatus.Position = UDim2.new(0, 10, 0, 82)
TrapStatus.BackgroundTransparency = 1
TrapStatus.TextXAlignment = Enum.TextXAlignment.Left
TrapStatus.Text = "F - Trap Listener: OFF"
TrapStatus.TextColor3 = Color3.fromRGB(220, 220, 220)
TrapStatus.TextSize = 14
TrapStatus.Font = Enum.Font.Gotham
TrapStatus.Parent = MainFrame


--// INFO

local Info = Instance.new("TextLabel")
Info.Size = UDim2.new(1, -20, 0, 30)
Info.Position = UDim2.new(0, 10, 0, 125)
Info.BackgroundTransparency = 1
Info.TextXAlignment = Enum.TextXAlignment.Left
Info.TextColor3 = Color3.fromRGB(150, 150, 150)
Info.TextSize = 12
Info.Font = Enum.Font.Gotham
Info.Text = "U = Lob Pass     F = Traps"
Info.Parent = MainFrame


--// =========================================
--// UI FUNCTIONS
--// =========================================

local function UpdateLobStatus()

    if LobPassEnabled then

        LobStatus.Text = "U - Lob Pass: ON"
        LobStatus.TextColor3 = Color3.fromRGB(100, 255, 100)

    else

        LobStatus.Text = "U - Lob Pass: OFF"
        LobStatus.TextColor3 = Color3.fromRGB(220, 220, 220)

    end

end


local function UpdateTrapStatus()

    if TrapListenerEnabled then

        TrapStatus.Text = "F - Trap Listener: ON"
        TrapStatus.TextColor3 = Color3.fromRGB(100, 255, 100)

    else

        TrapStatus.Text = "F - Trap Listener: OFF"
        TrapStatus.TextColor3 = Color3.fromRGB(220, 220, 220)

    end

end


--// =========================================
--// LOB PASS
--// =========================================

task.spawn(function()

    while ScreenGui.Parent do

        if LobPassEnabled then

            for _, instance in ipairs(workspace:GetChildren()) do

                PunchRemote:FireServer(
                    "LobPass",
                    instance,
                    Vector3.new(2000, 36000, 300)
                )

            end

        end

        task.wait(LobPassDelay)

    end

end)


--// =========================================
--// TRAP LISTENER
--// =========================================

local TrapConnection

TrapConnection = TranciverRemote.OnClientEvent:Connect(function(
    action,
    player,
    style,
    skill,
    ball
)

    if not TrapListenerEnabled then
        return
    end


    -- Creative Trap

    if player ~= LocalPlayer
        and action == "Hold"
        and (
            skill == "Impact Shot"
            or skill == "Explosive Kick"
        ) then

        TranciverRemote:FireServer(
            "UseSkill",
            "Creative Trap"
        )

    end


    -- Black Hole Trap

    if player ~= LocalPlayer
        and action == "UseSkill"
        and skill == "Impact Bicycle" then

        TranciverRemote:FireServer(
            "UseSkill",
            "Black Hole Trap"
        )

    end

end)


--// =========================================
--// KEYBINDS
--// =========================================

local InputConnection

InputConnection = UserInputService.InputBegan:Connect(function(
    input,
    gameProcessed
)

    -- Don't let the game block the toggle
    if input.KeyCode == Enum.KeyCode.F then

        TrapListenerEnabled = not TrapListenerEnabled

        UpdateTrapStatus()

        return
    end


    if input.KeyCode == Enum.KeyCode.U then

        LobPassEnabled = not LobPassEnabled

        UpdateLobStatus()

        return
    end

end)


--// =========================================
--// CLEANUP
--// =========================================

ScreenGui.Destroying:Connect(function()

    if InputConnection then
        InputConnection:Disconnect()
    end

    if TrapConnection then
        TrapConnection:Disconnect()
    end

end)


--// =========================================
--// INITIAL STATE
--// =========================================

UpdateLobStatus()
UpdateTrapStatus()
