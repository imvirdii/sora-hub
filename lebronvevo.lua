local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LocalPlayer = Players.LocalPlayer

local Transceiver =
    ReplicatedStorage.Remotes.TranciverRemote

--------------------------------------------------
--// PREVENT DUPLICATE
--------------------------------------------------

if _G.AutoTrapOnlyRunning then
    return
end

_G.AutoTrapOnlyRunning = true

--------------------------------------------------
--// SETTINGS
--------------------------------------------------

local AutoTrapEnabled = true

local LastTrigger = 0
local TrapCooldown = 0.2

local LastBicycleTrap = 0
local BicycleTrapCooldown = 0.05

local CLOSE_DISTANCE = 125

--------------------------------------------------
--// GUI
--------------------------------------------------

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "AutoTrapHub"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = game:GetService("CoreGui")

--------------------------------------------------
--// STATUS LABEL
--------------------------------------------------

local Frame = Instance.new("Frame")

Frame.Name = "AutoTrapStatus"
Frame.Size = UDim2.new(0, 180, 0, 45)
Frame.Position = UDim2.new(0, 15, 0, 15)

Frame.BackgroundColor3 =
    Color3.fromRGB(25, 25, 25)

Frame.BorderSizePixel = 0

Frame.Parent = ScreenGui

local Corner = Instance.new("UICorner")
Corner.CornerRadius = UDim.new(0, 8)
Corner.Parent = Frame

--------------------------------------------------
--// LABEL
--------------------------------------------------

local Status = Instance.new("TextLabel")

Status.Size = UDim2.new(1, 0, 1, 0)

Status.BackgroundTransparency = 1

Status.Font = Enum.Font.GothamBold
Status.TextSize = 15

Status.Text = "AUTO TRAP: ON"

Status.TextColor3 =
    Color3.fromRGB(85, 255, 85)

Status.Parent = Frame

--------------------------------------------------
--// UPDATE GUI
--------------------------------------------------

local function UpdateGUI()

    if AutoTrapEnabled then

        Status.Text = "AUTO TRAP: ON"

        Status.TextColor3 =
            Color3.fromRGB(85, 255, 85)

    else

        Status.Text = "AUTO TRAP: OFF"

        Status.TextColor3 =
            Color3.fromRGB(255, 80, 80)

    end

end

--------------------------------------------------
--// F2 TOGGLE
--------------------------------------------------

UserInputService.InputBegan:Connect(function(
    input,
    gameProcessed
)

    if gameProcessed then
        return
    end

    if input.KeyCode == Enum.KeyCode.F2 then

        AutoTrapEnabled =
            not AutoTrapEnabled

        UpdateGUI()

        print(
            "Auto Trap:",
            AutoTrapEnabled
                and "ON"
                or "OFF"
        )

    end

end)

--------------------------------------------------
--// NORMAL AUTO TRAP
--
-- Impact Shot
-- Explosive Kick
--------------------------------------------------

Transceiver.OnClientEvent:Connect(function(
    action,
    player,
    style,
    skill,
    ball
)

    if not AutoTrapEnabled then
        return
    end

    if action ~= "Hold" then
        return
    end

    if player == LocalPlayer then
        return
    end

    if skill ~= "Impact Shot"
        and skill ~= "Explosive Kick"
    then
        return
    end

    if os.clock() - LastTrigger
        < TrapCooldown
    then
        return
    end

    --------------------------------------------------
    -- GET CHARACTERS
    --------------------------------------------------

    local MyCharacter =
        LocalPlayer.Character

    local TheirCharacter =
        player.Character

    if not MyCharacter
        or not TheirCharacter
    then
        return
    end

    --------------------------------------------------
    -- GET ROOTS
    --------------------------------------------------

    local MyRoot =
        MyCharacter:FindFirstChild(
            "HumanoidRootPart"
        )

    local TheirRoot =
        TheirCharacter:FindFirstChild(
            "HumanoidRootPart"
        )

    if not MyRoot or not TheirRoot then
        return
    end

    --------------------------------------------------
    -- DISTANCE
    --------------------------------------------------

    local Distance =
        (
            MyRoot.Position
            - TheirRoot.Position
        ).Magnitude

    LastTrigger = os.clock()

    --------------------------------------------------
    -- TRAP
    --------------------------------------------------

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
--// BICYCLE AUTO TRAP
--
-- Impact Bicycle
-- -> Black Hole Trap
--------------------------------------------------

Transceiver.OnClientEvent:Connect(function(
    action,
    player,
    style,
    skill,
    ball
)

    if not AutoTrapEnabled then
        return
    end

    if action ~= "UseSkill" then
        return
    end

    if skill ~= "Impact Bicycle" then
        return
    end

    if player == LocalPlayer then
        return
    end

    if os.clock() - LastBicycleTrap
        < BicycleTrapCooldown
    then
        return
    end

    LastBicycleTrap = os.clock()

    Transceiver:FireServer(
        "UseSkill",
        "Black Hole Trap"
    )

end)

--------------------------------------------------
--// INITIAL GUI
--------------------------------------------------

UpdateGUI()

print("Auto Trap Hub loaded | F2 = Toggle")
