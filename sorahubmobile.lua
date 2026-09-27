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
local TDImmunityEnabled = true

local LastTrigger = 0
local TrapCooldown = 0.2

local LastTackle = 0
local TackleCooldown = 0.5

local CLOSE_DISTANCE = 55

local TD_IMMUNITY_DISTANCE = 30
local TD_IMMUNITY_COOLDOWN = 0.15

local CHECK_INTERVAL = 0.03
local TACKLE_RANGE = 8
local PREDICTION_TIME = 0.12

--------------------------------------------------
--// TD IMMUNITY STATE
--------------------------------------------------

local FakeVolleyPending = false
local PendingPlayer = nil

local RushCooldown = false

--------------------------------------------------
--// EXCEPTION LIST
--------------------------------------------------

local ExceptionList = {
    ["TheNextNagi"] = true,
    ["LeoTheDominican"] = true,
}

local function isExcluded(player)

    if not player then
        return false
    end

    return ExceptionList[player.Name] == true

end

--------------------------------------------------
--// GUI
--------------------------------------------------

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "TrapTackleMobileHub"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = game:GetService("CoreGui")

--------------------------------------------------
--// CREATE MOBILE BUTTON
--------------------------------------------------

local function CreateStatus(name, yPosition, text)

    local Button = Instance.new("TextButton")

    Button.Name = name
    Button.Size = UDim2.new(0, 180, 0, 50)
    Button.Position = UDim2.new(0, 15, 0, yPosition)

    Button.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
    Button.BorderSizePixel = 0

    Button.Font = Enum.Font.GothamBold
    Button.TextSize = 16
    Button.Text = text
    Button.TextColor3 = Color3.fromRGB(85, 255, 85)

    Button.AutoButtonColor = true

    Button.Parent = ScreenGui

    local Corner = Instance.new("UICorner")
    Corner.CornerRadius = UDim.new(0, 10)
    Corner.Parent = Button

    return Button
end

local TrapButton = CreateStatus(
    "TrapButton",
    15,
    "TRAP: ON"
)

local TackleButton = CreateStatus(
    "TackleButton",
    75,
    "TACKLE: ON"
)

local TDImmunityButton = CreateStatus(
    "TDImmunityButton",
    135,
    "TD IMMUNITY: ON"
)

--------------------------------------------------
--// DRAG + TAP SYSTEM
--------------------------------------------------
-- Tap = toggle
-- Drag = move
--------------------------------------------------

local function MakeDraggable(Button, ToggleFunction)

    local Dragging = false
    local DragStart = nil
    local StartPosition = nil
    local DragInput = nil

    local HasMoved = false
    local DRAG_THRESHOLD = 8

    --------------------------------------------------
    --// UPDATE POSITION
    --------------------------------------------------

    local function UpdatePosition(input)

        local Delta =
            input.Position - DragStart

        if math.abs(Delta.X) > DRAG_THRESHOLD
            or math.abs(Delta.Y) > DRAG_THRESHOLD
        then
            HasMoved = true
        end

        Button.Position = UDim2.new(
            StartPosition.X.Scale,
            StartPosition.X.Offset + Delta.X,
            StartPosition.Y.Scale,
            StartPosition.Y.Offset + Delta.Y
        )

    end

    --------------------------------------------------
    --// INPUT START
    --------------------------------------------------

    Button.InputBegan:Connect(function(input)

        if input.UserInputType ~= Enum.UserInputType.MouseButton1
            and input.UserInputType ~= Enum.UserInputType.Touch
        then
            return
        end

        Dragging = true
        HasMoved = false

        DragStart = input.Position
        StartPosition = Button.Position

        input.Changed:Connect(function()

            if input.UserInputState == Enum.UserInputState.End then

                Dragging = false

                --------------------------------------------------
                -- ONLY TOGGLE IF IT WAS A TAP
                --------------------------------------------------

                if not HasMoved then
                    ToggleFunction()
                end

            end

        end)

    end)

    --------------------------------------------------
    --// INPUT CHANGED
    --------------------------------------------------

    Button.InputChanged:Connect(function(input)

        if input.UserInputType == Enum.UserInputType.MouseMovement
            or input.UserInputType == Enum.UserInputType.Touch
        then

            DragInput = input

        end

    end)

    --------------------------------------------------
    --// DRAG MOVEMENT
    --------------------------------------------------

    UserInputService.InputChanged:Connect(function(input)

        if not Dragging then
            return
        end

        if input == DragInput
            or input.UserInputType == Enum.UserInputType.MouseMovement
            or input.UserInputType == Enum.UserInputType.Touch
        then

            UpdatePosition(input)

        end

    end)

end

--------------------------------------------------
--// GUI UPDATES
--------------------------------------------------

local function UpdateButton(Button, Enabled, Name)

    if Enabled then

        Button.Text = Name .. ": ON"
        Button.TextColor3 =
            Color3.fromRGB(85, 255, 85)

    else

        Button.Text = Name .. ": OFF"
        Button.TextColor3 =
            Color3.fromRGB(255, 80, 80)

    end

end

local function UpdateTrapGUI()

    UpdateButton(
        TrapButton,
        TrapEnabled,
        "TRAP"
    )

end

local function UpdateTackleGUI()

    UpdateButton(
        TackleButton,
        TackleEnabled,
        "TACKLE"
    )

end

local function UpdateTDImmunityGUI()

    UpdateButton(
        TDImmunityButton,
        TDImmunityEnabled,
        "TD IMMUNITY"
    )

end

--------------------------------------------------
--// BUTTON TOGGLE FUNCTIONS
--------------------------------------------------

local function ToggleTrap()

    TrapEnabled = not TrapEnabled

    UpdateTrapGUI()

    print(
        "Trap Script:",
        TrapEnabled and "ON" or "OFF"
    )

end

local function ToggleTackle()

    TackleEnabled = not TackleEnabled

    UpdateTackleGUI()

    print(
        "Tackle Script:",
        TackleEnabled and "ON" or "OFF"
    )

end

local function ToggleTDImmunity()

    TDImmunityEnabled =
        not TDImmunityEnabled

    if not TDImmunityEnabled then

        FakeVolleyPending = false
        PendingPlayer = nil

    end

    UpdateTDImmunityGUI()

    print(
        "TD Immunity:",
        TDImmunityEnabled and "ON" or "OFF"
    )

end

--------------------------------------------------
--// MAKE BUTTONS DRAGGABLE
--------------------------------------------------

MakeDraggable(
    TrapButton,
    ToggleTrap
)

MakeDraggable(
    TackleButton,
    ToggleTackle
)

MakeDraggable(
    TDImmunityButton,
    ToggleTDImmunity
)

--------------------------------------------------
--// OPTIONAL KEYBOARD CONTROLS
--------------------------------------------------
-- F2 = Trap
-- F3 = Tackle
-- F4 = TD Immunity
--------------------------------------------------

UserInputService.InputBegan:Connect(function(
    input,
    gameProcessed
)

    if gameProcessed then
        return
    end

    if input.KeyCode == Enum.KeyCode.F2 then

        ToggleTrap()

    elseif input.KeyCode == Enum.KeyCode.F3 then

        ToggleTackle()

    elseif input.KeyCode == Enum.KeyCode.F4 then

        ToggleTDImmunity()

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

    if isExcluded(player) then
        return
    end

    if skill ~= "Impact Shot"
        and skill ~= "Explosive Kick"
    then
        return
    end

    if os.clock() - LastTrigger < TrapCooldown then
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
--// TD IMMUNITY DISTANCE CHECK
--------------------------------------------------

local function IsTDPlayerClose(player)

    if not player or player == LocalPlayer then
        return false
    end

    local Character =
        LocalPlayer.Character

    local OtherCharacter =
        player.Character

    if not Character or not OtherCharacter then
        return false
    end

    local Root =
        Character:FindFirstChild(
            "HumanoidRootPart"
        )

    local OtherRoot =
        OtherCharacter:FindFirstChild(
            "HumanoidRootPart"
        )

    if not Root or not OtherRoot then
        return false
    end

    return (
        Root.Position
        - OtherRoot.Position
    ).Magnitude <= TD_IMMUNITY_DISTANCE

end

--------------------------------------------------
--// TD IMMUNITY
--
--// Defensive Stance -> Fake Volley
--// TD actually used -> Finish Fake Volley
--// Defensive Rush -> Creative Trap
--------------------------------------------------

Transceiver.OnClientEvent:Connect(function(
    action,
    player,
    style,
    skill,
    ball
)

    if not TDImmunityEnabled then
        return
    end

    if player == LocalPlayer then
        return
    end

    if isExcluded(player) then
        return
    end

    --------------------------------------------------
    -- DEFENSIVE STANCE
    -- START FAKE VOLLEY
    --------------------------------------------------

    if action == "Hold"
        and style == "Total Defense"
        and skill == "Defensive Stance"
    then

        if not IsTDPlayerClose(player) then
            return
        end

        if FakeVolleyPending then
            return
        end

        FakeVolleyPending = true
        PendingPlayer = player

        Transceiver:FireServer(
            "Hold",
            "Fake Volley Shot"
        )

        return
    end

    --------------------------------------------------
    -- DEFENSIVE STANCE ACTUALLY GETS USED
    -- FINISH FAKE VOLLEY
    --------------------------------------------------

    if action == "UseSkill"
        and style == "Total Defense"
        and skill == "Defensive Stance"
    then

        if not FakeVolleyPending then
            return
        end

        if player ~= PendingPlayer then
            return
        end

        Transceiver:FireServer(
            "UseSkill",
            "Fake Volley Shot"
        )

        FakeVolleyPending = false
        PendingPlayer = nil

        return
    end

    --------------------------------------------------
    -- DEFENSIVE RUSH
    -- CREATIVE TRAP
    --------------------------------------------------

    if action == "Kick"
        and style == "Total Defense"
        and skill == "Defensive Rush"
    then

        if not IsTDPlayerClose(player) then
            return
        end

        if RushCooldown then
            return
        end

        RushCooldown = true

        Transceiver:FireServer(
            "UseSkill",
            "Creative Trap"
        )

        task.delay(
            TD_IMMUNITY_COOLDOWN,
            function()

                RushCooldown = false

            end
        )

        return
    end

end)

--------------------------------------------------
--// FIND BALL HOLDER
--------------------------------------------------

local function getBallHolder()

    for _, player in ipairs(
        Players:GetPlayers()
    ) do

        if player ~= LocalPlayer then

            if not isExcluded(player) then

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

    if isExcluded(holder) then
        return
    end

    if hasIFrames(holderCharacter) then
        return
    end

    --------------------------------------------------
    -- PREDICT BALL
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
    -- FINAL IFRAME CHECK
    --------------------------------------------------

    if hasIFrames(holderCharacter) then
        return
    end

    LastTackle = os.clock()

    SkillEvent:FireServer(
        "TackleBegin"
    )

    if hasIFrames(holderCharacter) then
        return
    end

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
--// INITIAL GUI STATE
--------------------------------------------------

UpdateTrapGUI()
UpdateTackleGUI()
UpdateTDImmunityGUI()
