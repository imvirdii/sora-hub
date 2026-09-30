-- Sora Hub | Custom UI, no third-party UI library.
-- Client script; requires the same execution environment as the source project.
-- F1 Bike | F2 Trap | F3 Tackle | F4 TD Immunity | F5 Auto M2 | Space Aim | End Menu

local Env = getgenv()
-- These are PlaceIds, not the shared universe GameId.
local HubMode=({
    [12694155368]='Basic', -- Main Game
    [12868032990]='Basic', -- Training Room
    [13864400206]='Daily Challenge',
    [12467817668]='Auto Spin', -- Main Lobby
})[game.PlaceId]
if not HubMode then warn('Sora Hub: this place is not supported.');return end
-- Players excluded from targeted automation. Add exact Roblox usernames here.
local Exceptions = {
    ["TheNextNagi"] = true,
    ["LeoTheDominican"] = true,
}
local function isExcepted(player)
    return player ~= nil and Exceptions[player.Name] == true
end
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
local hoverTip=ui('TextLabel',Gui,{Visible=false,ZIndex=30,Size=UDim2.fromOffset(230,52),
    BackgroundColor3=Color3.fromRGB(27,28,40),BackgroundTransparency=0.05,BorderSizePixel=0,
    Text='',TextColor3=Color3.new(1,1,1),Font=Enum.Font.Gotham,TextSize=11,
    TextWrapped=true,TextXAlignment=Enum.TextXAlignment.Center,TextYAlignment=Enum.TextYAlignment.Center})
rounded(hoverTip,7)
ui('UIStroke',hoverTip,{Color=Color3.fromRGB(90,82,122),Thickness=1})
local function placeHoverTip()
    local pointer=UIInput:GetMouseLocation()
    local camera=workspace.CurrentCamera
    local viewport=camera and camera.ViewportSize or Vector2.new(900,650)
    hoverTip.Position=UDim2.fromOffset(math.max(0,math.min(pointer.X+14,viewport.X-236)),
        math.max(0,math.min(pointer.Y+14,viewport.Y-58)))
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
local function visibility() root.Visible=not root.Visible; reopen.Visible=not root.Visible;hoverTip.Visible=false end
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
footer.TextScaled=true
footer.Position=UDim2.new(0,18,1,-28); footer.TextColor3=muted
local pages={}
local keys={}
local keyControls={}
local pendingKey, capturedInput
local function keyHints()
    local hints={}
    for _,key in ipairs(keyControls) do
        if key.Value~='None' then table.insert(hints,key.Value..' '..key.ShortName) end
    end
    return table.concat(hints,'   ')
end
local function beginKeyCapture(key)
    if pendingKey then pendingKey:Refresh() end
    pendingKey=key
    key.Button.Text='Press key...'
    Library:Notify('Press a key. Escape: cancel | Backspace: unbind',8)
end
local function createKeyControl(id, name, default, button, callback, badge)
    local key={Value='None',Default=default,Name=name,ShortName=name,Button=button}
    function key:Refresh()
        if self.Button then self.Button.Text=self.Name..': '..self.Value end
        if badge then badge.Text=self.Value end
    end
    function key:SetValue(value)
        if value~='None' and (not Enum.KeyCode[value] or value=='Unknown' or value=='Escape' or value=='Backspace') then return false end
        for _,other in ipairs(keyControls) do
            if other~=self and value~='None' and other.Value==value then
                Library:Notify(value..' is already assigned to '..other.Name,4)
                return false
            end
        end
        if self.Value~='None' then keys[self.Value]=nil end
        self.Value=value
        if value~='None' then keys[value]=callback end
        if id=='SoraMenuKey' then menuKey=value end
        self:Refresh()
        footer.Text=keyHints()
        return true
    end
    Options[id]=key
    table.insert(keyControls,key)
    key:SetValue(default)
    if button then listen(button.Activated,function() beginKeyCapture(key) end) end
    return key
end
local function row(parent,height)
    return ui('Frame',parent,{Size=UDim2.new(1,0,0,height or 36),BackgroundTransparency=1})
end
local function groupMethods(parent)
    local group={}
    function group:AddToggle(id, info)
        local holder=row(parent)
        local button=ui('TextButton',holder,{Text='',AutoButtonColor=false,BackgroundTransparency=1,Size=UDim2.fromScale(1,1)})
        if info.Tooltip then
            listen(button.MouseEnter,function() hoverTip.Text=info.Tooltip;placeHoverTip();hoverTip.Visible=true end)
            listen(button.MouseMoved,function() if hoverTip.Visible then placeHoverTip() end end)
            listen(button.MouseLeave,function() hoverTip.Visible=false end)
        end
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
            local badge=label(holder,keyInfo.Default,9)
            badge.TextColor3=muted; badge.TextXAlignment=Enum.TextXAlignment.Right
            badge.Size=UDim2.fromOffset(70,20); badge.Position=UDim2.new(1,-119,0.5,-10)
            caption.Size=UDim2.new(1,-125,1,0)
            createKeyControl(keyId,keyInfo.Text,keyInfo.Default,nil,function() self:SetValue(not self.Value) end,badge)
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
        local control={Value=info.Multi and {} or info.Values[info.Default or 1]}
        local items={}
        function control:SetValue(value)
            if info.Multi then
                if type(value)~='table' then return end
                self.Value={}
                local count=0
                for _,choice in ipairs(info.Values) do
                    if value[choice] then self.Value[choice]=true;count=count+1 end
                    if items[choice] then items[choice].Text=(value[choice] and '✓ ' or '')..choice end
                end
                button.Text=count==0 and 'Choose targets  ▾' or tostring(count)..' selected  ▾'
            else
                if not table.find(info.Values,value) then return end
                self.Value=value; button.Text=value .. '  ▾'
                choices.Visible=false; holder.Size=UDim2.new(1,0,0,60)
            end
            if self.Callback then self.Callback() end
        end
        function control:OnChanged(callback) self.Callback=callback end
        for _,value in ipairs(info.Values) do
            local item=ui('TextButton',choices,{Text=value,Font=Enum.Font.Gotham,TextSize=12,TextColor3=Color3.new(1,1,1),BackgroundColor3=Color3.fromRGB(48,42,65),Size=UDim2.new(1,0,0,26),BorderSizePixel=0})
            items[value]=item
            rounded(item,5)
            listen(item.Activated,function()
                if info.Multi then
                    local selected=table.clone(control.Value)
                    selected[value]=not selected[value] or nil
                    control:SetValue(selected)
                else control:SetValue(value) end
            end)
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
        function control:SetText(value) textLabel.Text=value end
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
        if not self.Unloaded then footer.Text=keyHints() end
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
    if pendingKey then
        capturedInput=input
        if input.UserInputType~=Enum.UserInputType.Keyboard then return end
        local key=pendingKey
        local name=input.KeyCode.Name
        if name=='Escape' then
            pendingKey=nil; key:Refresh(); footer.Text=keyHints()
        elseif key:SetValue(name=='Backspace' and 'None' or name) then
            pendingKey=nil
        end
        return
    end
    if input.KeyCode.Name==menuKey then visibility(); return end
    -- Preserve standalone aim input even when Roblox handles the rebound key.
    local aimKey=Options.SoraAutoAimKey
    if processed and not (aimKey and input.KeyCode.Name==aimKey.Value) then return end
    local callback=keys[input.KeyCode.Name]
    if callback then callback() end
end)

-- Specialized versions return before any match-only dependencies or loops load.
if HubMode~='Basic' then
    local RS=game:GetService('ReplicatedStorage')
    local RunService=game:GetService('RunService')
    local session={Alive=true,Connections={}}
    Env.SoraHubSession=session
    title.Text='SORA HUB | '..HubMode
    footer.Text='End Menu'
    local window=Library:CreateWindow()
    local farming=window:AddTab('Farming')
    local settings=window:AddTab('UI Settings')
    local menu=settings:AddRightGroupbox('Menu')
    local layout=settings:AddLeftGroupbox('Window')
    local menuButton=menu:AddButton({Text='Menu: End',Func=function() end})
    createKeyControl('SoraMenuKey','Menu','End',menuButton,visibility)
    layout:AddSlider('SoraUIScale',{Text='UI Size (%)',Default=100,Min=70,Max=130,Rounding=0})
    Options.SoraUIScale:OnChanged(function() uiZoom=Options.SoraUIScale.Value/100;fit() end)
    layout:AddButton({Text='Center Window',Func=function() root.Position=UDim2.fromScale(0.5,0.5) end})
    menu:AddButton({Text='Unload Sora Hub',Func=function() Library:Unload() end})
    Library:OnUnload(function()
        session.Alive=false
        if Env.SoraHubSession==session then Env.SoraHubSession=nil end
    end)
    session.Cleanup=function() Library:Unload() end
    local function remote(name)
        local folder=RS:FindFirstChild('Remotes')
        local object=folder and folder:FindFirstChild(name)
        return object and object:IsA('RemoteEvent') and object or nil
    end

    if HubMode=='Daily Challenge' then
        local group=farming:AddLeftGroupbox('Daily Challenge')
        group:AddLabel('Supports the 3 original layouts.')
        group:AddLabel('Starts disabled. Stop at any time.')
        local status=group:AddLabel('Status: idle')
        local auto=group:AddToggle('SoraAutoDailyChallenge',{Text='Auto Daily Challenge',Default=false,
            Tooltip='Uses the original shots for three known layouts. Unknown layouts are not fired on.'})
        local layouts={
            {spot=Vector3.new(342.4703674316406,3.814638137817383,-713.7109985351562),
             direction=Vector3.new(0.9485578536987305,-0.28204798698425293,0.1438293308019638),
             facing=Vector3.new(0.9885718822479248,0.016017595306038857,0.14989666640758514)},
            {spot=Vector3.new(298.120361328125,3.814638137817383,-758.5650024414062),
             direction=Vector3.new(0.17995981872081757,-0.3644046187400818,-0.9136869311332703),
             facing=Vector3.new(0.19315169751644135,0.01585335098206997,-0.9810408353805542)},
            {spot=Vector3.new(253.4203643798828,3.814638137817383,-713.7109985351562),
             direction=Vector3.new(-0.9260265231132507,-0.3074670732021332,-0.21894952654838562),
             facing=Vector3.new(-0.9730885624885559,0.016010480001568794,-0.2298746258020401)},
        }
        local elapsed,lastShot,heldBall,attempts=0,-math.huge,nil,0
        auto:OnChanged(function()
            elapsed,lastShot,heldBall,attempts=0,-math.huge,nil,0
            if auto.Value and not remote('UseKeyboardSkillRemote') then
                auto:SetValue(false)
                status:SetText('Shot remote unavailable.')
            else status:SetText(auto.Value and 'Waiting for the ball...' or 'Status: stopped') end
        end)
        listen(RunService.Heartbeat,function(dt)
            if not session.Alive or not auto.Value then return end
            elapsed=elapsed+dt
            if elapsed<0.2 then return end
            elapsed=0
            local character=UIPlayer.Character
            local ball=character and character:FindFirstChild('Ball')
            local humanoid=character and character:FindFirstChildOfClass('Humanoid')
            if not ball or not humanoid or humanoid.Health<=0 then
                heldBall,attempts=nil,0
                status:SetText('Waiting for the ball...')
                return
            end
            if ball~=heldBall then heldBall,attempts=ball,0 end
            local field=workspace:FindFirstChild('GameField')
            local keepers=field and field:FindFirstChild('BlueLockmans')
            local spot=keepers and keepers:FindFirstChild('Spot1')
            if not spot or not spot:IsA('BasePart') then status:SetText('Waiting for challenge layout...');return end
            local shot
            for _,entry in ipairs(layouts) do
                if (spot.Position-entry.spot).Magnitude<=0.75 then shot=entry;break end
            end
            if not shot then status:SetText('Unrecognized layout; waiting.');return end
            if os.clock()-lastShot<0.75 then return end
            if attempts>=3 then
                auto:SetValue(false)
                status:SetText('No shot accepted; paused.')
                return
            end
            local event=remote('UseKeyboardSkillRemote')
            if not event then auto:SetValue(false);status:SetText('Shot remote unavailable.');return end
            lastShot,attempts=os.clock(),attempts+1
            local ok=pcall(function() event:FireServer('PunchBall',ball,1.25,shot.direction,shot.facing) end)
            if not ok then auto:SetValue(false);status:SetText('Shot request failed; paused.');return end
            status:SetText('Shot sent; waiting for next ball.')
        end)
    else
        local group=farming:AddLeftGroupbox('Auto Spin')
        local targets=farming:AddRightGroupbox('Stop On These Results')
        group:AddLabel('Consumes your available spins.')
        group:AddLabel('Never purchases spins or Robux.')
        group:AddDropdown('SoraSpinType',{Text='Spin Type',Values={'Weapon','Prodigy'},Default=1})
        group:AddDropdown('SoraSpinSlot',{Text='Weapon Slot',Values={'1','2','3'},Default=1})
        group:AddSlider('SoraSpinLimit',{Text='Max Requests This Run',Default=25,Min=1,Max=500,Rounding=0})
        targets:AddDropdown('SoraSpinWeapons',{Text='Wanted Weapons',Multi=true,Values={
            'Direct Shot','Finesse Shot','Explosive Acceleration','Stealthy Steps','Jumping Power',
            'Immense Speed','Mark Smell','Drive Shot','Elastic Dribbling','Trapping',
            'Perfect Kick Accuracy','Villainous Soccer','Total Defense','Godspeed','Kaiser Impact'}})
        targets:AddDropdown('SoraSpinProdigies',{Text='Wanted Prodigies',Multi=true,
            Values={'None','Intellect','Punch','Defense','Speed','Dribble','Ball Control'}})
        targets:AddLabel('Choose one or more wanted results.')
        targets:AddLabel('Stops before rerolling a match.')
        local status=group:AddLabel('Status: idle')
        local resultLabel=group:AddLabel('Current: --')
        local countLabel=group:AddLabel('Requests: 0')
        local auto=group:AddToggle('SoraAutoSpin',{Text='Auto Spin',Default=false,
            Tooltip='Spends available spins until a chosen result or run limit. Pauses if a result is not confirmed.'})
        local count,pending,elapsed,spinData=0,nil,0,nil
        local function selection()
            local weapon=Options.SoraSpinType.Value=='Weapon'
            return weapon and ('Weapon'..Options.SoraSpinSlot.Value) or 'Prodigy',
                weapon and Options.SoraSpinWeapons.Value or Options.SoraSpinProdigies.Value,
                weapon and 'SpinWeapon' or 'SpinProdigy'
        end
        local function stop(message)
            if auto.Value then auto:SetValue(false) end
            status:SetText(message)
        end
        local function spinCounts(data)
            local counts={}
            -- The source does not document balance names. Observe replicated
            -- numeric spin counters when available; never assume a wallet API.
            for name,value in pairs(data:GetAttributes()) do
                if type(value)=='number' and name:lower():find('spin',1,true) then counts[name]=value end
            end
            return counts
        end
        auto:OnChanged(function()
            pending,elapsed=nil,0
            if not auto.Value then status:SetText('Status: stopped');return end
            count=0
            countLabel:SetText('Requests: 0')
            local attribute,wanted,eventName=selection()
            spinData=UIPlayer:FindFirstChild('Data')
            if not next(wanted) then stop('Choose wanted results first.');return end
            if not spinData or spinData:GetAttribute(attribute)==nil then stop('Slot / data unavailable.');return end
            if not remote(eventName) then stop('Spin remote unavailable.');return end
            status:SetText('Status: starting')
        end)
        for _,id in ipairs({'SoraSpinType','SoraSpinSlot','SoraSpinWeapons','SoraSpinProdigies','SoraSpinLimit'}) do
            Options[id]:OnChanged(function()
                if auto.Value then stop('Settings changed; restart to spin.') end
            end)
        end
        listen(RunService.Heartbeat,function(dt)
            if not session.Alive or not auto.Value then return end
            elapsed=elapsed+dt
            if elapsed<0.1 then return end
            elapsed=0
            local attribute,wanted,eventName=selection()
            if UIPlayer:FindFirstChild('Data')~=spinData or not spinData then stop('Player data changed; paused.');return end
            local current=spinData:GetAttribute(attribute)
            if type(current)~='string' then stop('Result unavailable; paused.');return end
            resultLabel:SetText('Current: '..current)
            if wanted[current] then stop('Found: '..current);return end
            local now=os.clock()
            if pending then
                local confirmed=current~=pending.before
                if not confirmed then
                    for name,previous in pairs(pending.counts) do
                        local value=spinData:GetAttribute(name)
                        if type(value)=='number' and value<previous then confirmed=true;break end
                    end
                end
                if confirmed and not pending.confirmedAt then pending.confirmedAt=now end
                -- Allow the result to follow a balance update before another request.
                if pending.confirmedAt and now-pending.confirmedAt>=0.75 and now-pending.sent>=1 then
                    pending=nil
                elseif now-pending.sent>=10 then stop('No result confirmed; paused.');return
                else return end
            end
            if count>=Options.SoraSpinLimit.Value then stop('Run limit reached.');return end
            local event=remote(eventName)
            if not event then stop('Spin remote unavailable.');return end
            pending={before=current,counts=spinCounts(spinData),sent=now}
            count=count+1
            countLabel:SetText('Requests: '..count)
            local ok=pcall(function()
                if eventName=='SpinWeapon' then event:FireServer(tonumber(Options.SoraSpinSlot.Value))
                else event:FireServer() end
            end)
            if not ok then stop('Spin request failed; paused.');return end
            status:SetText('Waiting for spin result...')
        end)
    end
    Library:Notify('Sora Hub '..HubMode..' loaded. Farming starts disabled.',6)
    return
end

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
    AutoTrap = false, AutoTackle = false, TDImmunity = false, AutoDribble=false, DribbleRange=15,
    AutoTD = false, TDRange = 8, TDPrediction = 0.12, TDAdaptive=true, TDHold=0.4, AutoM2 = false, AutoAim = false, ShootAfterAimed = false, AimAllowed = true, AutoBike = true, AutoAimBike = false,
    AutoPosition = false, Team = 1, Position = 'Forward', AutoFarm = false,
    BallPrediction=false, BallETA=false, ReboundAlert=false, PassReception=false, OffscreenBall=false, OpponentCooldowns=false, OpponentReady=false, HighlightTDs=false, CooldownRange=80,
    SpeedDemon = true, SpeedBoost = 0.75, LockFOV = false, FOV = 85, CanonKaiser=true,
}
local Character, Root, Humanoid
local speedConnection, speedBase, speedWritten
local pendingPlayer, pendingAt, bikeArmed = nil, 0, false
local bikeAimUntil=0
local aimStep
local lastTrap, lastBikeTrap, lastRush, lastTackle, lastM2 = -math.huge, -math.huge, -math.huge, -math.huge, -math.huge
local lastAutoTD,tdFacingUntil,tdTarget=-math.huge,0,nil
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
-- PowerLocal.TakeBall uses this animation with Action3 priority.
local takeBallAnimation=Instance.new('Animation')
takeBallAnimation.AnimationId='rbxassetid://12698914098'
local takeBallTrack, takeBallAnimator
local lastTakeBallAnimation=-math.huge
local function clearTakeBallAnimation()
    if takeBallTrack then
        takeBallTrack:Stop(0.1)
        takeBallTrack:Destroy()
    end
    takeBallTrack,takeBallAnimator=nil,nil
    lastTakeBallAnimation=-math.huge
end
local function playTakeBallAnimation(now)
    if not Humanoid or not Humanoid.Parent or Humanoid.Health<=0 then return end
    local animator=Humanoid:FindFirstChildOfClass('Animator')
    if not animator then return end
    if takeBallAnimator~=animator then clearTakeBallAnimation() end
    if now-lastTakeBallAnimation<1 or (takeBallTrack and takeBallTrack.IsPlaying) then return end
    lastTakeBallAnimation=now
    if not takeBallTrack then
        local ok,track=pcall(function() return animator:LoadAnimation(takeBallAnimation) end)
        if not ok then return end
        takeBallTrack,takeBallAnimator=track,animator
        takeBallTrack.Priority=Enum.AnimationPriority.Action3
        takeBallTrack.Looped=false
    end
    takeBallTrack:Play(0.1)
end
local function bindCharacter(newCharacter)
    clearTakeBallAnimation()
    releaseRotation()
    if speedConnection then speedConnection:Disconnect() end
    restoreSpeed()
    Character, Root, Humanoid = newCharacter, nil, nil
    speedBase, speedWritten, pendingPlayer, bikeArmed = nil, nil, nil, false
    bikeAimUntil=0
    wasSprinting, dashDirection = false, nil
    tdFacingUntil,tdTarget=0,nil
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

local updateCanonKaiser,cleanupCanonKaiser
do
    local animation=Instance.new('Animation')
    animation.AnimationId='rbxassetid://13732545430'
    local listener,replay,animator
    local generation=0
    local phase='idle'
    local function reset()
        generation=generation+1
        phase='idle'
        if listener then listener:Disconnect();listener=nil end
        if replay then replay:Stop(0.1);replay:Destroy();replay=nil end
        animator=nil
    end
    local function bind(character)
        reset()
        if not State.CanonKaiser or not Session.Alive or not character then return end
        local token=generation
        task.spawn(function()
            local humanoid=character:WaitForChild('Humanoid',10)
            local current=humanoid and humanoid:WaitForChild('Animator',10)
            if not current or not Session.Alive or not State.CanonKaiser or token~=generation or Player.Character~=character then return end
            animator=current
            local function onPlayed(track)
                if token~=generation or not State.CanonKaiser or not Session.Alive or track==replay then return end
                if not track.Animation or track.Animation.AnimationId:match('%d+$')~='13732545430' then return end
                if phase=='cooldown' then return end
                track:Stop(0.1)
                if phase=='suppressing' then return end
                phase='suppressing'
                -- Original timing: suppress for 0.25 seconds, replay, pause 1.5 seconds.
                task.delay(0.25,function()
                    if token~=generation or not Session.Alive or not State.CanonKaiser or Player.Character~=character or humanoid.Health<=0 then return end
                    if not replay then
                        local ok,result=pcall(function() return current:LoadAnimation(animation) end)
                        if not ok then phase='idle';return end
                        replay=result
                    end
                    phase='cooldown'
                    replay:Play()
                    task.delay(1.5,function()
                        if token==generation then phase='idle' end
                    end)
                end)
            end
            listener=current.AnimationPlayed:Connect(onPlayed)
            -- Catch a matching animation already running when enabled.
            for _,track in ipairs(current:GetPlayingAnimationTracks()) do onPlayed(track) end
        end)
    end
    updateCanonKaiser=function() bind(Player.Character) end
    connect(Player.CharacterAdded,bind)
    connect(Player.CharacterRemoving,reset)
    cleanupCanonKaiser=function() reset();animation:Destroy() end
    updateCanonKaiser()
end

local Window = Library:CreateWindow({ Title='Sora Hub', Center=true, AutoShow=true, TabPadding=8, MenuFadeTime=0.2 })
local Main = Window:AddTab('Main')
local FarmTab = Window:AddTab('Farming')
local Settings = Window:AddTab('Settings')
local UITab = Window:AddTab('UI Settings')
local Defense = Main:AddLeftGroupbox('Defense')
local Attack = Main:AddRightGroupbox('Attack')
local Movement = Main:AddRightGroupbox('Speed Demon')
local PositionGroup = Main:AddLeftGroupbox('Auto Position')
local FarmGroup = FarmTab:AddLeftGroupbox('Training Room')
local General = Settings:AddLeftGroupbox('General')
local CameraGroup = Settings:AddRightGroupbox('Camera')
local Menu = Settings:AddLeftGroupbox('Menu')
local function toggle(group, name, label, key, onChanged, description)
    local id = 'Sora' .. name
    local control = group:AddToggle(id, { Text=label, Default=State[name], Tooltip=description })
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
toggle(Defense, 'AutoTD', 'Auto TD', 'F6', function(enabled)
    if not enabled then tdFacingUntil,tdTarget=0,nil; releaseRotation() end
end, 'Lines up with the predicted ball path before rushing, then holds its direction. Does not skip enemy IFrames. Range is an activation setting, not a measured hitbox.')
Defense:AddSlider('SoraTDRange',{Text='Auto TD Range',Default=8,Min=4,Max=25,Rounding=0})
Options.SoraTDRange:OnChanged(function() State.TDRange=Options.SoraTDRange.Value end)
Defense:AddSlider('SoraTDPrediction',{Text='Auto TD Prediction (seconds)',Default=0.12,Min=0,Max=0.25,Rounding=2})
Options.SoraTDPrediction:OnChanged(function() State.TDPrediction=Options.SoraTDPrediction.Value end)
toggle(Defense,'TDAdaptive','Adaptive TD Prediction',nil,nil,
    'Adjusts prediction in small steps after accepted rushes that likely missed. Passed balls, interrupted casts and unconfirmed requests do not train it. Learning lasts this session.')
Defense:AddSlider('SoraTDHold',{Text='TD Direction Hold (seconds)',Default=0.4,Min=0.15,Max=0.6,Rounding=2})
Options.SoraTDHold:OnChanged(function() State.TDHold=Options.SoraTDHold.Value end)

toggle(Attack, 'TDImmunity', 'TD Immunity', 'F4', function() pendingPlayer = nil end)
toggle(Defense, 'AutoM2', 'Auto M2', 'F5', function(enabled)
    if not enabled then clearTakeBallAnimation() end
end)
toggle(Attack,'AutoDribble','Auto Dribble','F7',nil,
    'Dodges attack animations and fast opponents closing directly into you. Early prediction can also react to a runner.')
Attack:AddSlider('SoraDribbleRange',{Text='Dribble vs Tackle Range',Default=15,Min=15,Max=30,Rounding=0})
Options.SoraDribbleRange:OnChanged(function() State.DribbleRange=Options.SoraDribbleRange.Value end)
toggle(Attack, 'AutoBike', 'Auto Bike', 'F1', function()
    bikeArmed=false;bikeAimUntil=0
end)
toggle(Attack,'AutoAimBike','Auto Aim Bike',nil,function(enabled)
    bikeAimUntil=0
    if enabled and not State.AimAllowed then Toggles.SoraAutoAimBike:SetValue(false) end
end,'Uses Auto Aim for one second whenever Auto Bike fires, with the same goal corners and crossbar limit.')
toggle(Attack,'CanonKaiser','Canon Kaiser',nil,updateCanonKaiser)
toggle(Attack, 'AutoAim', 'Auto Aim', 'Space', function(enabled)
    if enabled and not State.AimAllowed then Toggles.SoraAutoAim:SetValue(false) end
    if not State.AutoAim then releaseRotation() end
end)
toggle(Attack,'ShootAfterAimed','Shoot After Aimed',nil,function(enabled)
    if enabled and not State.AimAllowed then Toggles.SoraShootAfterAimed:SetValue(false) end
end)
toggle(General, 'AimAllowed', 'Allow Auto Aim', nil, function(enabled)
    if not enabled then
        Toggles.SoraShootAfterAimed:SetValue(false)
        Toggles.SoraAutoAim:SetValue(false)
        Toggles.SoraAutoAimBike:SetValue(false)
        releaseRotation()
    end
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
CameraGroup:AddSlider('SoraFOV', { Text='FOV', Default=85, Min=85, Max=120, Rounding=0, Compact=false })
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
    if not Session.Alive or not player or player == Player or isExcepted(player) then return end
    local now = os.clock()
    if State.AutoTrap and action == 'Hold' and (skill == 'Impact Shot' or skill == 'Explosive Kick') and now-lastTrap >= 0.2 then
        local selected = selectedTrap()
        if selected and trapActions[selected] then
            lastTrap = now
            Event:FireServer(trapActions[selected], selected)
        end
    end
    -- Snake Jump's UseSkill broadcast starts its exported effect animation.
    if State.AutoTrap and action=='UseSkill' and skill=='Snake Jump' and now-lastBikeTrap>=0.2 then
        lastBikeTrap=now
        Event:FireServer('UseSkill','Black Hole Trap')
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
local lastBikeRequest=-math.huge
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
Attack:AddButton({Text='Rescan Auto Bike Slot', Func=function()
    local skills=Player:FindFirstChild('EquippedSkills')
    if skills and scanBikeSlot(skills) then
        Library:Notify('Auto Bike slot: ' .. impactKey.Name,4)
    else
        Library:Notify('Impact Bicycle was not found in EquippedSkills.',4)
    end
end})
local function bikeInput(input, processed)
    if not Session.Alive or not State.AutoBike or pendingKey or input==capturedInput then return end
    -- The original LMB listener does NOT reject gameProcessed input.
    -- Only the slot-selection input uses that filter.
    if bikeArmed and input.UserInputType == Enum.UserInputType.MouseButton1 then
        bikeArmed = false
        local currentCharacter = Player.Character
        local ball = currentCharacter and currentCharacter:FindFirstChild('Ball')
        local currentRoot = currentCharacter and currentCharacter:FindFirstChild('HumanoidRootPart')
        if not ball or not currentRoot then return end
        local now=os.clock()
        if now-lastBikeRequest<0.25 then return end
        local humanoid=currentCharacter:FindFirstChildOfClass('Humanoid')
        local state=Player:FindFirstChild('PlayerStateFolder')
        -- The game's own LMB listener can set UsingSkill/CantPunch/cooldown
        -- before this callback runs. Those snapshots must not veto this click.
        local blocked=not humanoid or humanoid.Health<=0
            or workspace:GetAttribute('PlayersAllowedToUseSkills')==false
            or (state and state:FindFirstChild('Stun'))
        if blocked then
            bikeAimUntil=0
            Library:Notify('Auto Bike blocked: character unavailable, stunned, or skills disabled.',3)
            return
        end
        lastBikeRequest=now
        if State.AutoAimBike and State.AimAllowed then
            bikeAimUntil=os.clock()+1
            if aimStep then aimStep(true) end
        end
        Punch:FireServer('LobPass', ball, currentRoot.Position + Vector3.new(0,50,0))
        Event:FireServer('UseSkill', 'Impact Bicycle')
        return
    end
    if processed or UIS:GetFocusedTextBox() then return end
    if impactKey and input.KeyCode == impactKey then
        bikeArmed=true
    else
        for _,key in pairs(slotKeys) do
            if input.KeyCode==key then bikeArmed=false;break end
        end
    end
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
local bikeResponses=setmetatable({}, {__mode='k'})
local lastSnakeJump=-math.huge
local function snakeJumpReady(now)
    if not State.AutoTD or now-lastSnakeJump<0.5 or now-lastAutoTD<0.5 or now-lastTackle<0.5 then return false end
    if not Character or not Humanoid or Humanoid.Health<=0 or Character:FindFirstChild('Ball') then return false end
    if Player:GetAttribute('UsingSkill') or Character:FindFirstChild('HoldingSkill') then return false end
    if workspace:GetAttribute('PlayersAllowedToUseSkills')==false then return false end
    local playerState=Player:FindFirstChild('PlayerStateFolder')
    if playerState and playerState:FindFirstChild('Stun') then return false end
    local cooldowns=RS:FindFirstChild('CooldownsFolder')
    return not (cooldowns and cooldowns:FindFirstChild(tostring(Player.UserId)..'Snake Jump'))
end
local function bicycleTrap(players, now)
    -- One shared animation scan for Auto Trap and Auto TD.
    for _,player in ipairs(players) do
        local folder=player.Character and player.Character:FindFirstChild('Ball')
        if folder and folder:GetAttribute('GameBall') then lastOwner=player; break end
    end
    if not lastOwner or lastOwner==Player or lastOwner.Parent~=Players or isExcepted(lastOwner) then return false end
    local character=lastOwner.Character
    local humanoid=character and character:FindFirstChildOfClass('Humanoid')
    local root=character and character:FindFirstChild('HumanoidRootPart')
    local animator=humanoid and humanoid:FindFirstChildOfClass('Animator')
    if not root or not animator then return false end
    for _,track in ipairs(animator:GetPlayingAnimationTracks()) do
        if track.Animation and track.Animation.AnimationId:match('%d+$')=='14085400141' then
            local response=bikeResponses[track]
            local position=track.TimePosition
            if not response or position+0.01<response.position then
                response={fired=false}
                bikeResponses[track]=response
            end
            response.seen,response.position=now,position
            if response.fired then return false end
            local ball=gameBall(players)
            if not ball or (ball.Position-root.Position).Magnitude>=12.35 then return false end
            -- Auto Trap owns the bicycle response whenever it is enabled.
            if State.AutoTrap then
                if now-lastBikeTrap<0.2 then return false end
                response.fired=true
                lastBikeTrap=now
                Event:FireServer('UseSkill','Black Hole Trap')
                return true
            elseif not sameTeam(lastOwner) and snakeJumpReady(now) then
                response.fired=true
                lastSnakeJump,lastAutoTD=now,now
                tdTarget,tdFacingUntil=nil,0
                releaseRotation()
                Event:FireServer('UseSkill','Snake Jump')
                return true
            end
            return false
        end
    end
    return false
end
local tdReady,rushTargetValid,tdTargetPosition,startAutoTD,trackAutoTD,observeAutoTD
do
local attempt,leadAdjustment=nil,0
local hits,misses,ignored=0,0,0
local status=Defense:AddLabel('TD learning: waiting for attempts')
Session.TDAttempts={}
local function showStatus()
    status:SetText(string.format('TD: %d hits / %d likely misses / %d uncertain | lead %+.0f ms',hits,misses,ignored,leadAdjustment*1000))
end
local function finishAttempt(result)
    if not attempt then return end
    local a=attempt
    if result=='hit' then hits=hits+1
    elseif result=='likely miss' then
        misses=misses+1
        -- Correct measured sideways error along target movement, not a blind
        -- increase after every timeout. Stationary targets provide no lead signal.
        if a.adaptive and State.TDAdaptive and a.basePrediction==State.TDPrediction
            and a.correction and math.abs(a.correction)>0.005 then
            leadAdjustment=math.clamp(leadAdjustment+math.clamp(a.correction*0.25,-0.015,0.015),-0.06,0.10)
        end
    else ignored=ignored+1 end
    local history=Session.TDAttempts
    if #history>=12 then table.remove(history,1) end
    history[#history+1]={result=result,range=a.range,prediction=a.prediction,
        lateralError=a.bestError,adjustment=leadAdjustment}
    attempt=nil
    showStatus()
end
Defense:AddButton({Text='Reset TD Learning',Func=function()
    attempt,leadAdjustment=nil,0
    hits,misses,ignored=0,0,0
    table.clear(Session.TDAttempts)
    showStatus()
end})
local function targetVelocity(target)
    local velocity=target.root.AssemblyLinearVelocity
    local ballVelocity=target.ball.AssemblyLinearVelocity
    if (ballVelocity-velocity).Magnitude<=20 then
        velocity=velocity*0.65+ballVelocity*0.35
    end
    return velocity
end
tdReady=function(now)
    if attempt then return false end
    if not State.AutoTD or now-lastAutoTD<0.5 or now-lastTackle<0.5 then return false end
    if not Character or not Humanoid or Humanoid.Health<=0 or Character:FindFirstChild('Ball') then return false end
    if Player:GetAttribute('UsingSkill') or Character:FindFirstChild('HoldingSkill') then return false end
    if workspace:GetAttribute('PlayersAllowedToUseSkills')==false then return false end
    local playerState=Player:FindFirstChild('PlayerStateFolder')
    if playerState and playerState:FindFirstChild('Stun') then return false end
    local cooldowns=RS:FindFirstChild('CooldownsFolder')
    if cooldowns and cooldowns:FindFirstChild(tostring(Player.UserId)..'Defensive Rush') then return false end
    -- Read equipped slots only when otherwise ready; no polling while on cooldown.
    local skills=Player:FindFirstChild('EquippedSkills')
    if not skills then return false end
    for slot,skill in pairs(skills:GetAttributes()) do
        if slot:match('^Slot') and skill=='Defensive Rush' then return true end
    end
    return false
end
rushTargetValid=function(target,tracking)
    if not Root or not Root.Parent or not target or target.player.Parent~=Players
        or target.player.Character~=target.character or isExcepted(target.player)
        or not target.ball:IsDescendantOf(target.character)
        or target.root.Parent~=target.character or target.humanoid.Health<=0
        or sameTeam(target.player) then return false end
    local offset=target.ball.Position-Root.Position
    -- Small acquisition margin permits early entry prediction. Tracking gets a
    -- separate exit margin so crossing the slider boundary does not drop aim.
    local margin=tracking and 4 or math.min(3,State.TDRange*0.25)
    if offset.Magnitude>State.TDRange+margin then return false end
    -- Conservative vertical guard, NOT a claim about the server hitbox height.
    if math.abs(offset.Y)>6 then return false end
    return true
end
tdTargetPosition=function(target,remainingTime)
    local offset=target.ball.Position-Root.Position
    local flatDistance=Vector3.new(offset.X,0,offset.Z).Magnitude
    -- A carried ball can have stale/zero velocity. Use its velocity only when
    -- it agrees with the holder; never extrapolate an apparent launch spike.
    local velocity=targetVelocity(target)
    local relative=velocity-Root.AssemblyLinearVelocity
    local prediction=math.clamp(State.TDPrediction+(State.TDAdaptive and leadAdjustment or 0),0,0.25)
        *math.clamp(flatDistance/8,0,1)
    if remainingTime then prediction=math.min(prediction,math.max(0,remainingTime)) end
    local futureOffset=offset+relative*prediction
    local currentDistance,futureDistance=offset.Magnitude,futureOffset.Magnitude
    local closing=currentDistance>0.001 and -offset:Dot(relative)/currentDistance or 0
    -- Stationary and close retreating holders remain valid. Only reject
    -- retreating edge targets projected to escape the configured range.
    local eligible=(currentDistance<=State.TDRange or (closing>0 and futureDistance<=State.TDRange))
        and not (closing<0 and currentDistance>State.TDRange*0.7 and futureDistance>State.TDRange)
        and math.abs(futureOffset.Y)<=6
    local lead=Vector3.new(relative.X,0,relative.Z)*prediction
    local maxLead=math.min(4,flatDistance*0.4)
    if lead.Magnitude>maxLead then lead=lead.Unit*maxLead end
    local predicted=target.ball.Position+lead
    -- Rank by expected proximity; do not mistake 'approaching' for a required
    -- condition when a stationary or slower retreating holder is reachable.
    local direction=predicted-Root.Position
    direction=Vector3.new(direction.X,0,direction.Z)
    if direction.Magnitude<0.001 then return predicted,math.huge,false,prediction end
    direction=direction.Unit
    -- A ray is only an aiming lane, not an invented hitbox width. Favor holders
    -- whose projected position lies along it, with a small cost for large turns.
    local flatFuture=Vector3.new(futureOffset.X,0,futureOffset.Z)
    local along=flatFuture:Dot(direction)
    local lateral=(flatFuture-direction*along).Magnitude
    local turn=1-math.clamp(Root.CFrame.LookVector:Dot(direction),-1,1)
    local score=futureDistance+currentDistance*0.15+lateral*0.5+turn*0.5
    return Vector3.new(predicted.X,Root.Position.Y,predicted.Z),score,eligible and along>0,prediction
end
startAutoTD=function(target,now)
    if tdTarget then return false end
    if not tdReady(now) or not rushTargetValid(target) then return false end
    local flatTarget,_,eligible=tdTargetPosition(target)
    if not eligible then return false end
    if (flatTarget-Root.Position).Magnitude<0.001 then return false end
    lockRotation()
    Root.CFrame=CFrame.new(Root.Position,flatTarget)
    -- Prepare direction now; require a later frame with a stable bearing before
    -- requesting the skill. The timeout prevents chasing an unalignable target.
    target.preparedAt,target.direction=now,nil
    tdTarget,tdFacingUntil=target,now+0.15
    return true
end
trackAutoTD=function(now)
    if not tdTarget then return false end
    if not State.AutoTD or now>=tdFacingUntil or not Root or not Root.Parent
        or not Humanoid or Humanoid.Health<=0 or not Character
        or Character:FindFirstChild('Ball') or not rushTargetValid(tdTarget,true)
        or workspace:GetAttribute('PlayersAllowedToUseSkills')==false
        or (Player:FindFirstChild('PlayerStateFolder') and Player.PlayerStateFolder:FindFirstChild('Stun')) then
        tdTarget=nil
        releaseRotation()
        return false
    end
    if tdTarget.direction then
        -- Fix the bearing after firing: do not sweep the attack or redirect
        -- the outgoing ball while continuing to chase a moving holder.
        lockRotation()
        Root.CFrame=CFrame.new(Root.Position,Root.Position+tdTarget.direction)
        return true
    end
    local position,_,eligible,prediction=tdTargetPosition(tdTarget)
    if not eligible or not tdReady(now) then
        tdTarget=nil;releaseRotation();return false
    end
    local delta=position-Root.Position
    if delta.Magnitude<0.001 then tdTarget=nil;releaseRotation();return false end
    local direction=delta.Unit
    local aligned=Root.CFrame.LookVector:Dot(direction)>=0.985
    lockRotation()
    Root.CFrame=CFrame.new(Root.Position,position)
    if now-tdTarget.preparedAt>=1/60 and aligned then
        tdTarget.direction=direction
        tdFacingUntil=now+State.TDHold
        lastAutoTD=now
        attempt={target=tdTarget,character=Character,sent=now,accepted=false,
            basePrediction=State.TDPrediction,prediction=prediction,adaptive=State.TDAdaptive,
            direction=direction,range=State.TDRange,hold=State.TDHold,bestError=math.huge}
        Event:FireServer('UseSkill','Defensive Rush')
    end
    return true
end
observeAutoTD=function(now)
    local a=attempt
    if not a then return end
    local t=a.target
    local ps=Player:FindFirstChild('PlayerStateFolder')
    if not Session.Alive or not State.AutoTD or Character~=a.character or not Root or not Root.Parent
        or not Humanoid or Humanoid.Health<=0 or (ps and ps:FindFirstChild('Stun'))
        or workspace:GetAttribute('PlayersAllowedToUseSkills')==false then
        finishAttempt('interrupted');return
    end
    local cd=RS:FindFirstChild('CooldownsFolder')
    if cd and cd:FindFirstChild(tostring(Player.UserId)..'Defensive Rush') then a.accepted=true end
    if Character:FindFirstChild('Ball') then a.uncertain=true end
    if t.player.Character~=t.character or t.player.Parent~=Players or t.humanoid.Health<=0
        or isExcepted(t.player) or sameTeam(t.player) or not t.ball:IsDescendantOf(t.character) then
        -- Keep the attempt for a delayed Kick acknowledgement, but never train
        -- a miss from a pass, despawn, or loss of the original ball holder.
        a.uncertain=true
    elseif now-a.sent<=a.hold and not a.uncertain then
        local offset=t.ball.Position-Root.Position
        offset=Vector3.new(offset.X,0,offset.Z)
        local along=offset:Dot(a.direction)
        local cross=offset-a.direction*along
        local error=cross.Magnitude
        if along>0 and along<=a.range+4 and error<a.bestError then
            a.bestError=error
            local velocity=targetVelocity(t)-Root.AssemblyLinearVelocity
            velocity=Vector3.new(velocity.X,0,velocity.Z)
            local sideways=velocity-a.direction*velocity:Dot(a.direction)
            local speedSquared=sideways:Dot(sideways)
            a.correction=speedSquared>=16 and cross:Dot(sideways)/speedSquared or nil
        end
    end
    -- Observation timeout is deliberately separate from direction hold and is
    -- not treated as a measurement of the server hitbox lifetime.
    if now-a.sent>=1.25 then
        finishAttempt(a.accepted and not a.uncertain and a.bestError<math.huge and 'likely miss' or 'uncertain')
    end
end
connect(Event.OnClientEvent,function(action,player,style,skill,ball)
    local a=attempt
    if not a or not Session.Alive or not State.AutoTD or player~=Player then return end
    if style~='Total Defense' or skill~='Defensive Rush' then
        if action=='UseSkill' or action=='Hold' then a.uncertain=true end
        return
    end
    if action=='UseSkill' then a.accepted=true
    elseif action=='Kick' and typeof(ball)=='Instance'
        and (ball==a.target.ball or a.target.ball:IsDescendantOf(ball)) then
        finishAttempt('hit')
        tdTarget,tdFacingUntil=nil,0
        releaseRotation()
    end
end)
end
local function defenseStep(now)
    local players=Players:GetPlayers()
    if (State.AutoTrap or State.AutoTD) and bicycleTrap(players,now) then return end
    if not Root or not Root.Parent or not Character then return end
    local canRush=not tdTarget and tdReady(now)
    local myTeam=canRush and getTeam(Player) or nil
    local rushTarget,rushDistance=nil,math.huge
    local tackleTarget,tackleDistance=nil,math.huge
    for _,player in ipairs(players) do
        if player~=Player and not isExcepted(player) then
            local character=player.Character
            local root=character and character:FindFirstChild('HumanoidRootPart')
            local folder=character and character:FindFirstChild('Ball')
            local ball=folder and folder:FindFirstChild('Ball')
            if root and ball and ball:IsA('BasePart') then
                local holderDistance=(root.Position-Root.Position).Magnitude
                -- Keep Auto M2's original 23-stud activation; animate only within 8.
                if State.AutoM2 and not tdTarget and not Character:FindFirstChild('Ball') and now-lastM2>=0.1 and holderDistance<=23 then
                    lastM2=now
                    if holderDistance<=8 then playTakeBallAnimation(now) end
                    Punch:FireServer('TakeBall',ball)
                end
                if canRush then
                    local theirTeam=getTeam(player)
                    local humanoid=character:FindFirstChildOfClass('Humanoid')
                    local distance=(ball.Position-Root.Position).Magnitude
                    if (not myTeam or theirTeam~=myTeam) and humanoid and humanoid.Health>0
                        and distance<=State.TDRange+math.min(3,State.TDRange*0.25)
                        and math.abs(ball.Position.Y-Root.Position.Y)<=6 then
                        local candidate={player=player,character=character,root=root,humanoid=humanoid,ball=ball}
                        local _,score,eligible=tdTargetPosition(candidate)
                        if eligible and score<rushDistance then
                            rushDistance,rushTarget=score,candidate
                        end
                    end
                end
                if State.AutoTackle and not tdTarget and now-lastTackle>=0.5 and now-lastAutoTD>=0.5
                    and not sameTeam(player) and not iframes(character) then
                    local predicted=ball.Position+ball.AssemblyLinearVelocity*0.12
                    local distance=(Root.Position-predicted).Magnitude
                    if distance<=8 and distance<tackleDistance then
                        tackleDistance=distance
                        tackleTarget={player=player,character=character,ball=ball}
                    end
                end
            end
        end
    end
    -- Prefer a ready Defensive Rush, with one defensive skill request per scan.
    if rushTarget and startAutoTD(rushTarget,now) then return end
    if tackleTarget then
        local target=tackleTarget
        if isExcepted(target.player) or sameTeam(target.player) or iframes(target.character) or not target.ball:IsDescendantOf(target.character) then return end
        lastTackle=now
        Tackle:FireServer('TackleBegin')
        Tackle:FireServer('Tackle',target.ball,Root.CFrame*CFrame.new(0,-1.5,0))
    end
end

-- Resolve real goal mouths; no helper parts or per-frame raycast allocations.
do
    local goals,nextRefresh,selected,side={},0,nil,nil
    local previousDirection,previousGoal,previousSide
    local function refreshGoals(now)
        nextRefresh=now+2
        local found={}
        local function inspect(model)
            local mouth=model:FindFirstChild('LineHitbox')
            if not mouth or not mouth:IsA('BasePart') then return end
            local bar
            for _,p in ipairs(model:GetChildren()) do
                if p.Name=='Shtanga' and p:IsA('BasePart') and p.Size.Y<math.max(p.Size.X,p.Size.Z) then
                    if not bar or p.Position.Y>bar.Position.Y then bar=p end
                end
            end
            if bar then found[#found+1]={mouth=mouth,bar=bar} end
        end
        for _,object in ipairs(workspace:GetChildren()) do
            inspect(object)
            if object.Name=='GameField' or object.Name=='MiniField' then
                for _,child in ipairs(object:GetChildren()) do inspect(child) end
            end
        end
        goals=found
    end
    aimStep=function(forBike)
        local function stop()
            selected,side=nil,nil
            previousDirection,previousGoal,previousSide=nil,nil,nil
            releaseRotation()
            return false
        end
        if not (State.AutoAim or forBike) or not State.AimAllowed then return stop() end
        if not Root or not Root.Parent or not Humanoid or Humanoid.Health<=0 then return stop() end
        local camera=workspace.CurrentCamera
        if not camera or camera.CameraType==Enum.CameraType.Scriptable then return stop() end
        local now=os.clock()
        if now>=nextRefresh then refreshGoals(now) end
        local frame=camera.CFrame
        local horizontal=Vector3.new(frame.LookVector.X,0,frame.LookVector.Z)
        if frame.LookVector.Y>0.94 or horizontal.Magnitude<0.001 then
            -- Looking nearly straight up makes camera yaw a poor goal selector.
            local facing=selected and selected.Parent and (selected.Position-Root.Position) or Root.CFrame.LookVector
            horizontal=Vector3.new(facing.X,0,facing.Z)
        end
        if horizontal.Magnitude<0.001 then return stop() end
        horizontal=horizontal.Unit
        local goal,hit,tBest=nil,nil,math.huge
        for _,g in ipairs(goals) do
            local mouth=g.mouth
            if mouth.Parent and g.bar.Parent and math.abs(mouth.Position.Y-Root.Position.Y)<45 then
                local origin=mouth.CFrame:PointToObjectSpace(frame.Position)
                local look=mouth.CFrame:VectorToObjectSpace(horizontal)
                if math.abs(look.X)>0.001 then
                    local t=-origin.X/look.X
                    if t>0 and t<tBest and t<2000 then
                        goal,hit,tBest=g,origin+look*t,t
                    end
                end
            end
        end
        if not goal then return stop() end
        local mouth,bar=goal.mouth,goal.bar
        if selected~=mouth then selected=mouth;side=hit.Z>=0 and 1 or -1 end
        -- A small centre dead zone prevents left/right flicker.
        if hit.Z>1 then side=1 elseif hit.Z< -1 then side=-1 end
        local folder=Character and Character:FindFirstChild('Ball')
        local ball=folder and folder:FindFirstChild('Ball')
        local margin=1.5
        local origin=Root.Position
        if ball and ball:IsA('BasePart') then
            margin=math.max(ball.Size.X,ball.Size.Y,ball.Size.Z)*0.5+0.75
            origin=ball.Position
        end
        local cf,size=bar.CFrame,bar.Size
        local halfHeight=(math.abs(cf.RightVector.Y)*size.X+math.abs(cf.UpVector.Y)*size.Y+math.abs(cf.LookVector.Y)*size.Z)*0.5
        -- Keep the camera's maximum aim visibly below the underside of the bar.
        local ceiling=bar.Position.Y-halfHeight-math.max(2,margin)
        local width=math.max(0,mouth.Size.Z*0.5-margin)
        local corner=mouth.CFrame:PointToWorldSpace(Vector3.new(0,0,side*width))
        local target=Vector3.new(corner.X,Root.Position.Y,corner.Z)
        local delta=target-Root.Position
        if delta.Magnitude<0.1 then return stop() end
        local shotHorizontal=Vector3.new(corner.X-origin.X,0,corner.Z-origin.Z)
        local shotFlat=shotHorizontal.Magnitude
        if shotFlat<0.1 then return stop() end
        -- Cap both the shot-origin angle and the camera ray at the crossbar.
        -- This bounds the aim direction, not server-authored curve/lift physics.
        local maxPitch=math.atan2(ceiling-origin.Y,math.max(shotFlat,0.1))
        -- Shot direction starts at the ball, not the offset third-person camera.
        local shotYaw=shotHorizontal.Unit
        local cameraLocal=mouth.CFrame:PointToObjectSpace(frame.Position)
        local yawLocal=mouth.CFrame:VectorToObjectSpace(shotYaw)
        if math.abs(yawLocal.X)<0.001 then return stop() end
        local cameraFlat=-cameraLocal.X/yawLocal.X
        if cameraFlat<0.1 then return stop() end
        maxPitch=math.min(maxPitch,math.atan2(ceiling-frame.Position.Y,math.max(cameraFlat,0.1)))
        local pitch=math.asin(math.clamp(frame.LookVector.Y,-1,1))
        local aimPitch=math.min(pitch,maxPitch)
        local shotDirection=shotYaw*math.cos(aimPitch)+Vector3.new(0,math.sin(aimPitch),0)
        -- Align at every pitch, including views already below the crossbar.
        if frame.LookVector:Dot(shotDirection)<0.999999 then
            camera.CFrame=CFrame.lookAt(frame.Position,frame.Position+shotDirection)
        end
        lockRotation()
        local direction=delta.Unit
        local facingSettled=Root.CFrame.LookVector:Dot(direction)>0.99985
        if Root.CFrame.LookVector:Dot(direction)<0.999999 then
            Root.CFrame=CFrame.lookAt(Root.Position,target)
        end
        local stable=previousGoal==mouth and previousSide==side and previousDirection
            and previousDirection:Dot(shotDirection)>0.99985
        previousGoal,previousSide,previousDirection=mouth,side,shotDirection
        -- A rush can overwrite facing between frames. Don't count our own
        -- correction as evidence that the game has stopped overriding it.
        return stable and facingSettled and true or false
    end
end
-- Original PowerfulShot priority and remote sequences, after a successful aim.
local shootAfterAimStep
do
    local possession,nextCheck,sent=nil,0,false
    local cleanMotionFrames=0
    local function motionReady()
        if not Root or not Root.Parent then cleanMotionFrames=0;return false end
        local velocity=Root.AssemblyLinearVelocity
        local fast=Vector3.new(velocity.X,0,velocity.Z).Magnitude>45
        local body=Root:FindFirstChildOfClass('BodyVelocity')
        local linear=Root:FindFirstChildOfClass('LinearVelocity')
        local driven=(body and body.Velocity.Magnitude>2 and body.MaxForce.Magnitude>0)
            or (linear and linear.Enabled)
        if fast or driven then cleanMotionFrames=0;return false end
        -- Two clean render frames replace the fixed post-rush delay.
        cleanMotionFrames=math.min(cleanMotionFrames+1,2)
        return cleanMotionFrames==2
    end
    local function readyShot()
        local equipped=Player:FindFirstChild('EquippedSkills')
        local gui=Player:FindFirstChild('PlayerGui')
        local hotbar=gui and gui:FindFirstChild('SkilsGui',true)
        local cooldowns=RS:FindFirstChild('CooldownsFolder')
        local available,blocked={},{}
        if equipped then
            for slot,skill in pairs(equipped:GetAttributes()) do
                if slot:match('^Slot') and (skill=='Impact Shot' or skill=='Explosive Kick') then
                    available[skill]=true
                end
            end
        end
        if hotbar then
            for _,slot in ipairs(hotbar:GetChildren()) do
                local name=slot:FindFirstChild('SkillName')
                if name and (name:IsA('TextLabel') or name:IsA('TextButton')) then
                    local skill=name.Text
                    if skill=='Impact Shot' or skill=='Explosive Kick' then
                        available[skill]=true
                        local cd=slot:FindFirstChild('CDFrame')
                        if cd and cd:IsA('GuiObject') and cd.Visible then blocked[skill]=true end
                    end
                end
            end
        end
        for _,skill in ipairs({'Impact Shot','Explosive Kick'}) do
            if available[skill] and not blocked[skill]
                and not (cooldowns and cooldowns:FindFirstChild(tostring(Player.UserId)..skill)) then
                return skill
            end
        end
    end
    shootAfterAimStep=function(aimed)
        local ball=Character and Character:FindFirstChild('Ball')
        if not Session.Alive or not State.ShootAfterAimed or not State.AutoAim or not State.AimAllowed or not ball then
            possession,nextCheck,sent=nil,0,false
            cleanMotionFrames=0
            return
        end
        if ball~=possession then possession,nextCheck,sent=ball,0,false;cleanMotionFrames=0 end
        if sent or game.PlaceId==12467817668 then return end
        local movementReady=motionReady()
        if not movementReady or not aimed then nextCheck=0;return end
        if not Humanoid or Humanoid.Health<=0 or Player:GetAttribute('UsingSkill')
            or workspace:GetAttribute('PlayersAllowedToUseSkills')==false then return end
        local state=Player:FindFirstChild('PlayerStateFolder')
        if state and (state:FindFirstChild('Stun') or state:FindFirstChild('CantPunch')) then return end
        local now=os.clock()
        if now<nextCheck then return end
        -- Only the hotbar scan is throttled; movement/facing are checked each frame.
        nextCheck=now+0.03
        local skill=readyShot()
        if not skill then return end
        sent=true
        Event:FireServer('Hold',skill)
        if skill=='Explosive Kick' then Event:FireServer('UseSkill',skill) end
    end
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
                local holder=ball.Parent.Parent and Players:GetPlayerFromCharacter(ball.Parent.Parent)
                if isExcepted(holder) then return end
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
        observeAutoTD(now)
        if State.AutoTrap or State.AutoTackle or State.AutoM2 or State.AutoTD then defenseStep(os.clock()) end
        if pendingPlayer and os.clock()-pendingAt > 5 then pendingPlayer = nil end
    end
end)
local aimRenderName='SoraHubAim'
RunService:BindToRenderStep(aimRenderName,Enum.RenderPriority.Last.Value+1,function()
    if not Session.Alive then return end
    local now=os.clock()
    if not State.AutoBike or not State.AutoAimBike or not State.AimAllowed then
        bikeAimUntil=0
    end
    local bikeAiming=now<bikeAimUntil
    if trackAutoTD(now) then shootAfterAimStep(false);return end
    local aimed=aimStep(bikeAiming)
    shootAfterAimStep(aimed and not bikeAiming and not (State.AutoBike and bikeArmed))
    if not ((State.AutoAim or bikeAiming) and State.AimAllowed) and State.SpeedDemon and dashDirection and Root and Root.Parent then
        Root.CFrame = CFrame.new(Root.Position, Root.Position+dashDirection)
    end
end)

-- React to attack animation starts; cooldown replication arrives too late.
local cleanupDribble=(function()
    local lastDribble=-math.huge
    local tackleThreats={}
    local watchers={}
    local lastAgainst={}
    -- Tackle ID inferred from the user's isolated tackle capture after excluding
    -- the exported idle/walk/run IDs. TakeBall is verified in PowerLocal.
    local attackAnimations={['12698810109']=0.9,['12698914098']=0.45}
    local function react(player,now,isM2)
        if not Session.Alive or not State.AutoDribble or now-lastDribble<0.35 then return false end
        if not player or player==Player or isExcepted(player) or sameTeam(player) then return false end
        if now-(lastAgainst[player] or -math.huge)<0.9 then return false end
        if not Character or not Character:FindFirstChild('Ball') or not Root or not Root.Parent
            or not Humanoid or Humanoid.Health<=0 or Character:FindFirstChild('CantDribble') or iframes(Character) then return false end
        if workspace:GetAttribute('PlayersAllowedToUseSkills')==false then return false end
        -- PowerLocal permits dribbling out of a charged punch.
        if Player:GetAttribute('UsingSkill') and not Character:FindFirstChild('BeganChargingPunch') then return false end
        local ps=Player:FindFirstChild('PlayerStateFolder')
        if ps and ps:FindFirstChild('Stun') then return false end
        local other=player.Character
        local otherRoot=other and other:FindFirstChild('HumanoidRootPart')
        if not otherRoot then return false end
        local offset=otherRoot.Position-Root.Position
        local range=isM2 and 8 or State.DribbleRange
        if offset.Magnitude>range then
            if isM2 then return false end
            -- Account for approach during the request's travel to the server.
            if offset.Magnitude>range+4 then return false end
            local relative=otherRoot.AssemblyLinearVelocity-Root.AssemblyLinearVelocity
            local speedSquared=relative:Dot(relative)
            local ahead=speedSquared>0.01 and math.clamp(-offset:Dot(relative)/speedSquared,0,0.2) or 0
            local lead=relative*ahead
            if lead.Magnitude>4 then lead=lead.Unit*4 end
            if (offset+lead).Magnitude>range then return false end
        end
        local amount=Player:GetAttribute('Dribbles')
        if type(amount)~='number' or amount<1 then return false end
        local away=Root.Position-otherRoot.Position
        local choices={Forward=Root.CFrame.LookVector,Back=-Root.CFrame.LookVector,Right=Root.CFrame.RightVector,Left=-Root.CFrame.RightVector}
        local direction,score=nil,-math.huge
        local incoming=otherRoot.AssemblyLinearVelocity-Root.AssemblyLinearVelocity
        incoming=Vector3.new(incoming.X,0,incoming.Z)
        local costs={Forward=1,Back=1,Right=1,Left=1}
        for _,child in ipairs(Character:GetChildren()) do
            if child.Name=='DribblesIncrease' and child:IsA('StringValue') and costs[child.Value] then costs[child.Value]=costs[child.Value]+1 end
        end
        for name,vector in pairs(choices) do
            local value=away:Dot(vector)
            if incoming.Magnitude>12 and away:Dot(incoming)>0 then
                -- Retreating straight backwards stays in a head-on tackle's path.
                value=value*0.2+(1-math.abs(vector:Dot(incoming.Unit)))*math.max(away.Magnitude,4)
            end
            if amount>=costs[name] and value>score then direction,score=name,value end
        end
        if not direction then return false end
        lastDribble=now
        lastAgainst[player]=now
        Tackle:FireServer('Dribble',direction)
        return true
    end
    local function unwatch(player)
        local watcher=watchers[player]
        if watcher then
            for _,connection in pairs(watcher) do connection:Disconnect() end
            watchers[player]=nil
        end
        tackleThreats[player]=nil
        lastAgainst[player]=nil
    end
    local function watch(player)
        if player==Player or watchers[player] then return end
        local watcher={}
        watchers[player]=watcher
        local function bind(character)
            if watcher.animation then watcher.animation:Disconnect();watcher.animation=nil end
            if watcher.descendant then watcher.descendant:Disconnect();watcher.descendant=nil end
            tackleThreats[player]=nil
            lastAgainst[player]=nil
            local function attach(animator)
                if watcher.animation or not animator:IsA('Animator') or not animator.Parent:IsA('Humanoid') then return end
                watcher.animation=animator.AnimationPlayed:Connect(function(track)
                    if not Session.Alive or not State.AutoDribble or player.Character~=character then return end
                    local id=track.Animation and track.Animation.AnimationId:match('%d+$')
                    local window=id and attackAnimations[id]
                    if not window or track.TimePosition>window then return end
                    if isExcepted(player) or sameTeam(player) then return end
                    local now=os.clock()
                    local active=tackleThreats[player]
                    if active and active.track==track and now<active.expires then return end
                    local isM2=id=='12698914098'
                    tackleThreats[player]={character=character,track=track,isM2=isM2,
                        expires=now+math.min(window,(window-track.TimePosition)/math.max(math.abs(track.Speed),0.1)),
                        fired=react(player,now,isM2)}
                end)
            end
            watcher.descendant=character.DescendantAdded:Connect(attach)
            local humanoid=character:FindFirstChildOfClass('Humanoid')
            local animator=humanoid and humanoid:FindFirstChildOfClass('Animator')
            if animator then attach(animator) end
        end
        watcher.character=player.CharacterAdded:Connect(bind)
        if player.Character then bind(player.Character) end
    end
    for _,player in ipairs(Players:GetPlayers()) do watch(player) end
    connect(Players.PlayerAdded,watch)
    connect(Players.PlayerRemoving,unwatch)
    local elapsed=0
    connect(RunService.Heartbeat,function(dt)
        if not Session.Alive then return end
        if not State.AutoDribble then
            table.clear(tackleThreats)
            return
        end
        elapsed=elapsed+dt
        if elapsed<0.03 then return end
        elapsed=0
        local now=os.clock()
        for player,threat in pairs(tackleThreats) do
            if now>=threat.expires or not threat.track.IsPlaying or player.Parent~=Players or player.Character~=threat.character then
                tackleThreats[player]=nil
            elseif not threat.fired and react(player,now,threat.isM2) then
                threat.fired=true
            end
        end
        -- Replicated animations can arrive after contact. Check only imminent,
        -- direct approaches while we possess the ball; never treat this as a
        -- confirmed tackle or depend on late cooldown replication.
        if now-lastDribble<0.35 or not Character or not Character:FindFirstChild('Ball')
            or not Root or not Root.Parent then return end
        for player in pairs(watchers) do
            local character=player.Character
            local otherRoot=character and character:FindFirstChild('HumanoidRootPart')
            local threat=tackleThreats[player]
            if otherRoot and not (threat and threat.isM2) and not character:FindFirstChild('Ball') and not isExcepted(player) and not sameTeam(player) then
                local offset=otherRoot.Position-Root.Position
                local distance=offset.Magnitude
                if distance>0.1 and distance<=State.DribbleRange+4 and math.abs(offset.Y)<5 then
                    local relative=otherRoot.AssemblyLinearVelocity-Root.AssemblyLinearVelocity
                    local closing=-relative:Dot(offset.Unit)
                    local advancing=-otherRoot.AssemblyLinearVelocity:Dot(offset.Unit)
                    local facing=otherRoot.CFrame.LookVector:Dot(-offset.Unit)
                    if closing>18 and advancing>12 and facing>0.5 and math.max(0,distance-4)/closing<=0.28 then
                        local speedSquared=relative:Dot(relative)
                        local nearestAt=math.clamp(-offset:Dot(relative)/math.max(speedSquared,0.01),0,0.4)
                        if (offset+relative*nearestAt).Magnitude<=3.5 and react(player,now) then break end
                    end
                end
            end
        end
    end)
    return function()
        for player in pairs(watchers) do unwatch(player) end
        table.clear(tackleThreats)
        table.clear(lastAgainst)
    end
end)()

local cleanupMetavision=(function()
-- Local visual aids: no remotes are sent by these features.
local visualFolder=Instance.new('Folder')
visualFolder.Name='SoraHubVisuals'
visualFolder.Parent=workspace
local function visualPart(name)
    local part=Instance.new('Part')
    part.Name=name
    part.Anchored=true
    part.CanCollide=false
    part.CanTouch=false
    part.CanQuery=false
    part.CastShadow=false
    part.Material=Enum.Material.Neon
    part.Transparency=1
    part.Parent=visualFolder
    return part
end
local landingRing,ringFrames={},{}
local ringVisible=false
local ringCenter
-- Precompute the circle once; updates only move the existing segments.
for i=1,20 do
    local part=visualPart('LandingRing'..i)
    part.Color=Color3.fromRGB(255,205,80)
    local a=(i-1)*math.pi*2/20
    local b=i*math.pi*2/20
    local first=Vector3.new(math.cos(a)*2,0,math.sin(a)*2)
    local second=Vector3.new(math.cos(b)*2,0,math.sin(b)*2)
    part.Size=Vector3.new(0.12,0.12,(second-first).Magnitude)
    ringFrames[i]=CFrame.new((first+second)*0.5,second)
    landingRing[i]=part
end
local function hideLanding()
    if not ringVisible then return end
    ringVisible=false
    ringCenter=nil
    for _,part in ipairs(landingRing) do part.Transparency=1 end
end
local etaAnchor=visualPart('BallETAAnchor')
etaAnchor.Size=Vector3.new(0.1,0.1,0.1)
local etaGui=ui('BillboardGui',etaAnchor,{Size=UDim2.fromOffset(60,22),
    StudsOffsetWorldSpace=Vector3.new(0,1.55,0),AlwaysOnTop=true,MaxDistance=180,Enabled=false})
local etaText=ui('TextLabel',etaGui,{Text='',Font=Enum.Font.GothamBold,TextSize=12,
    TextColor3=Color3.fromRGB(255,227,151),BackgroundColor3=Color3.fromRGB(23,24,34),
    BackgroundTransparency=0.22,BorderSizePixel=0,Size=UDim2.fromScale(1,1)})
rounded(etaText,5)
local function hideBallETA() etaGui.Enabled=false end
local visualPlayers,visualBall={},nil
local nextRosterRefresh,nextBallSearch,nextFilterRefresh=0,0,0
local filterBall
local function currentVisualBall(now)
    if now>=nextRosterRefresh then
        visualPlayers=Players:GetPlayers()
        nextRosterRefresh=now+0.5
    end
    if not visualBall or not visualBall:IsDescendantOf(workspace) or now>=nextBallSearch then
        visualBall=gameBall(visualPlayers)
        nextBallSearch=now+0.25
    end
    return visualBall
end
local landingParams=RaycastParams.new()
landingParams.FilterType=Enum.RaycastFilterType.Exclude
landingParams.RespectCanCollide=true
local function visualRayParams(ball,now)
    if now<nextFilterRefresh and filterBall==ball then return landingParams end
    nextFilterRefresh=now+0.5
    filterBall=ball
    local excluded={visualFolder}
    for _,name in ipairs({'Corners','FinalWalls'}) do
        local object=workspace:FindFirstChild(name)
        if object then table.insert(excluded,object) end
    end
    for _,player in ipairs(visualPlayers) do
        if player.Character then table.insert(excluded,player.Character) end
    end
    if ball and ball.Parent then table.insert(excluded,ball.Parent:IsA('Model') and ball.Parent or ball) end
    landingParams.FilterDescendantsInstances=excluded
    return landingParams
end
local function landingPoint(ball,params)
    local position=ball.Position
    local velocity=ball.AssemblyLinearVelocity
    local radius=math.min(ball.Size.X,ball.Size.Y,ball.Size.Z)*0.5
    local ground=workspace:Raycast(position+Vector3.new(0,2,0),Vector3.new(0,-(radius+4),0),params)
    if ground and ground.Normal.Y>=0.7 and position.Y-ground.Position.Y<=radius+0.6
        and math.abs(velocity.Y)<6 then
        -- A rolling ball has already landed: mark its short-term ground position.
        local lead=Vector3.new(velocity.X,0,velocity.Z)*0.35
        if lead.Magnitude>20 then lead=lead.Unit*20 end
        local obstacle=lead.Magnitude>0.05 and workspace:Raycast(position,lead,params)
        if obstacle then lead=obstacle.Position-position end
        local projected=position+lead
        local floor=workspace:Raycast(projected+Vector3.new(0,2,0),Vector3.new(0,-(radius+5),0),params)
        local point=floor and floor.Normal.Y>=0.7 and floor.Position or ground.Position
        local seconds=velocity.Magnitude>2 and lead.Magnitude/math.max(velocity.Magnitude,0.1) or nil
        return point,seconds
    end
    local acceleration=Vector3.new(0,-workspace.Gravity,0)
    local dt=0.1
    local offset=Vector3.new(0,math.max(0,radius-0.05),0)
    for step=1,40 do
        local nextPosition=position+velocity*dt+acceleration*(0.5*dt*dt)
        local hit=workspace:Raycast(position-offset,nextPosition-position,params)
        if hit then
            if hit.Normal.Y>=0.7 then
                local fraction=math.clamp(hit.Distance/math.max((nextPosition-position).Magnitude,0.001),0,1)
                return hit.Position,(step-1+fraction)*dt
            end
            return
        end
        position=nextPosition
        velocity=velocity+acceleration*dt
    end
end
local function updateBallVisuals()
    if not State.BallPrediction and not State.BallETA then return end
    if workspace:GetAttribute('GameEnded') then hideLanding();hideBallETA();return end
    local now=os.clock()
    local ball=currentVisualBall(now)
    if not ball then hideLanding();hideBallETA();return end
    for _,player in ipairs(visualPlayers) do
        if player.Character and ball:IsDescendantOf(player.Character) then hideLanding();hideBallETA();return end
    end
    local landing,seconds=landingPoint(ball,visualRayParams(ball,now))
    if not landing then hideLanding();hideBallETA();return end
    local center=landing+Vector3.new(0,0.12,0)
    if State.BallETA and seconds and seconds>=0.1 then
        etaAnchor.CFrame=CFrame.new(center)
        etaText.Text=string.format('~%.1fs',seconds)
        etaGui.Enabled=true
    else hideBallETA() end
    if not State.BallPrediction then hideLanding();return end
    if ringCenter and (center-ringCenter).Magnitude<0.03 then return end
    local transform=CFrame.new(center)
    for i,part in ipairs(landingRing) do
        part.CFrame=transform*ringFrames[i]
        if not ringVisible then part.Transparency=0.15 end
    end
    ringVisible,ringCenter=true,center
end
-- Two small world markers, allocated once and moved at 10 Hz only when enabled.
local function newCue(name,color,radius)
    local cue={segments={},offsets={},visible=false,radius=radius}
    for i=1,12 do
        local a,b=(i-1)*math.pi/6,i*math.pi/6
        cue.offsets[i]={Vector3.new(math.cos(a),0,math.sin(a)),Vector3.new(math.cos(b),0,math.sin(b))}
        local part=visualPart(name..i)
        part.Color=color
        part.Size=Vector3.new(0.12,0.10,1)
        cue.segments[i]=part
    end
    return cue
end
local reboundCue=newCue('ReboundCue',Color3.fromRGB(255,151,72),1.8)
local receptionCue=newCue('ReceptionCue',Color3.fromRGB(75,220,255),1.5)
local reboundAnchor=visualPart('ReboundLabelAnchor')
reboundAnchor.Size=Vector3.new(0.1,0.1,0.1)
local reboundGui=ui('BillboardGui',reboundAnchor,{Size=UDim2.fromOffset(84,22),
    StudsOffsetWorldSpace=Vector3.new(0,1.8,0),AlwaysOnTop=true,MaxDistance=125,Enabled=false})
local reboundText=ui('TextLabel',reboundGui,{Text='REBOUND',Font=Enum.Font.GothamBold,TextSize=11,
    TextColor3=Color3.fromRGB(255,216,165),BackgroundColor3=Color3.fromRGB(23,24,34),
    BackgroundTransparency=0.22,BorderSizePixel=0,Size=UDim2.fromScale(1,1)})
rounded(reboundText,5)
local function hideCue(cue)
    if not cue.visible then return end
    cue.visible=false
    for _,part in ipairs(cue.segments) do part.Transparency=1 end
    if cue==reboundCue then reboundGui.Enabled=false end
end
local function moveCue(cue,point)
    local center=point+Vector3.new(0,0.14,0)
    if cue.visible and cue.center and (center-cue.center).Magnitude<0.12 then return end
    cue.center=center
    for i,part in ipairs(cue.segments) do
        local ends=cue.offsets[i]
        local first=center+ends[1]*cue.radius
        local second=center+ends[2]*cue.radius
        part.Size=Vector3.new(0.12,0.10,(second-first).Magnitude)
        part.CFrame=CFrame.lookAt((first+second)*0.5,second)
        part.Transparency=0.18
    end
    cue.visible=true
    if cue==reboundCue then
        reboundAnchor.CFrame=CFrame.new(center)
        reboundGui.Enabled=true
    end
end
local reboundBall,previousBounceVelocity,lastReboundAt,reboundUntil=nil,nil,-math.huge,0
local function observeBounce(ball,now)
    if ball~=reboundBall then
        reboundBall,previousBounceVelocity=ball,nil
        reboundUntil=0
    end
    if not State.ReboundAlert or not ball then
        previousBounceVelocity=nil
        hideCue(reboundCue)
        return
    end
    local velocity=ball.AssemblyLinearVelocity
    local previous=previousBounceVelocity
    previousBounceVelocity=velocity
    if previous and now-lastReboundAt>0.65 then
        local horizontal=Vector3.new(velocity.X,0,velocity.Z)
        local priorHorizontal=Vector3.new(previous.X,0,previous.Z)
        local deflected=horizontal.Magnitude>18 and priorHorizontal.Magnitude>18
            and horizontal:Dot(priorHorizontal)<0.55*horizontal.Magnitude*priorHorizontal.Magnitude
        local bouncedUp=previous.Y< -14 and velocity.Y>12 and previous.Magnitude>23
        if deflected or bouncedUp then
            lastReboundAt,reboundUntil=now,now+1.5
        end
    end
end
local function freeVisualBall(now)
    local ball=currentVisualBall(now)
    if not ball then return nil end
    for _,player in ipairs(visualPlayers) do
        if player.Character and ball:IsDescendantOf(player.Character) then return nil end
    end
    return ball
end
local function updateFieldCues(now)
    if not State.ReboundAlert and not State.PassReception then return end
    if workspace:GetAttribute('GameEnded') then hideCue(reboundCue);hideCue(receptionCue);return end
    local ball=freeVisualBall(now)
    if not ball then hideCue(reboundCue);hideCue(receptionCue);return end
    local params=visualRayParams(ball,now)
    if State.ReboundAlert and now<reboundUntil and ball==reboundBall then
        local projected=ball.Position+ball.AssemblyLinearVelocity*0.22
        local ground=workspace:Raycast(projected+Vector3.new(0,12,0),Vector3.new(0,-75,0),params)
        if ground and ground.Normal.Y>=0.65 then moveCue(reboundCue,ground.Position)
        else hideCue(reboundCue) end
    else hideCue(reboundCue) end
    if not State.PassReception or not Root or not Root.Parent or not Humanoid or Humanoid.Health<=0 then
        hideCue(receptionCue)
        return
    end
    local velocity=ball.AssemblyLinearVelocity
    local flatVelocity=Vector3.new(velocity.X,0,velocity.Z)
    local toPlayer=Root.Position-ball.Position
    local distance=Vector3.new(toPlayer.X,0,toPlayer.Z).Magnitude
    local speedSquared=flatVelocity:Dot(flatVelocity)
    if speedSquared<18*18 or distance<7 or distance>110 then hideCue(receptionCue);return end
    local interceptTime=Vector3.new(toPlayer.X,0,toPlayer.Z):Dot(flatVelocity)/speedSquared
    if interceptTime<0.12 or interceptTime>1.35 then hideCue(receptionCue);return end
    local projected=ball.Position+flatVelocity*interceptTime
    local ground=workspace:Raycast(Vector3.new(projected.X,Root.Position.Y+12,projected.Z),Vector3.new(0,-42,0),params)
    if not ground or ground.Normal.Y<0.65 then hideCue(receptionCue);return end
    local nearGround=workspace:Raycast(ball.Position+Vector3.new(0,1,0),Vector3.new(0,-4,0),params)
    if not nearGround or ball.Position.Y-nearGround.Position.Y>3.5 then
        local height=ball.Position.Y+velocity.Y*interceptTime-0.5*workspace.Gravity*interceptTime*interceptTime
        if height>ground.Position.Y+6 then hideCue(receptionCue);return end
    end
    local reachable=math.max(8,Humanoid.WalkSpeed)*interceptTime+5
    if (Root.Position-ground.Position).Magnitude>reachable then hideCue(receptionCue);return end
    moveCue(receptionCue,ground.Position)
end
-- Keep at most six seconds of ball motion. Sampling is independent of the
-- landing toggle, so the replay button works even when that visual is off.
local history,historyNext,historyCount={},1,0
local historyBall,lastBallPosition,lastMotionAt,completedPlay=nil,nil,0,nil
local replayParts,replayStarted={},nil
local function snapshotHistory()
    local points={}
    for i=1,historyCount do
        points[i]=history[(historyNext-historyCount+i-2)%60+1]
    end
    return points
end
local function archiveMotion(now)
    if historyCount>=3 and now-lastMotionAt<2 then
        completedPlay={points=snapshotHistory(),at=now}
    end
    table.clear(history)
    historyNext,historyCount=1,0
end
local function recordBallPath(now)
    local ball=freeVisualBall(now)
    observeBounce(ball,now)
    if ball~=historyBall then
        archiveMotion(now)
        historyBall,lastBallPosition=ball,nil
    end
    if not ball then return end
    local position=ball.Position
    if lastBallPosition then
        local distance=(position-lastBallPosition).Magnitude
        if distance>180 then archiveMotion(now)
        elseif distance<0.35 then
            if historyCount>0 and now-lastMotionAt>=0.5 then archiveMotion(lastMotionAt) end
            lastBallPosition=position
            return
        end
    end
    lastBallPosition,lastMotionAt=position,now
    history[historyNext]=position
    historyNext=historyNext%60+1
    historyCount=math.min(historyCount+1,60)
end
local function clearReplay()
    for _,part in ipairs(replayParts) do part:Destroy() end
    table.clear(replayParts)
    replayStarted=nil
end
local function showLastPlay()
    clearReplay()
    local now=os.clock()
    local points
    if historyCount>=3 and (not completedPlay or lastMotionAt>=completedPlay.at) then
        points=snapshotHistory()
    elseif completedPlay then
        points=completedPlay.points
    end
    if not points or #points<3 then
        Library:Notify('No recent ball path to replay yet.',3)
        return
    end
    -- At most 30 simple parts, created only when requested.
    local stride=math.max(1,math.ceil((#points-1)/30))
    for i=1,#points-1,stride do
        local first,second=points[i],points[math.min(i+stride,#points)]
        local length=(second-first).Magnitude
        if length>0.1 and length<180 then
            local part=visualPart('LastPlayTrail')
            part.Color=Color3.fromRGB(255,207,85)
            part.Size=Vector3.new(0.17,0.17,length)
            part.CFrame=CFrame.lookAt((first+second)*0.5,second)
            part.Transparency=0.15
            table.insert(replayParts,part)
        end
    end
    replayStarted=now
end
local function updateReplay(now)
    if not replayStarted then return end
    local elapsed=now-replayStarted
    if elapsed>=10 then clearReplay();return end
    local transparency=0.15+elapsed*0.085
    for _,part in ipairs(replayParts) do part.Transparency=transparency end
end
-- An independent, compact HUD marker for balls outside the camera viewport.
local offscreenGui=Instance.new('ScreenGui')
offscreenGui.Name='SoraOffscreenBall'
offscreenGui.ResetOnSpawn=false
offscreenGui.IgnoreGuiInset=true
offscreenGui.DisplayOrder=Gui.DisplayOrder+1
offscreenGui.Parent=Player:WaitForChild('PlayerGui')
local ballMarker=ui('Frame',offscreenGui,{
    Size=UDim2.fromOffset(62,65),AnchorPoint=Vector2.new(0.5,0.5),
    BackgroundColor3=Color3.fromRGB(18,19,28),BackgroundTransparency=0.22,
    BorderSizePixel=0,Visible=false,
})
rounded(ballMarker,9)
ui('UIStroke',ballMarker,{Color=Color3.fromRGB(245,245,245),Transparency=0.55,Thickness=1})
local arrowGlyph=ui('TextLabel',ballMarker,{
    BackgroundTransparency=1,Text='▲',Font=Enum.Font.GothamBold,TextSize=17,
    TextColor3=Color3.fromRGB(255,219,91),AnchorPoint=Vector2.new(0.5,0.5),
    Size=UDim2.fromOffset(22,19),Position=UDim2.new(0.5,0,0,11),
})
ui('TextLabel',ballMarker,{
    BackgroundTransparency=1,Text='⚽',Font=Enum.Font.GothamBold,TextSize=25,
    TextColor3=Color3.new(1,1,1),Size=UDim2.fromOffset(30,28),
    Position=UDim2.new(0.5,-15,0,21),
})
local ballDistance=ui('TextLabel',ballMarker,{
    BackgroundTransparency=1,Text='',Font=Enum.Font.GothamBold,TextSize=11,
    TextColor3=Color3.new(1,1,1),TextXAlignment=Enum.TextXAlignment.Center,
    Size=UDim2.new(1,0,0,14),Position=UDim2.fromOffset(0,48),
})
local function updateOffscreenBall()
    if not State.OffscreenBall or workspace:GetAttribute('GameEnded') then
        ballMarker.Visible=false
        return
    end
    local ball=currentVisualBall(os.clock())
    local currentCamera=workspace.CurrentCamera
    if not ball or not currentCamera then ballMarker.Visible=false;return end
    local view=currentCamera.ViewportSize
    if view.X<130 or view.Y<130 then ballMarker.Visible=false;return end
    local projected,onScreen=currentCamera:WorldToViewportPoint(ball.Position)
    if onScreen and projected.Z>0 then ballMarker.Visible=false;return end
    local center=Vector2.new(view.X*0.5,view.Y*0.5)
    local direction
    if projected.Z>0 then
        direction=Vector2.new(projected.X-center.X,projected.Y-center.Y)
    else
        local relative=currentCamera.CFrame:PointToObjectSpace(ball.Position)
        direction=Vector2.new(relative.X,-relative.Y)
    end
    if direction.Magnitude<0.001 then direction=Vector2.new(0,1) end
    direction=direction.Unit
    local maxX,maxY=center.X-42,center.Y-45
    local edge=math.min(maxX/math.max(math.abs(direction.X),0.001),maxY/math.max(math.abs(direction.Y),0.001))
    local location=center+direction*edge
    ballMarker.Position=UDim2.fromOffset(location.X,location.Y)
    arrowGlyph.Rotation=math.deg(math.atan2(direction.Y,direction.X))+90
    local origin=Root and Root.Parent and Root.Position or currentCamera.CFrame.Position
    ballDistance.Text=tostring(math.floor((ball.Position-origin).Magnitude+0.5))..' studs'
    ballMarker.Visible=true
end
-- All skill icons extracted from WeaponTrees; refresh from live definitions once.
local cooldownIcons={
    ["Impact Shot"]="rbxassetid://14065403478",
    ["Impact Bicycle"]="rbxassetid://14065403865",
    ["Direct Impact"]="rbxassetid://14089516792",
    ["Defensive Stance"]="rbxassetid://14007267580",
    ["Snake Jump"]="rbxassetid://14007268434",
    ["Defensive Rush"]="rbxassetid://14007268012",
    ["Explosive Rush"]="rbxassetid://13731727695",
    ["Diagonal Rush"]="rbxassetid://13811018937",
    ["Explosive Kick"]="rbxassetid://13731727432",
    ["Superior Rush"]="rbxassetid://12589280756",
    ["Dragon Drive"]="rbxassetid://13600834042",
    ["Big Bang Drive"]="rbxassetid://13600830832",
    ["Chop Feint"]="rbxassetid://13486932111",
    ["Lightning Dribble"]="rbxassetid://13486931618",
    ["Villainous Shot"]="rbxassetid://13486931863",
    ["Jumping Header"]="rbxassetid://13486932589",
    ["Midair Chest Trap"]="rbxassetid://13486932316",
    ["Hyperspeed Scissors"]="rbxassetid://12589289473",
    ["Marseille Turn"]="rbxassetid://12589482027",
    ["Midair Elastico"]="rbxassetid://12971351497",
    ["Rainbow Flick"]="rbxassetid://12971351341",
    ["Explosive Acceleration"]="rbxassetid://12636110455",
    ["Black Hole Trap"]="rbxassetid://12589275504",
    ["Trap Shot"]="rbxassetid://12589305143",
    ["Creative Trap"]="rbxassetid://12589287854",
    ["Zero Reset Turn"]="rbxassetid://12589308502",
    ["Fake Volley Shot"]="rbxassetid://13145237694",
    ["Mark Smell"]="rbxassetid://13054982608",
    ["Pinpoint High Speed Kick"]="rbxassetid://12846377200",
    ["Trivela (Shot)"]="rbxassetid://12589277896",
    ["Trivela (Pass)"]="rbxassetid://13033873580",
    ["Goal Scent"]="rbxassetid://12589079530",
    ["Long-Distance Sprinting"]="rbxassetid://12589079530",
    ["Knuckle Shot"]="rbxassetid://12589286269",
    ["Stealthy Steps"]="rbxassetid://12589292068",
    ["Direct Shot"]="rbxassetid://12589280756",
}
local loadedIconModules=setmetatable({}, {__mode='k'})
local function loadSkillIcons(module)
    if not module:IsA('ModuleScript') or loadedIconModules[module] then return end
    loadedIconModules[module]=true
    task.spawn(function()
        local ok,definitions=pcall(require,module)
        if not Session.Alive or not ok or type(definitions)~='table' then return end
        for _,skill in pairs(definitions) do
            if type(skill)=='table' and type(skill.Name)=='string' and skill.icon then
                local icon=tostring(skill.icon)
                if icon:match('^%d+$') then icon='rbxassetid://'..icon end
                cooldownIcons[skill.Name]=icon
            end
        end
    end)
end
local iconTree
local function refreshIconCatalog()
    local tree=RS:FindFirstChild('WeaponTrees')
    if tree==iconTree then return end
    iconTree=tree
    if tree then
        for _,module in ipairs(tree:GetDescendants()) do loadSkillIcons(module) end
        connect(tree.DescendantAdded,loadSkillIcons)
    end
end
local headCooldowns={}
local function clearHeadCooldowns()
    for _,display in pairs(headCooldowns) do display.gui:Destroy() end
    table.clear(headCooldowns)
end
local function createHeadCooldowns(player,head)
    local billboard=ui('BillboardGui',Gui,{Name='Cooldowns_'..player.UserId,Adornee=head,
        Size=UDim2.fromOffset(44,54),StudsOffsetWorldSpace=Vector3.new(0,3,0),
        AlwaysOnTop=true,MaxDistance=State.CooldownRange+10,LightInfluence=0})
    local display={gui=billboard,cells={}}
    headCooldowns[player]=display
    return display
end
local function createCooldownCell(display,name)
    local cell=ui('Frame',display.gui,{Name=name,Size=UDim2.fromOffset(42,52),
        BackgroundColor3=Color3.fromRGB(18,19,28),BackgroundTransparency=0.15,BorderSizePixel=0})
    rounded(cell,5)
    local icon=ui('ImageLabel',cell,{BackgroundTransparency=1,Size=UDim2.fromOffset(42,42)})
    local fallback=label(cell,name:sub(1,3):upper(),13)
    fallback.Size=UDim2.fromOffset(42,35);fallback.TextXAlignment=Enum.TextXAlignment.Center
    local timer=label(cell,'CD',13)
    timer.Position=UDim2.fromOffset(0,34);timer.Size=UDim2.fromOffset(42,18)
    timer.TextXAlignment=Enum.TextXAlignment.Center;timer.TextStrokeTransparency=0
    timer.Font=Enum.Font.GothamBold;timer.TextColor3=Color3.fromRGB(255,195,80)
    local result={frame=cell,icon=icon,fallback=fallback,timer=timer}
    display.cells[name]=result
    return result
end
local cooldownFolder,cooldownAdded,cooldownRemoved
local observedCooldowns,activeByUser={},{}
local finishedByUser={}
local updateCooldownPanel
local function removeCooldown(entry)
    local record=observedCooldowns[entry]
    if not record then return end
    local bucket=activeByUser[record.userId]
    if bucket then
        bucket[entry]=nil
        if next(bucket)==nil then activeByUser[record.userId]=nil end
    end
    observedCooldowns[entry]=nil
    -- The move can appear as ready again once its final cooldown entry is gone.
    local stillActive=false
    for _,other in pairs(bucket or {}) do
        if other.skill==record.skill then stillActive=true;break end
    end
    if not stillActive then
        finishedByUser[record.userId]=finishedByUser[record.userId] or {}
        finishedByUser[record.userId][record.skill]=true
    end
end
local function observeCooldown(entry,seen)
    local userId,skill=entry.Name:match('^(%d+)(.+)$')
    if not userId or not skill then return end
    if finishedByUser[userId] then finishedByUser[userId][skill]=nil end
    local record={userId=userId,skill=skill,seen=seen}
    observedCooldowns[entry]=record
    activeByUser[userId]=activeByUser[userId] or {}
    activeByUser[userId][entry]=record
end
local function detachCooldowns()
    clearHeadCooldowns()
    if cooldownAdded then cooldownAdded:Disconnect();cooldownAdded=nil end
    if cooldownRemoved then cooldownRemoved:Disconnect();cooldownRemoved=nil end
    cooldownFolder=nil
    table.clear(observedCooldowns)
    table.clear(activeByUser)
    table.clear(finishedByUser)
end
local function syncCooldownFolder()
    local folder=RS:FindFirstChild('CooldownsFolder')
    if folder==cooldownFolder then return end
    detachCooldowns()
    cooldownFolder=folder
    if not folder then return end
    for _,entry in ipairs(folder:GetChildren()) do observeCooldown(entry,nil) end
    cooldownAdded=folder.ChildAdded:Connect(function(entry)
        observeCooldown(entry,os.clock())
        updateCooldownPanel(os.clock())
    end)
    cooldownRemoved=folder.ChildRemoved:Connect(function(entry)
        removeCooldown(entry)
        updateCooldownPanel(os.clock())
    end)
end
local function cooldownEntryText(entry,record,now)
    local duration=entry:GetAttribute('Cooldown')
    if record.seen and type(duration)=='number' and duration>=0 then
        local remaining=duration-(now-record.seen)
        if remaining>0 then return string.format('~%.1f',remaining) end
    end
    return 'CD'
end
updateCooldownPanel=function(now)
    if not State.OpponentCooldowns and not State.OpponentReady then return end
    refreshIconCatalog()
    syncCooldownFolder()
    if not Root or not Root.Parent then clearHeadCooldowns();return end
    local visible={}
    local myTeam=getTeam(Player)
    for _,player in ipairs(Players:GetPlayers()) do
        local bucket=activeByUser[tostring(player.UserId)]
        if player~=Player and not isExcepted(player) and (bucket or State.OpponentReady) then
            local character=player.Character
            local root=character and character:FindFirstChild('HumanoidRootPart')
            local head=character and character:FindFirstChild('Head')
            local humanoid=character and character:FindFirstChildOfClass('Humanoid')
            if root and head and humanoid and humanoid.Health>0 and (not myTeam or myTeam~=getTeam(player))
                and (root.Position-Root.Position).Magnitude<=State.CooldownRange then
                local active,names={},{}
                for entry,record in pairs(bucket or {}) do
                    if State.OpponentCooldowns and entry.Parent==cooldownFolder then
                        if not active[record.skill] then table.insert(names,record.skill) end
                        active[record.skill]={entry=entry,record=record}
                    end
                end
                if State.OpponentReady and cooldownFolder then
                    local known={}
                    local equipped=player:FindFirstChild('EquippedSkills')
                    if equipped then
                        for slot,skill in pairs(equipped:GetAttributes()) do
                            if slot:match('^Slot') and type(skill)=='string' and skill~='' then known[skill]=true end
                        end
                    else
                        for skill in pairs(finishedByUser[tostring(player.UserId)] or {}) do known[skill]=true end
                    end
                    for skill in pairs(known) do
                        if not cooldownFolder:FindFirstChild(tostring(player.UserId)..skill) and not active[skill] then
                            active[skill]={ready=true}
                            table.insert(names,skill)
                        end
                    end
                end
                table.sort(names)
                if #names>0 then
                    visible[player]=true
                    local display=headCooldowns[player] or createHeadCooldowns(player,head)
                    display.gui.Adornee=head
                    display.gui.MaxDistance=State.CooldownRange+10
                    local columns=math.min(5,#names)
                    display.gui.Size=UDim2.fromOffset(columns*46,math.ceil(#names/5)*56)
                    for name,cell in pairs(display.cells) do
                        if not active[name] then cell.frame:Destroy();display.cells[name]=nil end
                    end
                    for i,name in ipairs(names) do
                        local cell=display.cells[name] or createCooldownCell(display,name)
                        cell.frame.Position=UDim2.fromOffset(((i-1)%5)*46,math.floor((i-1)/5)*56)
                        local icon=cooldownIcons[name]
                        cell.icon.Image=icon or ''
                        cell.icon.Visible=icon~=nil
                        cell.fallback.Visible=icon==nil
                        local item=active[name]
                        cell.timer.Text=item.ready and 'READY' or cooldownEntryText(item.entry,item.record,now)
                        cell.timer.TextColor3=item.ready and Color3.fromRGB(105,235,150) or Color3.fromRGB(255,195,80)
                    end
                end
            end
        end
    end
    for player,display in pairs(headCooldowns) do
        if not visible[player] then display.gui:Destroy();headCooldowns[player]=nil end
    end
end
local tdHighlights={}
local function clearTDHighlights()
    for player,highlight in pairs(tdHighlights) do
        highlight:Destroy()
        tdHighlights[player]=nil
    end
end
local function updateTDHighlights()
    if not State.HighlightTDs then return end
    local cooldowns=RS:FindFirstChild('CooldownsFolder')
    local visible={}
    if cooldowns then
        for _,player in ipairs(Players:GetPlayers()) do
            if player~=Player then
                local character=player.Character
                local humanoid=character and character:FindFirstChildOfClass('Humanoid')
                local skills=player:FindFirstChild('EquippedSkills')
                if character and humanoid and humanoid.Health>0 and skills then
                    local hasRush=false
                    for slot,skill in pairs(skills:GetAttributes()) do
                        if slot:match('^Slot') and skill=='Defensive Rush' then
                            hasRush=true
                            break
                        end
                    end
                    if hasRush and not cooldowns:FindFirstChild(tostring(player.UserId)..'Defensive Rush') then
                        visible[player]=true
                        local highlight=tdHighlights[player]
                        if not highlight then
                            highlight=Instance.new('Highlight')
                            highlight.Name='SoraReadyDefensiveRush'
                            highlight.FillColor=Color3.fromRGB(60,220,110)
                            highlight.FillTransparency=0.8
                            highlight.OutlineColor=Color3.fromRGB(65,255,125)
                            highlight.OutlineTransparency=0
                            highlight.DepthMode=Enum.HighlightDepthMode.AlwaysOnTop
                            highlight.Parent=visualFolder
                            tdHighlights[player]=highlight
                        end
                        if highlight.Adornee~=character then highlight.Adornee=character end
                    end
                end
            end
        end
    end
    for player,highlight in pairs(tdHighlights) do
        if not visible[player] then
            highlight:Destroy()
            tdHighlights[player]=nil
        end
    end
end
local Visuals=Main:AddRightGroupbox('Metavision')
toggle(Visuals,'BallPrediction','Ball Landing / Rolling Marker',nil,function(enabled) if not enabled then hideLanding() end end,
    'Shows an estimated landing point in the air, or a short forward marker while the ball rolls.')
toggle(Visuals,'BallETA','Ball ETA',nil,function(enabled)
    if not enabled then hideBallETA() end
end,'Shows estimated seconds until the ball reaches its landing point or short rolling lead. Hides while the ball is still.')
toggle(Visuals,'ReboundAlert','Rebound Alert',nil,function(enabled)
    if not enabled then reboundUntil=0;hideCue(reboundCue) end
end,'Shows a small orange marker after the free ball sharply changes direction. The REBOUND label marks its short-term ground position.')
toggle(Visuals,'PassReception','Pass Reception Cue',nil,function(enabled)
    if not enabled then hideCue(receptionCue) end
end,'Shows a cyan field marker where you could reach an incoming free ball. It disappears if the ball changes course or becomes unreachable.')
Visuals:AddButton({Text='Replay Last Ball Path',Func=showLastPlay})
Visuals:AddLabel('Recent ball trail fades over 10 seconds.')
toggle(Visuals,'OffscreenBall','Off-Screen Ball Arrow',nil,function(enabled)
    if enabled then updateOffscreenBall() else ballMarker.Visible=false end
end,'Shows a small ball arrow and distance near the screen edge while the ball is outside your view.')
Visuals:AddLabel('Air: landing estimate. Ground: short rolling lead.')
toggle(Visuals,'OpponentCooldowns','Opponent Cooldowns',nil,function(enabled)
    if enabled or State.OpponentReady then updateCooldownPanel(os.clock()) else detachCooldowns() end
end,'Shows an opponent move above their head only while its visible cooldown is active.')
toggle(Visuals,'OpponentReady','Opponent Ready Moves',nil,function(enabled)
    if enabled or State.OpponentCooldowns then updateCooldownPanel(os.clock()) else detachCooldowns() end
end,'Shows equipped moves above nearby opponents when no cooldown entry is visible.')
toggle(Visuals,'HighlightTDs','Highlight TDs',nil,function(enabled)
    if enabled then updateTDHighlights() else clearTDHighlights() end
end,'Highlights players with Defensive Rush equipped in green when it appears ready.')
Visuals:AddLabel('Green: Defensive Rush equipped and off cooldown.')
Visuals:AddLabel('Ready moves hide while their cooldown is active.')
Visuals:AddLabel('READY means no cooldown entry is visible.')
Visuals:AddSlider('SoraCooldownRange',{Text='Opponent Tracking Range',Default=80,Min=20,Max=200,Rounding=0})
Options.SoraCooldownRange:OnChanged(function() State.CooldownRange=Options.SoraCooldownRange.Value end)
local visualElapsed,cooldownElapsed,tdHighlightElapsed,arrowElapsed,recordElapsed,replayElapsed=0,0,0,0,0,0
connect(RunService.Heartbeat,function(dt)
    if not Session.Alive then return end
    visualElapsed=visualElapsed+dt
    cooldownElapsed=cooldownElapsed+dt
    tdHighlightElapsed=tdHighlightElapsed+dt
    arrowElapsed=arrowElapsed+dt
    recordElapsed=recordElapsed+dt
    replayElapsed=replayElapsed+dt
    if recordElapsed>=0.1 then
        recordElapsed=0
        local now=os.clock()
        recordBallPath(now)
        if State.ReboundAlert or State.PassReception then updateFieldCues(now) end
    end
    if (State.BallPrediction or State.BallETA) and visualElapsed>=0.05 then visualElapsed=0;updateBallVisuals() end
    if replayStarted and replayElapsed>=0.2 then replayElapsed=0;updateReplay(os.clock()) end
    if State.OffscreenBall and arrowElapsed>=0.05 then arrowElapsed=0; updateOffscreenBall() end
    if (State.OpponentCooldowns or State.OpponentReady) and cooldownElapsed>=0.25 then cooldownElapsed=0; updateCooldownPanel(os.clock()) end
    if State.HighlightTDs and tdHighlightElapsed>=0.2 then tdHighlightElapsed=0; updateTDHighlights() end
end)

return function()
    clearReplay()
    offscreenGui:Destroy()
    clearTDHighlights()
    detachCooldowns()
    visualFolder:Destroy()
end
end)()

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
local menuButton=Layout:AddButton({Text='Show / Hide Menu: End',Func=function() end})
createKeyControl('SoraMenuKey','Menu','End',menuButton,visibility)
local KeySettings=UITab:AddRightGroupbox('Keybinds')
KeySettings:AddLabel('Click a binding, then press a key.')
KeySettings:AddLabel('Escape cancels. Backspace clears.')
for _,key in ipairs(keyControls) do
    if key.Name~='Menu' then
        local button=KeySettings:AddButton({Text=key.Name..': '..key.Value,Func=function() beginKeyCapture(key) end})
        key.Button=button
        key:Refresh()
    end
end
local function resetKeybinds()
    if pendingKey then pendingKey:Refresh(); pendingKey=nil end
    for _,key in ipairs(keyControls) do key:SetValue('None') end
    for _,key in ipairs(keyControls) do key:SetValue(key.Default) end
end
KeySettings:AddButton({Text='Reset Keybinds',Func=resetKeybinds})
Layout:AddButton({Text='Center Window',Func=function() root.Position=UDim2.fromScale(0.5,0.5) end})
Layout:AddButton({Text='Reset UI Settings',Func=function()
    Options.SoraAccentPreset:SetValue('Purple')
    Options.SoraUIScale:SetValue(100)
    Options.SoraUITransparency:SetValue(0)
    Toggles.SoraShowKeyHints:SetValue(true)
    resetKeybinds()
    root.Position=UDim2.fromScale(0.5,0.5)
end})

local function cleanup()
    if not Session.Alive then return end
    Session.Alive = false
    if cleanupCanonKaiser then cleanupCanonKaiser() end
    if cleanupDribble then cleanupDribble() end
    if cleanupMetavision then cleanupMetavision() end
    RunService:UnbindFromRenderStep(aimRenderName)
    clearTakeBallAnimation()
    takeBallAnimation:Destroy()
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
    bikeAimUntil=0
    if Env.SoraHubSession == Session then Env.SoraHubSession = nil end
end
Session.Cleanup = cleanup
Library:OnUnload(cleanup)
Menu:AddButton({ Text='Unload Sora Hub', Func=function() cleanup(); Library:Unload() end })
Menu:AddLabel('Change keybinds in UI Settings.')
Library:Notify('Sora Hub loaded. Change keybinds in UI Settings.', 6)
