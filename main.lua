-- Sora Hub | Custom UI, no third-party UI library.
-- Client script; requires the same execution environment as the source project.
-- F1 Bike | F2 Trap | F3 Tackle | F4 TD Immunity | F5 Auto M2 | Space Aim | End Menu

local Env = getgenv()
if Env.SoraHubSession then
    warn('Sora Hub is already running. Unload it before executing again.')
    return
end

-- Custom UI: no external UI library or downloads.
local UIInput = game:GetService('UserInputService')
local UIPlayer = game:GetService('Players').LocalPlayer
local Gui = Instance.new('ScreenGui')
Gui.Name = 'SoraHub'
Gui.ResetOnSpawn = false
Gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
Gui.Parent = UIPlayer:WaitForChild('PlayerGui')
local Toggles, Options = {}, {}
local Library = { UIConnections = {}, Unloaded = false }
local accent = Color3.fromRGB(147, 112, 255)
local muted = Color3.fromRGB(161, 163, 184)
local uiZoom = 1
local menuKey = 'End'
local function ui(class, parent, props)
    local object = Instance.new(class)
    for key, value in pairs(props or {}) do object[key] = value end
    object.Parent = parent
    return object
end
local function rounded(object, radius)
    ui('UICorner', object, { CornerRadius=UDim.new(0,radius or 8) })
end
local function listen(signal, callback)
    local connection = signal:Connect(callback)
    table.insert(Library.UIConnections, connection)
    return connection
end
local function label(parent, text, size)
    return ui('TextLabel', parent, { BackgroundTransparency=1, Text=text, TextColor3=Color3.fromRGB(238,238,248), Font=Enum.Font.Gotham, TextSize=size or 13, TextXAlignment=Enum.TextXAlignment.Left, Size=UDim2.new(1,0,0,22) })
end
local root = ui('Frame', Gui, { Size=UDim2.fromOffset(570,530), AnchorPoint=Vector2.new(0.5,0.5), Position=UDim2.fromScale(0.5,0.5), BackgroundColor3=Color3.fromRGB(18,19,28), BorderSizePixel=0 })
rounded(root,12)
ui('UIStroke',root,{Color=Color3.fromRGB(62,55,88),Thickness=1})
local scale = ui('UIScale', root, { Scale=1 })
local function fit()
    local cam = workspace.CurrentCamera
    if cam then scale.Scale=math.min(uiZoom, (cam.ViewportSize.X-24)/570, (cam.ViewportSize.Y-24)/530) end
end
fit()
listen(game:GetService('RunService').RenderStepped, fit)
local title = label(root,'SORA HUB',20)
title.Position=UDim2.fromOffset(20,14)
title.Size=UDim2.new(1,-110,0,28)
title.Font=Enum.Font.GothamBold
title.Active=true
local hide = ui('TextButton',root,{Text='−',Font=Enum.Font.GothamBold,TextSize=25,TextColor3=muted,BackgroundColor3=Color3.fromRGB(31,32,45),Size=UDim2.fromOffset(32,30),Position=UDim2.new(1,-47,0,17),BorderSizePixel=0})
rounded(hide)
local reopen=ui('TextButton',Gui,{Text='SORA',Font=Enum.Font.GothamBold,TextSize=14,TextColor3=Color3.new(1,1,1),BackgroundColor3=accent,Size=UDim2.fromOffset(70,34),Position=UDim2.fromOffset(12,100),Visible=false,BorderSizePixel=0})
rounded(reopen)
local function visibility() root.Visible=not root.Visible; reopen.Visible=not root.Visible end
listen(hide.Activated,visibility)
listen(reopen.Activated,visibility)
local dragging, dragStart, frameStart
listen(title.InputBegan,function(input)
    if input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch then
        dragging=input; dragStart=input.Position; frameStart=root.Position
    end
end)
listen(UIInput.InputChanged,function(input)
    if dragging and (input.UserInputType==Enum.UserInputType.MouseMovement or input==dragging) then
        local delta=input.Position-dragStart
        root.Position=UDim2.new(frameStart.X.Scale,frameStart.X.Offset+delta.X,frameStart.Y.Scale,frameStart.Y.Offset+delta.Y)
    end
end)
listen(UIInput.InputEnded,function(input) if input==dragging then dragging=nil end end)
local nav=ui('Frame',root,{BackgroundTransparency=1,Position=UDim2.fromOffset(16,76),Size=UDim2.new(1,-32,0,32)})
ui('UIListLayout',nav,{FillDirection=Enum.FillDirection.Horizontal,Padding=UDim.new(0,8)})
local footer=label(root,'F1 Bike   F2 Trap   F3 Tackle   F4 TD   F5 M2   Space Aim',10)
footer.Position=UDim2.new(0,18,1,-28); footer.TextColor3=muted
local pages={}
local keys={}
local function row(parent,height)
    return ui('Frame',parent,{Size=UDim2.new(1,0,0,height or 36),BackgroundTransparency=1})
end
local function groupMethods(parent)
    local group={}
    function group:AddToggle(id, info)
        local holder=row(parent)
        local button=ui('TextButton',holder,{Text='',AutoButtonColor=false,BackgroundTransparency=1,Size=UDim2.fromScale(1,1)})
        local caption=label(button,info.Text,13); caption.Size=UDim2.new(1,-75,1,0)
        local pill=ui('TextLabel',button,{Size=UDim2.fromOffset(44,23),Position=UDim2.new(1,-44,0.5,-11),Font=Enum.Font.GothamBold,TextSize=10,BorderSizePixel=0,TextColor3=Color3.new(1,1,1)})
        rounded(pill,7)
        local control={Value=info.Default==true}
        function control:SetValue(value)
            self.Value=value==true
            pill.Text=self.Value and 'ON' or 'OFF'
            pill.BackgroundColor3=self.Value and accent or Color3.fromRGB(53,54,69)
            if self.Callback then self.Callback() end
        end
        function control:OnChanged(callback) self.Callback=callback end
        function control:AddKeyPicker(keyId,keyInfo)
            local key={Value=keyInfo.Default}
            Options[keyId]=key
            keys[keyInfo.Default]=function() self:SetValue(not self.Value) end
            local badge=label(holder,keyInfo.Default,9)
            badge.TextColor3=muted; badge.TextXAlignment=Enum.TextXAlignment.Right
            badge.Size=UDim2.fromOffset(35,20); badge.Position=UDim2.new(1,-84,0.5,-10)
            return self
        end
        control:SetValue(control.Value)
        listen(button.Activated,function() control:SetValue(not control.Value) end)
        Toggles[id]=control
        return control
    end
    function group:AddSlider(id,info)
        local holder=row(parent,64)
        local caption=label(holder,info.Text,12)
        caption.Size=UDim2.new(1,-64,0,22)
        local valueBox=ui('TextBox',holder,{Text='',ClearTextOnFocus=false,Font=Enum.Font.Gotham,TextSize=12,TextColor3=Color3.new(1,1,1),BackgroundColor3=Color3.fromRGB(40,40,56),Size=UDim2.fromOffset(55,24),Position=UDim2.new(1,-55,0,0),BorderSizePixel=0})
        rounded(valueBox,5)
        local track=ui('TextButton',holder,{Text='',AutoButtonColor=false,Size=UDim2.new(1,0,0,20),Position=UDim2.fromOffset(0,32),BackgroundTransparency=1})
        local rail=ui('Frame',track,{Size=UDim2.new(1,0,0,5),Position=UDim2.fromOffset(0,8),BackgroundColor3=Color3.fromRGB(49,48,65),BorderSizePixel=0}); rounded(rail,3)
        local fill=ui('Frame',rail,{BackgroundColor3=accent,BorderSizePixel=0,Size=UDim2.fromScale(0,1)}); rounded(fill,3)
        local thumb=ui('Frame',rail,{Size=UDim2.fromOffset(12,12),AnchorPoint=Vector2.new(0.5,0.5),BackgroundColor3=Color3.fromRGB(219,205,255),BorderSizePixel=0}); rounded(thumb,6)
        local control={Value=info.Default}
        function control:SetValue(value)
            local factor=10^info.Rounding
            self.Value=math.clamp(math.floor(value*factor+0.5)/factor,info.Min,info.Max)
            local fraction=(self.Value-info.Min)/(info.Max-info.Min)
            fill.Size=UDim2.fromScale(fraction,1); thumb.Position=UDim2.fromScale(fraction,0.5)
            valueBox.Text=tostring(self.Value)
            if self.Callback then self.Callback() end
        end
        function control:OnChanged(callback) self.Callback=callback end
        local active
        local function update(input)
            if track.AbsoluteSize.X>0 then control:SetValue(info.Min+math.clamp((input.Position.X-track.AbsolutePosition.X)/track.AbsoluteSize.X,0,1)*(info.Max-info.Min)) end
        end
        listen(track.InputBegan,function(input)
            if input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch then active=input; update(input) end
        end)
        listen(UIInput.InputChanged,function(input) if active and (input==active or input.UserInputType==Enum.UserInputType.MouseMovement) then update(input) end end)
        listen(UIInput.InputEnded,function(input) if input==active then active=nil end end)
        listen(valueBox.FocusLost,function() control:SetValue(tonumber(valueBox.Text) or control.Value) end)
        control:SetValue(info.Default); Options[id]=control
        return control
    end
    function group:AddDropdown(id, info)
        local holder=row(parent,60)
        label(holder,info.Text,12)
        local button=ui('TextButton',holder,{Text='',Font=Enum.Font.Gotham,TextSize=12,TextColor3=Color3.new(1,1,1),BackgroundColor3=Color3.fromRGB(40,40,56),Size=UDim2.new(1,0,0,29),Position=UDim2.fromOffset(0,25),BorderSizePixel=0})
        rounded(button,6)
        local choices=ui('Frame',holder,{Visible=false,BackgroundTransparency=1,Size=UDim2.new(1,0,0,#info.Values*28),Position=UDim2.fromOffset(0,58)})
        ui('UIListLayout',choices,{Padding=UDim.new(0,2)})
        local control={Value=info.Values[info.Default or 1]}
        function control:SetValue(value)
            if not table.find(info.Values,value) then return end
            self.Value=value; button.Text=value .. '  ▾'
            choices.Visible=false; holder.Size=UDim2.new(1,0,0,60)
            if self.Callback then self.Callback() end
        end
        function control:OnChanged(callback) self.Callback=callback end
        for _,value in ipairs(info.Values) do
            local item=ui('TextButton',choices,{Text=value,Font=Enum.Font.Gotham,TextSize=12,TextColor3=Color3.new(1,1,1),BackgroundColor3=Color3.fromRGB(48,42,65),Size=UDim2.new(1,0,0,26),BorderSizePixel=0})
            rounded(item,5)
            listen(item.Activated,function() control:SetValue(value) end)
        end
        listen(button.Activated,function()
            choices.Visible=not choices.Visible
            holder.Size=UDim2.new(1,0,0,choices.Visible and (62+#info.Values*28) or 60)
        end)
        control:SetValue(control.Value); Options[id]=control
        return control
    end
    function group:AddButton(info)
        local holder=row(parent,38)
        local button=ui('TextButton',holder,{Text=info.Text,Font=Enum.Font.GothamMedium,TextSize=12,TextColor3=Color3.new(1,1,1),BackgroundColor3=Color3.fromRGB(63,49,99),Size=UDim2.new(1,0,0,32),BorderSizePixel=0})
        rounded(button,7); listen(button.Activated,info.Func)
        return button
    end
    function group:AddLabel(text)
        local textLabel=label(parent,text,11); textLabel.TextColor3=muted
        local control={}
        function control:AddKeyPicker(id,info)
            Options[id]={Value=info.Default}
            textLabel.Text=text .. ': ' .. info.Default
            return self
        end
        return control
    end
    return group
end
function Library:CreateWindow()
    local window={}
    function window:AddTab(name)
        local page=ui('ScrollingFrame',root,{Size=UDim2.new(1,-32,1,-152),Position=UDim2.fromOffset(16,119),BackgroundTransparency=1,BorderSizePixel=0,ScrollBarThickness=3,ScrollBarImageColor3=accent,CanvasSize=UDim2.new(),AutomaticCanvasSize=Enum.AutomaticSize.Y,Visible=#pages==0})
        local columns={}
        for i=1,2 do
            local column=ui('Frame',page,{Size=UDim2.new(0.5,-6,0,0),Position=UDim2.new((i-1)*0.5,(i-1)*6,0,0),BackgroundTransparency=1,AutomaticSize=Enum.AutomaticSize.Y})
            ui('UIListLayout',column,{Padding=UDim.new(0,12),SortOrder=Enum.SortOrder.LayoutOrder})
            columns[i]=column
        end
        local tabButton=ui('TextButton',nav,{Text=name,Font=Enum.Font.GothamMedium,TextSize=12,TextColor3=Color3.new(1,1,1),BackgroundColor3=#pages==0 and accent or Color3.fromRGB(33,34,47),Size=UDim2.fromOffset(110,30),BorderSizePixel=0}); rounded(tabButton,7)
        table.insert(pages,{page=page,button=tabButton})
        listen(tabButton.Activated,function()
            for _,item in ipairs(pages) do item.page.Visible=item.page==page; item.button.BackgroundColor3=item.page==page and accent or Color3.fromRGB(33,34,47) end
        end)
        local tab={}
        local function addGroup(side,titleText)
            local card=ui('Frame',columns[side],{Size=UDim2.new(1,0,0,0),AutomaticSize=Enum.AutomaticSize.Y,BackgroundColor3=Color3.fromRGB(26,27,39),BorderSizePixel=0}); rounded(card,9)
            ui('UIPadding',card,{PaddingTop=UDim.new(0,12),PaddingBottom=UDim.new(0,10),PaddingLeft=UDim.new(0,12),PaddingRight=UDim.new(0,12)})
            ui('UIListLayout',card,{Padding=UDim.new(0,3),SortOrder=Enum.SortOrder.LayoutOrder})
            local heading=label(card,titleText:upper(),10); heading.TextColor3=accent; heading.Font=Enum.Font.GothamBold
            return groupMethods(card)
        end
        function tab:AddLeftGroupbox(titleText) return addGroup(1,titleText) end
        function tab:AddRightGroupbox(titleText) return addGroup(2,titleText) end
        return tab
    end
    return window
end
function Library:Notify(text,duration)
    footer.Text=text
    task.delay(duration or 4,function()
        if not self.Unloaded then footer.Text='F1 Bike   F2 Trap   F3 Tackle   F4 TD   F5 M2   Space Aim' end
    end)
end
function Library:OnUnload(callback) self.UnloadCallback=callback end
function Library:Unload()
    if self.Unloaded then return end
    self.Unloaded=true
    if self.UnloadCallback then self.UnloadCallback() end
    for _,connection in ipairs(self.UIConnections) do connection:Disconnect() end
    Gui:Destroy()
end
listen(UIInput.InputBegan,function(input,processed)
    if UIInput:GetFocusedTextBox() then return end
    if input.KeyCode.Name==menuKey then visibility(); return end
    -- Space remains usable when Roblox handles it as a jump input.
    if processed and input.KeyCode~=Enum.KeyCode.Space then return end
    local callback=keys[input.KeyCode.Name]
    if callback then callback() end
end)

local Players = game:GetService('Players')
local RS = game:GetService('ReplicatedStorage')
local UIS = game:GetService('UserInputService')
local RunService = game:GetService('RunService')
local Player = Players.LocalPlayer
local Remotes = RS:WaitForChild('Remotes')
local Event = Remotes:WaitForChild('TranciverRemote')
local Punch = Remotes:WaitForChild('PunchRemote')
local Tackle = Remotes:WaitForChild('UseKeyboardSkillRemote')

local Session = { Alive = true, Connections = {} }
Env.SoraHubSession = Session
local State = {
    AutoTrap = false, AutoTackle = false, TDImmunity = false,
    AutoM2 = false, AutoAim = false, AimAllowed = true, AutoBike = true,
    AutoPosition = false, Team = 1, Position = 'Forward', AutoFarm = false,
    SpeedDemon = true, SpeedBoost = 0.75, LockFOV = false, FOV = 75,
}
local Character, Root, Humanoid
local speedConnection, speedBase, speedWritten
local pendingPlayer, pendingAt, bikeArmed = nil, 0, false
local lastTrap, lastBikeTrap, lastRush, lastTackle, lastM2 = -math.huge, -math.huge, -math.huge, -math.huge, -math.huge
local lastOwner, wasSprinting, dashDirection
local rotationHumanoid, originalAutoRotate
local camera, cameraConnection, originalFOV
local shaker, oldShake, noShake
local boostedVelocities = setmetatable({}, { __mode = 'k' })
local bannedSpeeds = { [0]=true, [15]=true, [17]=true, [20]=true, [22]=true, [25]=true, [27]=true }

local function connect(signal, callback)
    local connection = signal:Connect(callback)
    table.insert(Session.Connections, connection)
    return connection
end
local function releaseRotation()
    if rotationHumanoid and rotationHumanoid.Parent then
        rotationHumanoid.AutoRotate = originalAutoRotate
    end
    rotationHumanoid, originalAutoRotate = nil, nil
end
local function lockRotation()
    if rotationHumanoid ~= Humanoid then
        releaseRotation()
        rotationHumanoid, originalAutoRotate = Humanoid, Humanoid.AutoRotate
    end
    Humanoid.AutoRotate = false
end
local function sprinting()
    local holding = Character and Character:FindFirstChild('HoldingSkill')
    return holding and holding:GetAttribute('SkillName') == 'Long-Distance Sprinting'
end
local function applySpeed()
    if not Humanoid or not Humanoid.Parent then return end
    local value = Humanoid.WalkSpeed
    -- Ignore our own last write, including deferred property notifications.
    if value == speedWritten then return end
    speedBase, speedWritten = value, nil
    if State.SpeedDemon and not bannedSpeeds[value] then
        speedWritten = value + (sprinting() and 1.213 or State.SpeedBoost)
        Humanoid.WalkSpeed = speedWritten
    end
end
local function restoreSpeed()
    if Humanoid and Humanoid.Parent and speedWritten and Humanoid.WalkSpeed == speedWritten then
        local base = speedBase
        speedWritten = nil
        if base then Humanoid.WalkSpeed = base end
    end
end
local function refreshSpeed()
    if speedConnection then speedConnection:Disconnect() end
    if not State.SpeedDemon then restoreSpeed() end
    if Humanoid and Humanoid.Parent then
        speedConnection = Humanoid:GetPropertyChangedSignal('WalkSpeed'):Connect(applySpeed)
    end
end
local function bindCharacter(newCharacter)
    releaseRotation()
    if speedConnection then speedConnection:Disconnect() end
    restoreSpeed()
    Character, Root, Humanoid = newCharacter, nil, nil
    speedBase, speedWritten, pendingPlayer, bikeArmed = nil, nil, nil, false
    wasSprinting, dashDirection = false, nil
    local newRoot = newCharacter:WaitForChild('HumanoidRootPart', 10)
    local newHumanoid = newCharacter:WaitForChild('Humanoid', 10)
    if not Session.Alive or Character ~= newCharacter then return end
    Root, Humanoid = newRoot, newHumanoid
    if Humanoid then refreshSpeed() end
end
connect(Player.CharacterAdded, bindCharacter)
bindCharacter(Player.Character or Player.CharacterAdded:Wait())

local function enforceFOV()
    if State.LockFOV and camera and camera.FieldOfView ~= State.FOV then
        camera.FieldOfView = State.FOV
    end
end
local function bindCamera()
    if cameraConnection then cameraConnection:Disconnect() end
    if camera and originalFOV and State.LockFOV then camera.FieldOfView = originalFOV end
    camera = workspace.CurrentCamera
    originalFOV = camera and camera.FieldOfView
    if camera then
        cameraConnection = camera:GetPropertyChangedSignal('FieldOfView'):Connect(enforceFOV)
        enforceFOV()
    end
end
connect(workspace:GetPropertyChangedSignal('CurrentCamera'), bindCamera)
bindCamera()

local Window = Library:CreateWindow({ Title='Sora Hub', Center=true, AutoShow=true, TabPadding=8, MenuFadeTime=0.2 })
local Main = Window:AddTab('Main')
local FarmTab = Window:AddTab('Autofarm')
local Settings = Window:AddTab('Settings')
local UITab = Window:AddTab('UI Settings')
local Defense = Main:AddLeftGroupbox('Defense')
local Aim = Main:AddRightGroupbox('Aim')
local Movement = Main:AddRightGroupbox('Speed Demon')
local PositionGroup = Main:AddLeftGroupbox('Auto Position')
local FarmGroup = FarmTab:AddLeftGroupbox('Training Room')
local General = Settings:AddLeftGroupbox('General')
local CameraGroup = Settings:AddRightGroupbox('Camera')
local Menu = Settings:AddLeftGroupbox('Menu')
local function toggle(group, name, label, key, onChanged)
    local id = 'Sora' .. name
    local control = group:AddToggle(id, { Text=label, Default=State[name] })
    if key then
        control:AddKeyPicker(id .. 'Key', { Default=key, SyncToggleState=true, Mode='Toggle', Text=label, NoUI=false })
    end
    Toggles[id]:OnChanged(function()
        State[name] = Toggles[id].Value
        if onChanged then onChanged(State[name]) end
    end)
end

toggle(Defense, 'AutoTrap', 'Auto Trap', 'F2')
toggle(Defense, 'AutoTackle', 'Auto Tackle', 'F3')
toggle(Defense, 'TDImmunity', 'TD Immunity', 'F4', function() pendingPlayer = nil end)
toggle(Defense, 'AutoM2', 'Auto M2', 'F5')
toggle(Defense, 'AutoBike', 'Auto Bike', 'F1', function() bikeArmed = false end)
toggle(Aim, 'AutoAim', 'Auto Aim', 'Space', function(enabled)
    if enabled and not State.AimAllowed then Toggles.SoraAutoAim:SetValue(false) end
    if not State.AutoAim then releaseRotation() end
end)
toggle(General, 'AimAllowed', 'Allow Auto Aim', nil, function(enabled)
    if not enabled then Toggles.SoraAutoAim:SetValue(false); releaseRotation() end
end)
toggle(Movement, 'SpeedDemon', 'Speed Demon', nil, refreshSpeed)
Movement:AddSlider('SoraSpeedBoost', { Text='Speed Boost', Default=0.75, Min=0, Max=5, Rounding=2, Compact=false })
Options.SoraSpeedBoost:OnChanged(function()
    State.SpeedBoost = Options.SoraSpeedBoost.Value
    refreshSpeed()
end)
toggle(PositionGroup, 'AutoPosition', 'Auto Position')
PositionGroup:AddDropdown('SoraTeam', { Text='Team', Values={'1','2'}, Default=1 })
Options.SoraTeam:OnChanged(function() State.Team=tonumber(Options.SoraTeam.Value) end)
PositionGroup:AddDropdown('SoraPosition', { Text='Position', Values={'Forward','LeftWinger','RightWinger','LeftDef','RightDef'}, Default=1 })
Options.SoraPosition:OnChanged(function() State.Position=Options.SoraPosition.Value end)
FarmGroup:AddLabel('Training room only. Starts disabled.')
FarmGroup:AddLabel('Farm claims Team 1 / Forward.')
-- Training-only dependencies are looked up only when the feature is enabled.
local farmCleanup
local function trainingCommands()
    local folder=RS:FindFirstChild('TrainingRoomRemotes')
    local commands=folder and folder:FindFirstChild('Commands')
    return commands and commands:IsA('RemoteEvent') and commands or nil
end
toggle(FarmGroup, 'AutoFarm', 'Auto Farm', nil, function(enabled)
    if enabled and (not trainingCommands() or not Remotes:FindFirstChild('ChoosePosition')) then
        Toggles.SoraAutoFarm:SetValue(false)
        Library:Notify('Autofarm is available in the training room only.',5)
    elseif not enabled and farmCleanup then farmCleanup() end
end)
CameraGroup:AddButton({ Text='Remove Camera Shake', Func=function()
    if shaker then return end
    local modules = RS:FindFirstChild('Modules')
    local module = modules and modules:FindFirstChild('CameraShaker')
    if not module then Library:Notify('CameraShaker module was not found.', 4); return end
    local loaded, value = pcall(require, module)
    if not loaded or type(value) ~= 'table' or type(value.Update) ~= 'function' then
        Library:Notify('CameraShaker could not be loaded.', 4); return
    end
    shaker, oldShake = value, value.Update
    noShake = function() return CFrame.new() end
    shaker.Update = noShake
    Library:Notify('Camera shake removed.', 3)
end })
toggle(CameraGroup, 'LockFOV', 'Lock FOV', nil, function(enabled)
    if enabled then enforceFOV() elseif camera and originalFOV then camera.FieldOfView = originalFOV end
end)
CameraGroup:AddSlider('SoraFOV', { Text='FOV', Default=75, Min=40, Max=120, Rounding=0, Compact=false })
Options.SoraFOV:OnChanged(function() State.FOV = Options.SoraFOV.Value; enforceFOV() end)

local function getTeam(player)
    local teams = RS:FindFirstChild('Teams')
    if teams then
        for _, team in ipairs(teams:GetChildren()) do
            for _, value in pairs(team:GetAttributes()) do
                if value == player.Name then return team end
            end
        end
    end
end
local function sameTeam(player)
    local mine, theirs = getTeam(Player), getTeam(player)
    return mine ~= nil and mine == theirs
end
local function iframes(character)
    return character:FindFirstChild('IFrames') or character:FindFirstChild('SuperIFrames')
end
local function closePlayer(player)
    if typeof(player) ~= 'Instance' or not player:IsA('Player') or player == Player then return false end
    local otherRoot = player.Character and player.Character:FindFirstChild('HumanoidRootPart')
    return Root and Root.Parent and otherRoot and (Root.Position-otherRoot.Position).Magnitude <= 30
end
local function selectedTrap()
    local gui = Player:FindFirstChild('PlayerGui')
    gui = gui and gui:FindFirstChild('SkilsGui', true)
    local selection = gui and gui:FindFirstChild('SelectionImage')
    if not selection or not selection:IsA('GuiObject') or not selection.Visible then return end
    local nearest, distance = nil, math.huge
    for _, slot in ipairs(gui:GetChildren()) do
        local label = slot:FindFirstChild('SkillName')
        if slot:IsA('GuiObject') and string.find(slot.Name, 'Slot') and label and (label:IsA('TextLabel') or label:IsA('TextButton')) then
            local delta = math.abs(slot.AbsolutePosition.X-selection.AbsolutePosition.X)
            if delta < distance then nearest, distance = label.Text, delta end
        end
    end
    return nearest
end
local trapActions = { ['Creative Trap']='UseSkill', ['Black Hole Trap']='UseSkill', ['Zero Reset Turn']='Hold', ['Dragon Drive']='Hold' }
connect(Event.OnClientEvent, function(action, player, style, skill)
    if not Session.Alive or not player or player == Player then return end
    local now = os.clock()
    if State.AutoTrap and action == 'Hold' and (skill == 'Impact Shot' or skill == 'Explosive Kick') and now-lastTrap >= 0.2 then
        local selected = selectedTrap()
        if selected and trapActions[selected] then
            lastTrap = now
            Event:FireServer(trapActions[selected], selected)
        end
    end
    if not State.TDImmunity or style ~= 'Total Defense' then return end
    if pendingPlayer and now-pendingAt > 5 then pendingPlayer = nil end
    if skill == 'Defensive Stance' then
        if action == 'Hold' and not pendingPlayer and closePlayer(player) then
            pendingPlayer, pendingAt = player, now
            Event:FireServer('Hold', 'Fake Volley Shot')
        elseif action == 'UseSkill' and pendingPlayer == player then
            pendingPlayer = nil
            Event:FireServer('UseSkill', 'Fake Volley Shot')
        end
    elseif action == 'Kick' and skill == 'Defensive Rush' and closePlayer(player) and now-lastRush >= 0.15 then
        lastRush = now
        Event:FireServer('UseSkill', 'Creative Trap')
    end
end)

-- Preserve the original sequence: slot number, then the next LMB, lob first.
-- One permanent input listener avoids stacking callbacks on repeated slot presses.
local impactKey
local slotKeys = {
    SlotOne=Enum.KeyCode.One, SlotTwo=Enum.KeyCode.Two, SlotThree=Enum.KeyCode.Three,
    SlotFour=Enum.KeyCode.Four, SlotFive=Enum.KeyCode.Five, SlotSix=Enum.KeyCode.Six,
    SlotSeven=Enum.KeyCode.Seven, SlotEight=Enum.KeyCode.Eight, SlotNine=Enum.KeyCode.Nine,
}
local function scanBikeSlot(equipped)
    impactKey, bikeArmed = nil, false
    for attribute, key in pairs(slotKeys) do
        if equipped:GetAttribute(attribute) == 'Impact Bicycle' then
            impactKey = key
            print('Sora Hub: Impact Bicycle found in:', attribute)
            return true
        end
    end
    warn('Sora Hub: Impact Bicycle was not found. Equip it, then use Rescan Auto Bike Slot.')
    return false
end
local equipped = Player:FindFirstChild('EquippedSkills')
if equipped then
    scanBikeSlot(equipped)
else
    -- Wait for replication through an event without delaying hub startup.
    local addedConnection
    addedConnection = connect(Player.ChildAdded, function(child)
        if child.Name == 'EquippedSkills' then
            addedConnection:Disconnect()
            scanBikeSlot(child)
        end
    end)
end
Defense:AddButton({Text='Rescan Auto Bike Slot', Func=function()
    local skills=Player:FindFirstChild('EquippedSkills')
    if skills and scanBikeSlot(skills) then
        Library:Notify('Auto Bike slot: ' .. impactKey.Name,4)
    else
        Library:Notify('Impact Bicycle was not found in EquippedSkills.',4)
    end
end})
local function bikeInput(input, processed)
    if not Session.Alive or not State.AutoBike then return end
    -- The original LMB listener does NOT reject gameProcessed input.
    -- Only the slot-selection input uses that filter.
    if bikeArmed and input.UserInputType == Enum.UserInputType.MouseButton1 then
        bikeArmed = false
        local currentCharacter = Player.Character
        local ball = currentCharacter and currentCharacter:FindFirstChild('Ball')
        local currentRoot = currentCharacter and currentCharacter:FindFirstChild('HumanoidRootPart')
        if not ball or not currentRoot then return end
        Punch:FireServer('LobPass', ball, currentRoot.Position + Vector3.new(0,50,0))
        Event:FireServer('UseSkill', 'Impact Bicycle')
        return
    end
    if processed or UIS:GetFocusedTextBox() then return end
    if impactKey and input.KeyCode == impactKey then bikeArmed = true end
end
connect(UIS.InputBegan, bikeInput)

local function gameBall(players)
    if workspace:GetAttribute('GameEnded') then return end
    for _, object in ipairs(workspace:GetChildren()) do
        if object.Name == 'Ball' and object:GetAttribute('GameBall') then
            local ball = object:FindFirstChild('Ball')
            if ball and ball:IsA('BasePart') then return ball end
        end
    end
    for _, player in ipairs(players) do
        local folder = player.Character and player.Character:FindFirstChild('Ball')
        if folder and folder:GetAttribute('GameBall') then
            local ball = folder:FindFirstChild('Ball')
            if ball and ball:IsA('BasePart') then return ball end
        end
    end
end
local function bicycleTrap(players, now)
    -- Retain the last owner after the ball leaves their character, as in the pasted trap.
    for _, player in ipairs(players) do
        local folder = player.Character and player.Character:FindFirstChild('Ball')
        if folder and folder:GetAttribute('GameBall') then lastOwner = player; break end
    end
    if not lastOwner or lastOwner == Player or lastOwner.Parent ~= Players or now-lastBikeTrap < 0.2 then return end
    local character = lastOwner.Character
    local humanoid = character and character:FindFirstChildOfClass('Humanoid')
    local root = character and character:FindFirstChild('HumanoidRootPart')
    if not humanoid or not root then return end
    local animator = humanoid:FindFirstChildOfClass('Animator')
    if not animator then return end
    for _, track in ipairs(animator:GetPlayingAnimationTracks()) do
        if track.Animation and track.Animation.AnimationId:match('%d+$') == '14085400141' then
            local ball = gameBall(players)
            if ball and (ball.Position-root.Position).Magnitude < 12.35 then
                lastBikeTrap = now
                Event:FireServer('UseSkill', 'Black Hole Trap')
            end
            return
        end
    end
end
local function defenseStep(now)
    local players = Players:GetPlayers()
    if State.AutoTrap then bicycleTrap(players, now) end
    if not Root or not Root.Parent or not Character then return end
    for _, player in ipairs(players) do
        if player ~= Player then
            local character = player.Character
            local root = character and character:FindFirstChild('HumanoidRootPart')
            local folder = character and character:FindFirstChild('Ball')
            local ball = folder and folder:FindFirstChild('Ball')
            if root and ball and ball:IsA('BasePart') then
                -- Auto M2 preserves the supplied targeting behavior; tackle checks teams.
                if State.AutoM2 and not Character:FindFirstChild('Ball') and now-lastM2 >= 0.1 and (root.Position-Root.Position).Magnitude <= 23 then
                    lastM2 = now
                    Punch:FireServer('TakeBall', ball)
                end
                if State.AutoTackle and now-lastTackle >= 0.5 and not sameTeam(player) and not iframes(character) then
                    local predicted = ball.Position+ball.AssemblyLinearVelocity*0.12
                    if (Root.Position-predicted).Magnitude <= 8 then
                        lastTackle = now
                        Tackle:FireServer('TackleBegin')
                        if not sameTeam(player) and not iframes(character) and ball:IsDescendantOf(character) then
                            Tackle:FireServer('Tackle', ball, Root.CFrame*CFrame.new(0,-1.5,0))
                        end
                    end
                end
            end
        end
    end
end

local rayParams = RaycastParams.new()
rayParams.FilterType = Enum.RaycastFilterType.Include
local function aimStep()
    if not State.AutoAim or not State.AimAllowed or not Root or not Root.Parent or not Humanoid or Humanoid.Health <= 0 then
        releaseRotation(); return false
    end
    local corners, walls = workspace:FindFirstChild('Corners'), workspace:FindFirstChild('FinalWalls')
    local currentCamera = workspace.CurrentCamera
    if not corners or not walls or not currentCamera then releaseRotation(); return false end
    rayParams.FilterDescendantsInstances = { walls }
    local hit = workspace:Raycast(currentCamera.CFrame.Position, currentCamera.CFrame.LookVector*10000, rayParams)
    if not hit then releaseRotation(); return false end
    local target, minimum = nil, math.huge
    for i=1,4 do
        local corner = corners:FindFirstChild('Corner' .. i)
        if corner and corner:IsA('BasePart') then
            local distance = (hit.Position-corner.Position).Magnitude
            if distance < minimum then target, minimum = corner.Position, distance end
        end
    end
    if not target then releaseRotation(); return false end
    local flatTarget = Vector3.new(target.X, Root.Position.Y, target.Z)
    if (flatTarget-Root.Position).Magnitude < 0.001 then releaseRotation(); return false end
    lockRotation()
    Root.CFrame = CFrame.new(Root.Position, flatTarget)
    return true
end
local function movementStep()
    if not State.SpeedDemon or not Root or not Root.Parent or not Humanoid then dashDirection=nil; return end
    local isSprinting = sprinting() and true or false
    -- Skill state only chooses the boost for the next game-authored speed change.
    -- Never force WalkSpeed to 30 or rewrite it on slider/toggle/respawn.
    wasSprinting = isSprinting
    local velocity = Root:FindFirstChild('BodyVelocity')
    if velocity and velocity:IsA('BodyVelocity') and not boostedVelocities[velocity] then
        local magnitude = velocity.Velocity.Magnitude
        if magnitude >= 57 and magnitude < 58 then
            local currentCamera = workspace.CurrentCamera
            local look = currentCamera and currentCamera.CFrame.LookVector
            local flat = look and Vector3.new(look.X, 0, look.Z)
            if flat and flat.Magnitude > 0.001 then
                dashDirection = flat.Unit*magnitude*1.2
                velocity.Velocity = dashDirection
                boostedVelocities[velocity] = true
            end
        elseif magnitude >= 24 and magnitude < 26 then
            velocity.Velocity = velocity.Velocity*1.2
            boostedVelocities[velocity] = true
        end
    end
    if not Player:GetAttribute('UsingSkill') then dashDirection = nil end
end
-- Nonblocking position selection, using the original team/position identifiers.
local lastPositionAttempt=-math.huge
local function choosingPositions()
    local gui=Player:FindFirstChild('PlayerGui')
    local statusGui=gui and gui:FindFirstChild('GameStatusGui')
    local status=statusGui and statusGui:FindFirstChild('GameStatus')
    if not status or not (status:IsA('TextLabel') or status:IsA('TextButton')) then return false end
    local seconds=tonumber(status.Text:match('^Choosing positions: (%d+) Seconds left$'))
    return seconds and seconds>=1 and seconds<=10
end
local function hasPosition(team,position)
    local teams=RS:FindFirstChild('Teams')
    local folder=teams and teams:FindFirstChild(tostring(team))
    return folder and tostring(folder:GetAttribute(position))==Player.Name
end
local function positionStep(now,team,position)
    if now-lastPositionAttempt<0.15 or not choosingPositions() or hasPosition(team,position) then return end
    local remote=Remotes:FindFirstChild('ChoosePosition')
    if remote and remote:IsA('RemoteEvent') then
        lastPositionAttempt=now
        remote:FireServer(position,team)
    end
end
local farmPhase, farmPhaseAt='idle',0
local lastFarmTackle=-math.huge
local collisionValues={}
local farmSpot=CFrame.new(-459.389282,-93.0298462,-368.699829,
    -0.999780118,1.15958221e-08,-0.0209698491,
    1.13763603e-08,1,1.05849018e-08,
    0.0209698491,1.03440136e-08,-0.999780118)
local function restoreCollision()
    for part,value in pairs(collisionValues) do
        if part.Parent then part.CanCollide=value end
    end
    table.clear(collisionValues)
end
farmCleanup=function()
    restoreCollision()
    farmPhase,farmPhaseAt='idle',0
end
connect(RunService.Stepped,function()
    if not Session.Alive or not State.AutoFarm or farmPhase~='playing' or not Player:GetAttribute('Playing') then return end
    if Character then
        for _,part in ipairs(Character:GetDescendants()) do
            if part:IsA('BasePart') then
                if collisionValues[part]==nil then collisionValues[part]=part.CanCollide end
                part.CanCollide=false
            end
        end
    end
end)
connect(Player.CharacterRemoving,function() restoreCollision() end)
local function farmStep(now)
    if not State.AutoFarm then return end
    local commands=trainingCommands()
    if not commands then
        Toggles.SoraAutoFarm:SetValue(false)
        Library:Notify('Autofarm stopped: training room is unavailable.',4)
        return
    end
    if farmPhase=='idle' then
        if Player:GetAttribute('Playing') then
            farmPhase='playing'
        else
            commands:FireServer('Begin Game')
            farmPhase='starting'
        end
        farmPhaseAt=now
    elseif farmPhase=='starting' then
        positionStep(now,1,'Forward')
        if Player:GetAttribute('Playing') then
            farmPhase,farmPhaseAt='playing',now
        elseif now-farmPhaseAt>30 then
            Toggles.SoraAutoFarm:SetValue(false)
            Library:Notify('Autofarm stopped: match did not start within 30 seconds.',5)
        end
    elseif farmPhase=='playing' then
        if not Player:GetAttribute('Playing') then
            restoreCollision()
            farmPhase,farmPhaseAt='between',now
            return
        end
        if not Root or not Root.Parent or not Humanoid or Humanoid.Health<=0 or Humanoid.WalkSpeed==0 then return end
        Root.CFrame=farmSpot
        if now-lastFarmTackle>=0.1 then
            local ball=gameBall(Players:GetPlayers())
            if ball and ball.Parent then
                lastFarmTackle=now
                Tackle:FireServer('TackleBegin')
                Tackle:FireServer('Tackle',ball,ball.CFrame)
            end
        end
    elseif farmPhase=='between' and now-farmPhaseAt>=0.25 then
        farmPhase='idle'
    end
end
local elapsed = 0
connect(RunService.Heartbeat, function(dt)
    if not Session.Alive then return end
    movementStep()
    local now=os.clock()
    farmStep(now)
    if State.AutoPosition and not State.AutoFarm then positionStep(now,State.Team,State.Position) end
    elapsed = elapsed+dt
    if elapsed >= 0.03 then
        elapsed = 0
        if State.AutoTrap or State.AutoTackle or State.AutoM2 then defenseStep(os.clock()) end
        if pendingPlayer and os.clock()-pendingAt > 5 then pendingPlayer = nil end
    end
end)
connect(RunService.RenderStepped, function()
    if not Session.Alive then return end
    local aiming = aimStep()
    if not aiming and State.SpeedDemon and dashDirection and Root and Root.Parent then
        Root.CFrame = CFrame.new(Root.Position, Root.Position+dashDirection)
    end
end)

-- Custom appearance controls; recolor existing widgets and future toggle states.
local Appearance = UITab:AddLeftGroupbox('Colors')
local Layout = UITab:AddRightGroupbox('Window')
local function setAccent(newColor)
    local previous=accent
    accent=newColor
    for _,object in ipairs(Gui:GetDescendants()) do
        if object:IsA('GuiObject') then
            if object.BackgroundColor3==previous then object.BackgroundColor3=newColor end
            if (object:IsA('TextLabel') or object:IsA('TextButton') or object:IsA('TextBox')) and object.TextColor3==previous then object.TextColor3=newColor end
            if object:IsA('ScrollingFrame') and object.ScrollBarImageColor3==previous then object.ScrollBarImageColor3=newColor end
        end
    end
end
local presets={
    Purple=Color3.fromRGB(147,112,255), Blue=Color3.fromRGB(75,150,255),
    Cyan=Color3.fromRGB(40,195,210), Green=Color3.fromRGB(65,180,115),
    Pink=Color3.fromRGB(220,95,170), Red=Color3.fromRGB(225,80,90),
    Orange=Color3.fromRGB(225,140,55),
}
Appearance:AddDropdown('SoraAccentPreset',{Text='Accent preset',Values={'Purple','Blue','Cyan','Green','Pink','Red','Orange'},Default=1})
for _,channel in ipairs({'Red','Green','Blue'}) do
    local defaults={Red=147,Green=112,Blue=255}
    Appearance:AddSlider('SoraColor'..channel,{Text=channel,Default=defaults[channel],Min=0,Max=255,Rounding=0})
end
local syncingColor=false
local function rgbChanged()
    if not syncingColor then setAccent(Color3.fromRGB(Options.SoraColorRed.Value,Options.SoraColorGreen.Value,Options.SoraColorBlue.Value)) end
end
for _,channel in ipairs({'Red','Green','Blue'}) do Options['SoraColor'..channel]:OnChanged(rgbChanged) end
local function applyPreset(name)
    local color=presets[name]
    syncingColor=true
    Options.SoraColorRed:SetValue(math.floor(color.R*255+0.5))
    Options.SoraColorGreen:SetValue(math.floor(color.G*255+0.5))
    Options.SoraColorBlue:SetValue(math.floor(color.B*255+0.5))
    syncingColor=false
    setAccent(color)
end
Options.SoraAccentPreset:OnChanged(function() applyPreset(Options.SoraAccentPreset.Value) end)
Layout:AddSlider('SoraUIScale',{Text='UI Size (%)',Default=100,Min=70,Max=130,Rounding=0})
Options.SoraUIScale:OnChanged(function() uiZoom=Options.SoraUIScale.Value/100; fit() end)
Layout:AddSlider('SoraUITransparency',{Text='Window Transparency (%)',Default=0,Min=0,Max=70,Rounding=0})
Options.SoraUITransparency:OnChanged(function() root.BackgroundTransparency=Options.SoraUITransparency.Value/100 end)
State.ShowKeyHints=true
toggle(Layout,'ShowKeyHints','Show Keybind Hints',nil,function(value) footer.Visible=value end)
Layout:AddDropdown('SoraMenuKeyChoice',{Text='Show / Hide Key',Values={'End','Insert','RightShift','Home'},Default=1})
Options.SoraMenuKeyChoice:OnChanged(function()
    menuKey=Options.SoraMenuKeyChoice.Value
    if Options.SoraMenuKey then Options.SoraMenuKey.Value=menuKey end
end)
Layout:AddButton({Text='Center Window',Func=function() root.Position=UDim2.fromScale(0.5,0.5) end})
Layout:AddButton({Text='Reset UI Settings',Func=function()
    Options.SoraAccentPreset:SetValue('Purple')
    Options.SoraUIScale:SetValue(100)
    Options.SoraUITransparency:SetValue(0)
    Toggles.SoraShowKeyHints:SetValue(true)
    Options.SoraMenuKeyChoice:SetValue('End')
    root.Position=UDim2.fromScale(0.5,0.5)
end})

local function cleanup()
    if not Session.Alive then return end
    Session.Alive = false
    State.AutoFarm=false
    if farmCleanup then farmCleanup() end
    for _, connection in ipairs(Session.Connections) do connection:Disconnect() end
    if speedConnection then speedConnection:Disconnect() end
    if cameraConnection then cameraConnection:Disconnect() end
    restoreSpeed()
    releaseRotation()
    if camera and originalFOV and State.LockFOV then camera.FieldOfView = originalFOV end
    if shaker and shaker.Update == noShake then shaker.Update = oldShake end
    pendingPlayer, bikeArmed = nil, false
    if Env.SoraHubSession == Session then Env.SoraHubSession = nil end
end
Session.Cleanup = cleanup
Library:OnUnload(cleanup)
Menu:AddButton({ Text='Unload Sora Hub', Func=function() cleanup(); Library:Unload() end })
Menu:AddLabel('Change menu key in UI Settings.')
Library:Notify('Sora Hub loaded. F1: Bike | F2-F5: defense | End: menu', 6)
