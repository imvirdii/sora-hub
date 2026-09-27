local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LocalPlayer = Players.LocalPlayer

local Transceiver = ReplicatedStorage.Remotes.TranciverRemote
local SkillEvent = ReplicatedStorage.Remotes.UseKeyboardSkillRemote
local PunchRemote = ReplicatedStorage.Remotes.PunchRemote

local TeamsFolder = ReplicatedStorage:WaitForChild("Teams")
local EquippedSkills = LocalPlayer:WaitForChild("EquippedSkills")

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
local AutoTrapTDEnabled = true
local AutoBikeEnabled = true

local LastTrigger = 0
local TrapCooldown = 0.2

local LastAutoTrapTD = 0
local AutoTrapTDCooldown = 0.15

local LastTackle = 0
local TackleCooldown = 0.5

local CLOSE_DISTANCE = 55

local CHECK_INTERVAL = 0.03
local TACKLE_RANGE = 8
local PREDICTION_TIME = 0.12

--------------------------------------------------
--// AUTO BIKE SETTINGS
--------------------------------------------------

local BikeWaitingForLMB = false
local BikeConnection = nil

local SlotKeys = {
    SlotOne = Enum.KeyCode.One,
    SlotTwo = Enum.KeyCode.Two,
    SlotThree = Enum.KeyCode.Three,
    SlotFour = Enum.KeyCode.Four,
    SlotFive = Enum.KeyCode.Five,
    SlotSix = Enum.KeyCode.Six,
    SlotSeven = Enum.KeyCode.Seven,
    SlotEight = Enum.KeyCode.Eight,
    SlotNine = Enum.KeyCode.Nine,
}

--------------------------------------------------
--// FIND IMPACT BICYCLE ONCE
--------------------------------------------------

local ImpactSlot
local ImpactKey

for attributeName, keyCode in pairs(SlotKeys) do

    local skill =
        EquippedSkills:GetAttribute(attributeName)

    if skill == "Impact Bicycle" then

        ImpactSlot = attributeName
        ImpactKey = keyCode

        break
    end
end

if not ImpactKey then

    warn(
        "Impact Bicycle was not found in EquippedSkills"
    )

else

    print(
        "Impact Bicycle found in:",
        ImpactSlot
    )

end

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
    Frame.Size = UDim2.new(0, 160, 0, 40)
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
    Status.TextSize = 14
    Status.Text = text
    Status.TextColor3 =
        Color3.fromRGB(85, 255, 85)
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

local AutoTrapTDStatus = CreateStatus(
    "AutoTrapTDStatus",
    105,
    "AUTO TRAP TD: ON"
)

local AutoBikeStatus = CreateStatus(
    "AutoBikeStatus",
    150,
    "AUTO BIKE: ON"
)

--------------------------------------------------
--// GUI UPDATES
--------------------------------------------------

local function UpdateStatus(Status, Enabled, Name)

    if Enabled then

        Status.Text = Name .. ": ON"
        Status.TextColor3 =
            Color3.fromRGB(85, 255, 85)

    else

        Status.Text = Name .. ": OFF"
        Status.TextColor3 =
            Color3.fromRGB(255, 80, 80)

    end
end

local function UpdateTrapGUI()

    UpdateStatus(
        TrapStatus,
        TrapEnabled,
        "TRAP"
    )

end

local function UpdateTackleGUI()

    UpdateStatus(
        TackleStatus,
        TackleEnabled,
        "TACKLE"
    )

end

local function UpdateAutoTrapTDGUI()

    UpdateStatus(
        AutoTrapTDStatus,
        AutoTrapTDEnabled,
        "AUTO TRAP TD"
    )

end

local function UpdateAutoBikeGUI()

    UpdateStatus(
        AutoBikeStatus,
        AutoBikeEnabled,
        "AUTO BIKE"
    )

end

--------------------------------------------------
--// F2 / F3 / F4 / F5 TOGGLES
--------------------------------------------------

UserInputService.InputBegan:Connect(function(
    input,
    gameProcessed
)

    if gameProcessed then
        return
    end

    --------------------------------------------------
    -- F2 = TRAP
    --------------------------------------------------

    if input.KeyCode == Enum.KeyCode.F2 then

        TrapEnabled = not TrapEnabled

        UpdateTrapGUI()

        print(
            "Trap Script:",
            TrapEnabled and "ON" or "OFF"
        )

    end

    --------------------------------------------------
    -- F3 = TACKLE
    --------------------------------------------------

    if input.KeyCode == Enum.KeyCode.F3 then

        TackleEnabled = not TackleEnabled

        UpdateTackleGUI()

        print(
            "Tackle Script:",
            TackleEnabled and "ON" or "OFF"
        )

    end

    --------------------------------------------------
    -- F4 = AUTO TRAP TD
    --------------------------------------------------

    if input.KeyCode == Enum.KeyCode.F4 then

        AutoTrapTDEnabled =
            not AutoTrapTDEnabled

        UpdateAutoTrapTDGUI()

        print(
            "Auto Trap TD:",
            AutoTrapTDEnabled and "ON" or "OFF"
        )

    end

    --------------------------------------------------
    -- F5 = AUTO BIKE
    --------------------------------------------------

    if input.KeyCode == Enum.KeyCode.F5 then

        AutoBikeEnabled =
            not AutoBikeEnabled

        UpdateAutoBikeGUI()

        if not AutoBikeEnabled then

            BikeWaitingForLMB = false

            if BikeConnection then
                BikeConnection:Disconnect()
                BikeConnection = nil
            end

        end

        print(
            "Auto Bike:",
            AutoBikeEnabled and "ON" or "OFF"
        )

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
--// TEAM CHECK
--------------------------------------------------

local function getPlayerTeam(player)

    if not player then
        return nil
    end

    for _, teamFolder in ipairs(
        TeamsFolder:GetChildren()
    ) do

        for _, value in pairs(
            teamFolder:GetAttributes()
        ) do

            if value == player.Name then
                return teamFolder
            end

        end
    end

    return nil
end

local function isSameTeam(player)

    local myTeam =
        getPlayerTeam(LocalPlayer)

    local theirTeam =
        getPlayerTeam(player)

    if not myTeam or not theirTeam then
        return false
    end

    return myTeam == theirTeam
end

--------------------------------------------------
--// TRAP SYSTEM
--------------------------------------------------

Transceiver.OnClientEvent:Connect(function(
    action,
    player,
    style,
    skill,
    ball
)

    if not TrapEnabled then
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

    local MyCharacter =
        LocalPlayer.Character

    local TheirCharacter =
        player.Character

    local MyRoot =
        MyCharacter
        and MyCharacter:FindFirstChild(
            "HumanoidRootPart"
        )

    local TheirRoot =
        TheirCharacter
        and TheirCharacter:FindFirstChild(
            "HumanoidRootPart"
        )

    if not MyRoot or not TheirRoot then
        return
    end

    LastTrigger = os.clock()

    local Distance =
        (
            MyRoot.Position
            - TheirRoot.Position
        ).Magnitude

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
--// AUTO TRAP TD
--------------------------------------------------

local function IsBall(ball)

    return ball
        and ball:IsDescendantOf(workspace)
        and ball.Name == "Ball"

end

Transceiver.OnClientEvent:Connect(function(
    action,
    player,
    style,
    skill,
    ball
)

    if not AutoTrapTDEnabled then
        return
    end

    if player == LocalPlayer then
        return
    end

    if action ~= "Kick" then
        return
    end

    if not IsBall(ball) then
        return
    end

    if os.clock() - LastAutoTrapTD
        < AutoTrapTDCooldown
    then
        return
    end

    LastAutoTrapTD = os.clock()

    Transceiver:FireServer(
        "UseSkill",
        "Creative Trap"
    )

end)

--------------------------------------------------
--// FIND BALL HOLDER
--------------------------------------------------

local function getBallHolder()

    for _, player in ipairs(
        Players:GetPlayers()
    ) do

        if player ~= LocalPlayer then

            if not isSameTeam(player) then

                local character =
                    player.Character

                if character then

                    local ballFolder =
                        character:FindFirstChild("Ball")

                    if ballFolder then

                        local ball =
                            ballFolder:FindFirstChild("Ball")

                        if ball then

                            return player,
                                character,
                                ball

                        end
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

    local character =
        LocalPlayer.Character

    if not character then
        return
    end

    local root =
        character:FindFirstChild(
            "HumanoidRootPart"
        )

    if not root then
        return
    end

    local holder,
        holderCharacter,
        ball =
        getBallHolder()

    if not holder
        or not holderCharacter
        or not ball
    then

        return

    end

    --------------------------------------------------
    -- TEAM CHECK
    --------------------------------------------------

    if isSameTeam(holder) then
        return
    end

    --------------------------------------------------
    -- IFRAME CHECK
    --------------------------------------------------

    if hasIFrames(holderCharacter) then
        return
    end

    --------------------------------------------------
    -- PREDICT BALL POSITION
    --------------------------------------------------

    local predictedPosition =
        ball.Position
        + (
            ball.AssemblyLinearVelocity
            * PREDICTION_TIME
        )

    if
        (
            root.Position
            - predictedPosition
        ).Magnitude > TACKLE_RANGE
    then

        return

    end

    --------------------------------------------------
    -- COOLDOWN
    --------------------------------------------------

    if os.clock() - LastTackle
        < TackleCooldown
    then

        return

    end

    --------------------------------------------------
    -- CHECK BEFORE FIRE
    --------------------------------------------------

    if isSameTeam(holder) then
        return
    end

    if hasIFrames(holderCharacter) then
        return
    end

    LastTackle = os.clock()

    SkillEvent:FireServer(
        "TackleBegin"
    )

    --------------------------------------------------
    -- FINAL TEAM CHECK
    --------------------------------------------------

    if isSameTeam(holder) then
        return
    end

    --------------------------------------------------
    -- FINAL IFRAME CHECK
    --------------------------------------------------

    if hasIFrames(holderCharacter) then
        return
    end

    --------------------------------------------------
    -- TACKLE
    --------------------------------------------------

    SkillEvent:FireServer(
        "Tackle",
        ball,
        root.CFrame
            * CFrame.new(0, -1.5, 0)
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
--// AUTO BIKE
--------------------------------------------------

local function StartBikeLMBListener()

    if BikeConnection then

        BikeConnection:Disconnect()
        BikeConnection = nil

    end

    BikeWaitingForLMB = true

    BikeConnection =
        UserInputService.InputBegan:Connect(
            function(mouseInput)

                if not BikeWaitingForLMB then
                    return
                end

                if not AutoBikeEnabled then
                    return
                end

                if mouseInput.UserInputType
                    ~= Enum.UserInputType.MouseButton1
                then

                    return

                end

                BikeWaitingForLMB = false

                if BikeConnection then

                    BikeConnection:Disconnect()
                    BikeConnection = nil

                end

                local Character =
                    LocalPlayer.Character
                    or LocalPlayer.CharacterAdded:Wait()

                local Ball =
                    Character:FindFirstChild("Ball")

                local Root =
                    Character:FindFirstChild(
                        "HumanoidRootPart"
                    )

                if not Ball or not Root then
                    return
                end

                --------------------------------------------------
                -- LOB FIRST
                --------------------------------------------------

                local targetPosition =
                    Root.Position
                    + Vector3.new(0, 50, 0)

                PunchRemote:FireServer(
                    "LobPass",
                    Ball,
                    targetPosition
                )

                --------------------------------------------------
                -- IMPACT BICYCLE
                --------------------------------------------------

                Transceiver:FireServer(
                    "UseSkill",
                    "Impact Bicycle"
                )

            end
        )
end

--------------------------------------------------
--// AUTO BIKE INPUT
--------------------------------------------------

UserInputService.InputBegan:Connect(function(
    input,
    gameProcessed
)

    if gameProcessed then
        return
    end

    if not AutoBikeEnabled then
        return
    end

    if not ImpactKey then
        return
    end

    --------------------------------------------------
    -- PRESS IMPACT BICYCLE SLOT
    --------------------------------------------------

    if input.KeyCode == ImpactKey then

        StartBikeLMBListener()

        print(
            "Impact Bicycle selected:",
            ImpactSlot
        )

    end
end)

--------------------------------------------------
--// INITIAL GUI STATE
--------------------------------------------------

UpdateTrapGUI()
UpdateTackleGUI()
UpdateAutoTrapTDGUI()
UpdateAutoBikeGUI()
