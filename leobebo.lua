-- LeoBebo | Auto Bike and camera shake only.
-- Select the Impact Bicycle slot, then left-click. F1 toggles Auto Bike.
-- End hides/shows this panel without disabling Auto Bike.
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer
local Transceiver = ReplicatedStorage.Remotes.TranciverRemote
if _G.LeoBeboHubRunning then return end
_G.LeoBeboHubRunning = true

local AutoBikeEnabled = true
local BikeArmed, ImpactKey = false, nil
local Alive, Connections = true, {}
local function connect(signal, callback)
    local connection = signal:Connect(callback)
    table.insert(Connections, connection)
    return connection
end
local shaker, originalShake, noShake
local function restoreCameraShake()
    if shaker and shaker.Update == noShake then shaker.Update = originalShake end
    shaker, originalShake, noShake = nil, nil, nil
end


local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "LeoBeboHub"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = game:GetService("CoreGui")
local Frame = Instance.new("Frame")
Frame.Name = "LeoStatus"
Frame.Size = UDim2.new(0, 250, 0, 78)
Frame.Position = UDim2.new(0, 15, 0, 15)
Frame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
Frame.BorderSizePixel = 0
Frame.Parent = ScreenGui
local Corner = Instance.new("UICorner")
Corner.CornerRadius = UDim.new(0, 8)
Corner.Parent = Frame
local function CreateStatus(name, row, text)
    local button = Instance.new("TextButton")
    button.Name = name
    button.Size = UDim2.new(1, 0, 0, 39)
    button.Position = UDim2.new(0, 0, 0, row * 39)
    button.BackgroundTransparency = 1
    button.BorderSizePixel = 0
    button.Font = Enum.Font.GothamBold
    button.TextSize = 15
    button.Text = text
    button.TextColor3 = Color3.fromRGB(85, 255, 85)
    button.AutoButtonColor = false
    button.Parent = Frame
    return button
end
local AutoBikeButton = CreateStatus("AutoBikeButton", 0, "")
local CameraShakeButton = CreateStatus("CameraShakeButton", 1, "REMOVE CAMERA SHAKE")
CameraShakeButton.TextColor3 = Color3.fromRGB(235, 235, 235)
connect(CameraShakeButton.Activated, function()
    if shaker then return end
    local modules = ReplicatedStorage:FindFirstChild("Modules")
    local module = modules and modules:FindFirstChild("CameraShaker")
    if not module then
        CameraShakeButton.Text = "SHAKE MODULE NOT FOUND"
        return
    end
    local loaded, value = pcall(require, module)
    if not loaded or type(value) ~= "table" or type(value.Update) ~= "function" then
        CameraShakeButton.Text = "SHAKE MODULE UNAVAILABLE"
        return
    end
    if not Alive then return end
    shaker, originalShake = value, value.Update
    noShake = function() return CFrame.new() end
    shaker.Update = noShake
    CameraShakeButton.Text = "CAMERA SHAKE: REMOVED"
    CameraShakeButton.TextColor3 = Color3.fromRGB(85, 255, 85)
end)

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

local function UpdateBikeGUI()
    UpdateButton(AutoBikeButton, AutoBikeEnabled, "[F1] AUTO BIKE")
end
local function ToggleBike()
    AutoBikeEnabled = not AutoBikeEnabled
    BikeArmed = false
    UpdateBikeGUI()
end
connect(AutoBikeButton.Activated, ToggleBike)

-- Scan once when EquippedSkills is available, matching the original Auto Bike.
local SlotKeys = {
    SlotOne=Enum.KeyCode.One, SlotTwo=Enum.KeyCode.Two, SlotThree=Enum.KeyCode.Three,
    SlotFour=Enum.KeyCode.Four, SlotFive=Enum.KeyCode.Five, SlotSix=Enum.KeyCode.Six,
    SlotSeven=Enum.KeyCode.Seven, SlotEight=Enum.KeyCode.Eight, SlotNine=Enum.KeyCode.Nine,
}
local function ScanBikeSlot(skills)
    for slot, key in pairs(SlotKeys) do
        if skills:GetAttribute(slot) == "Impact Bicycle" then
            ImpactKey = key
            return
        end
    end
end
local equipped = LocalPlayer:FindFirstChild("EquippedSkills")
if equipped then
    ScanBikeSlot(equipped)
else
    local addedConnection
    addedConnection = connect(LocalPlayer.ChildAdded, function(child)
        if child.Name == "EquippedSkills" then
            addedConnection:Disconnect()
            ScanBikeSlot(child)
        end
    end)
end
connect(LocalPlayer.CharacterAdded, function() BikeArmed = false end)
connect(UserInputService.InputBegan, function(input, gameProcessed)
    if UserInputService:GetFocusedTextBox() then return end
    if AutoBikeEnabled and BikeArmed and input.UserInputType == Enum.UserInputType.MouseButton1 then
        -- UI clicks must not consume an armed bike or send a shot.
        if gameProcessed then return end
        BikeArmed = false
        local character = LocalPlayer.Character
        local ball = character and character:FindFirstChild("Ball")
        local root = character and character:FindFirstChild("HumanoidRootPart")
        local punch = ReplicatedStorage.Remotes:FindFirstChild("PunchRemote")
        if not ball or not root or not punch then return end
        punch:FireServer("LobPass", ball, root.Position + Vector3.new(0, 50, 0))
        Transceiver:FireServer("UseSkill", "Impact Bicycle")
        return
    end
    if gameProcessed then return end
    if input.KeyCode == Enum.KeyCode.End then
        ScreenGui.Enabled = not ScreenGui.Enabled
    elseif input.KeyCode == Enum.KeyCode.F1 then ToggleBike()
    elseif AutoBikeEnabled and ImpactKey and input.KeyCode == ImpactKey then BikeArmed = true
    elseif SlotKeys.SlotOne == input.KeyCode or input.KeyCode == Enum.KeyCode.Two
        or input.KeyCode == Enum.KeyCode.Three or input.KeyCode == Enum.KeyCode.Four
        or input.KeyCode == Enum.KeyCode.Five or input.KeyCode == Enum.KeyCode.Six
        or input.KeyCode == Enum.KeyCode.Seven or input.KeyCode == Enum.KeyCode.Eight
        or input.KeyCode == Enum.KeyCode.Nine then BikeArmed = false
    end
end)


connect(ScreenGui.Destroying, function()
    Alive = false
    BikeArmed = false
    restoreCameraShake()
    for _, connection in ipairs(Connections) do connection:Disconnect() end
    table.clear(Connections)
    _G.LeoBeboHubRunning = nil
end)
UpdateBikeGUI()
print("LeoBebo loaded | F1 Auto Bike | End Show/Hide | Click Remove Camera Shake")
