local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LocalPlayer = Players.LocalPlayer

local Transceiver = ReplicatedStorage.Remotes.TranciverRemote
local SkillEvent = ReplicatedStorage.Remotes.UseKeyboardSkillRemote

--------------------------------------------------
--// PREVENT DUPLICATE SCRIPT
--------------------------------------------------

if _G.TrapTackleHubRunning then
    return
end

_G.TrapTackleHubRunning = true

--------------------------------------------------
--// SETTINGS
--------------------------------------------------

local TrapEnabled = true
local TackleEnabled = true

local LastTrigger = 0
local TrapCooldown = 0.2

local LastTackle = 0
local TackleCooldown = 0.5

local CLOSE_DISTANCE = 55

local CHECK_INTERVAL = 0.03
local TACKLE_RANGE = 8
local PREDICTION_TIME = 0.12

--------------------------------------------------
--// GUI
--------------------------------------------------

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "TrapTackleHub"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = game:GetService("CoreGui")

local function CreateStatus(name, yPosition, text)
    local Frame = Instance.new("Frame")
    Frame.Name = name
    Frame.Size = UDim2.new(0, 120, 0, 40)
    Frame.Position = UDim2.new(0, 15, 0, yPosition)
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
    Status.Text = text
    Status.TextColor3 = Color3.fromRGB(85, 255, 85)
    Status.Parent = Frame

    return Status
end

local TrapStatus = CreateStatus(
    "TrapStatus",
    15,
    "TRAP: ON"
)

local TackleStatus = CreateStatus(
    "TackleStatus",
    60,
    "TACKLE: ON"
)

--------------------------------------------------
--// GUI UPDATES
--------------------------------------------------

local function UpdateTrapGUI()
    if TrapEnabled then
        TrapStatus.Text = "TRAP: ON"
        TrapStatus.TextColor3 = Color3.fromRGB(85, 255, 85)
    else
        TrapStatus.Text = "TRAP: OFF"
        TrapStatus.TextColor3 = Color3.fromRGB(255, 80, 80)
    end
end

local function UpdateTackleGUI()
    if TackleEnabled then
        TackleStatus.Text = "TACKLE: ON"
        TackleStatus.TextColor3 = Color3.fromRGB(85, 255, 85)
    else
        TackleStatus.Text = "TACKLE: OFF"
        TackleStatus.TextColor3 = Color3.fromRGB(255, 80, 80)
    end
end

--------------------------------------------------
--// F2 / F3 TOGGLES
--------------------------------------------------

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then
        return
    end

    -- F2 = Trap
    if input.KeyCode == Enum.KeyCode.F2 then
        TrapEnabled = not TrapEnabled
        UpdateTrapGUI()

        print("Trap Script:", TrapEnabled and "ON" or "OFF")
    end

    -- F3 = Tackle
    if input.KeyCode == Enum.KeyCode.F3 then
        TackleEnabled = not TackleEnabled
        UpdateTackleGUI()

        print("Tackle Script:", TackleEnabled and "ON" or "OFF")
    end
end)

--------------------------------------------------
--// IFRAME CHECK
--------------------------------------------------

local function hasIFrames(character)
    if not character then
        return false
    end

    return character:FindFirstChild("IFrames") ~= nil
        or character:FindFirstChild("SuperIFrames") ~= nil
end

--------------------------------------------------
--// TRAP SYSTEM
--------------------------------------------------

Transceiver.OnClientEvent:Connect(function(action, player, style, skill, ball)

    if not TrapEnabled then
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

    if os.clock() - LastTrigger < TrapCooldown then
        return
    end

    local MyCharacter = LocalPlayer.Character
    local TheirCharacter = player.Character

    local MyRoot = MyCharacter
        and MyCharacter:FindFirstChild("HumanoidRootPart")

    local TheirRoot = TheirCharacter
        and TheirCharacter:FindFirstChild("HumanoidRootPart")

    if not MyRoot or not TheirRoot then
        return
    end

    LastTrigger = os.clock()

    local Distance =
        (MyRoot.Position - TheirRoot.Position).Magnitude

    if Distance <= CLOSE_DISTANCE then

        Transceiver:FireServer(
            "UseSkill",
            "Creative Trap"
        )

    else

        Transceiver:FireServer(
            "UseSkill",
            "Black Hole Trap"
        )

    end
end)

--------------------------------------------------
--// FIND BALL HOLDER
--------------------------------------------------

local function getBallHolder()

    for _, player in ipairs(Players:GetPlayers()) do

        if player ~= LocalPlayer then

            local character = player.Character

            if character then

                local ballFolder =
                    character:FindFirstChild("Ball")

                if ballFolder then

                    local ball =
                        ballFolder:FindFirstChild("Ball")

                    if ball then
                        return player, character, ball
                    end

                end
            end
        end
    end

    return nil
end

--------------------------------------------------
--// TACKLE
--------------------------------------------------

local function tackle()

    if not TackleEnabled then
        return
    end

    local character = LocalPlayer.Character

    if not character then
        return
    end

    local root =
        character:FindFirstChild("HumanoidRootPart")

    if not root then
        return
    end

    local holder, holderCharacter, ball =
        getBallHolder()

    if not holder
        or not holderCharacter
        or not ball then

        return
    end

    -- Check immediately
    if hasIFrames(holderCharacter) then
        return
    end

    -- Predict ball movement
    local predictedPosition =
        ball.Position
        + (ball.AssemblyLinearVelocity * PREDICTION_TIME)

    if
        (root.Position - predictedPosition).Magnitude
        > TACKLE_RANGE
    then
        return
    end

    -- Cooldown
    if os.clock() - LastTackle < TackleCooldown then
        return
    end

    -- Check again before firing
    if hasIFrames(holderCharacter) then
        return
    end

    LastTackle = os.clock()

    SkillEvent:FireServer(
        "TackleBegin"
    )

    -- Final iframe check
    if hasIFrames(holderCharacter) then
        return
    end

    SkillEvent:FireServer(
        "Tackle",
        ball,
        root.CFrame * CFrame.new(0, -1.5, 0)
    )
end

--------------------------------------------------
--// TACKLE LOOP
--------------------------------------------------

task.spawn(function()

    while _G.TrapTackleHubRunning do

        tackle()

        task.wait(CHECK_INTERVAL)

    end

end)

--------------------------------------------------
--// INITIAL GUI STATE
--------------------------------------------------

UpdateTrapGUI()
UpdateTackleGUI()
