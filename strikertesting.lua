-- Striker testing: optional goal opening and shot angle guides.
local Players=game:GetService('Players')
local RS=game:GetService('ReplicatedStorage')
local RunService=game:GetService('RunService')
local Input=game:GetService('UserInputService')
local Player=Players.LocalPlayer
local Env=type(getgenv)=='function' and getgenv() or _G
if Env.StrikerTesting then Env.StrikerTesting.Unload() end
-- Unload the former test if it is still running during migration.
if Env.PKATrapTest then Env.PKATrapTest.Unload() end
local Session={Alive=true,Connections={}}
Env.StrikerTesting=Session
local function connect(signal,callback)
    local c=signal:Connect(callback);Session.Connections[#Session.Connections+1]=c;return c
end
local function team(player)
    local folder=RS:FindFirstChild('Teams')
    if folder then
        for _,t in ipairs(folder:GetChildren()) do
            for _,name in pairs(t:GetAttributes()) do if name==player.Name then return t end end
        end
    end
end
local function ownedBall(player)
    local ch=player.Character;local folder=ch and ch:FindFirstChild('Ball')
    if not folder then return end
    if folder:IsA('BasePart') then return folder end
    local ball=folder:FindFirstChild('Ball')
    if ball and ball:IsA('BasePart') then return ball end
end
local Gui=Instance.new('ScreenGui')
Gui.Name='StrikerTesting';Gui.ResetOnSpawn=false;Gui.Parent=Player:WaitForChild('PlayerGui')
local panel=Instance.new('Frame')
panel.Size=UDim2.fromOffset(310,185);panel.Position=UDim2.new(0,20,0.5,-92)
panel.BackgroundColor3=Color3.fromRGB(24,26,33);panel.Parent=Gui
local function label(text,y,height)
    local x=Instance.new('TextLabel');x.Size=UDim2.new(1,-20,0,height or 22)
    x.Position=UDim2.fromOffset(10,y);x.BackgroundTransparency=1;x.TextColor3=Color3.new(1,1,1)
    x.Font=Enum.Font.Gotham;x.TextSize=13;x.TextWrapped=true;x.Text=text;x.Parent=panel;return x
end
local function button(text,x,y,width,callback)
    local b=Instance.new('TextButton');b.Size=UDim2.fromOffset(width,27);b.Position=UDim2.fromOffset(x,y)
    b.BackgroundColor3=Color3.fromRGB(48,53,66);b.TextColor3=Color3.new(1,1,1)
    b.TextSize=12;b.Font=Enum.Font.Gotham;b.Text=text;b.Parent=panel
    connect(b.Activated,callback);return b
end
label('STRIKER TESTING',7)
-- Positional estimates only: these do not model skill hitboxes or curved shots.
local visuals=Instance.new('Folder');visuals.Name='StrikerGuides';visuals.Parent=workspace
local openingEnabled,angleEnabled=false,false
local strips,edges={},{}
local function newLine(color)
    local p=Instance.new('Part');p.Anchored=true;p.CanCollide=false;p.CanTouch=false;p.CanQuery=false
    p.Material=Enum.Material.Neon;p.Color=color;p.Transparency=1;p.CastShadow=false;p.Parent=visuals
    return p
end
for i=1,17 do strips[i]=newLine(Color3.fromRGB(85,240,140)) end
for i=1,2 do edges[i]=newLine(Color3.fromRGB(95,185,255)) end
local function line(p,a,b)
    local length=(b-a).Magnitude
    if length<0.01 then p.Transparency=1;return end
    p.Size=Vector3.new(0.13,0.13,length);p.CFrame=CFrame.lookAt((a+b)*0.5,b);p.Transparency=0.2
end
local angleGui=Instance.new('BillboardGui');angleGui.Size=UDim2.fromOffset(290,48)
angleGui.StudsOffsetWorldSpace=Vector3.new(0,4,0);angleGui.AlwaysOnTop=true;angleGui.Enabled=false;angleGui.Parent=Gui
local angleText=Instance.new('TextLabel');angleText.Size=UDim2.fromScale(1,1);angleText.BackgroundTransparency=1
angleText.TextColor3=Color3.fromRGB(145,215,255);angleText.TextStrokeTransparency=0.25
angleText.Font=Enum.Font.GothamMedium;angleText.TextSize=13;angleText.Parent=angleGui
local function hideGuides()
    for _,p in ipairs(strips) do p.Transparency=1 end
    for _,p in ipairs(edges) do p.Transparency=1 end
    angleGui.Enabled=false
end
local openingButton,angleButton
openingButton=button('Goal Opening Marker: OFF',10,38,290,function()
    openingEnabled=not openingEnabled
    openingButton.Text='Goal Opening Marker: '..(openingEnabled and 'ON' or 'OFF');hideGuides()
end)
angleButton=button('Shot Angle Guide: OFF',10,71,290,function()
    angleEnabled=not angleEnabled
    angleButton.Text='Shot Angle Guide: '..(angleEnabled and 'ON' or 'OFF');hideGuides()
end)
local goals,nextScan,visualElapsed={},0,0
local function scanGoals(now)
    goals={};nextScan=now+2
    local function inspect(model)
        local mouth=model:FindFirstChild('LineHitbox')
        if not mouth or not mouth:IsA('BasePart') then return end
        for _,p in ipairs(model:GetChildren()) do
            if p.Name=='Shtanga' and p:IsA('BasePart') and p.Size.Y<math.max(p.Size.X,p.Size.Z) then
                goals[#goals+1]=mouth;return
            end
        end
    end
    for _,obj in ipairs(workspace:GetChildren()) do
        inspect(obj)
        if obj.Name=='GameField' or obj.Name=='MiniField' then
            for _,child in ipairs(obj:GetChildren()) do inspect(child) end
        end
    end
end
local cornersEnabled=true
local cornerTargets={}
local cornerButton
cornerButton=button('Goal Corner Targets: ON',10,104,290,function()
    cornersEnabled=not cornersEnabled
    cornerButton.Text='Goal Corner Targets: '..(cornersEnabled and 'ON' or 'OFF')
    for _,markers in pairs(cornerTargets) do
        for _,marker in ipairs(markers) do marker.gui.Enabled=cornersEnabled end
    end
end)
local function updateCorners()
    local present={}
    for _,mouth in ipairs(goals) do
        if mouth.Parent then
            present[mouth]=true
            local markers=cornerTargets[mouth]
            if not markers then
                markers={};cornerTargets[mouth]=markers
                for i=1,4 do
                    local anchor=newLine(Color3.fromRGB(255,210,75))
                    anchor.Name='GoalCornerTarget';anchor.Size=Vector3.new(0.1,0.1,0.1)
                    local gui=Instance.new('BillboardGui');gui.Adornee=anchor
                    gui.Size=UDim2.fromOffset(22,22);gui.AlwaysOnTop=true;gui.MaxDistance=650;gui.Parent=anchor
                    local ring=Instance.new('Frame');ring.Size=UDim2.fromScale(1,1)
                    ring.BackgroundTransparency=1;ring.Parent=gui
                    local round=Instance.new('UICorner');round.CornerRadius=UDim.new(1,0);round.Parent=ring
                    local stroke=Instance.new('UIStroke');stroke.Color=Color3.fromRGB(255,210,75);stroke.Thickness=2;stroke.Parent=ring
                    local dot=Instance.new('Frame');dot.AnchorPoint=Vector2.new(0.5,0.5);dot.Position=UDim2.fromScale(0.5,0.5)
                    dot.Size=UDim2.fromOffset(4,4);dot.BorderSizePixel=0;dot.BackgroundColor3=stroke.Color;dot.Parent=ring
                    markers[i]={anchor=anchor,gui=gui}
                end
            end
            -- Keep targets inside the mouth, with the top below the crossbar.
            local top=mouth.Size.Y/2-1.5
            for _,bar in ipairs(mouth.Parent:GetChildren()) do
                if bar.Name=='Shtanga' and bar:IsA('BasePart') and bar.Size.Y<math.max(bar.Size.X,bar.Size.Z) then
                    local barLocal=mouth.CFrame:PointToObjectSpace(bar.Position)
                    top=math.min(top,barLocal.Y-bar.Size.Y/2-1.5)
                end
            end
            local bottom=-mouth.Size.Y/2+1.5
            top=math.max(bottom,top)
            local width=math.max(0,mouth.Size.Z/2-1.5)
            for i,marker in ipairs(markers) do
                local y=i<=2 and top or bottom
                local z=i%2==1 and -width or width
                marker.anchor.Position=mouth.CFrame:PointToWorldSpace(Vector3.new(0,y,z))
                marker.gui.Enabled=cornersEnabled
            end
        end
    end
    for mouth,markers in pairs(cornerTargets) do
        if not present[mouth] then
            for _,marker in ipairs(markers) do marker.anchor:Destroy() end
            cornerTargets[mouth]=nil
        end
    end
end

local function flat(v) return Vector3.new(v.X,0,v.Z) end
connect(RunService.Heartbeat,function(dt)
    if not openingEnabled and not angleEnabled and not cornersEnabled then return end
    visualElapsed=visualElapsed+dt;if visualElapsed<0.1 then return end;visualElapsed=visualElapsed%0.1
    hideGuides()
    local now=os.clock()
    if now>=nextScan then scanGoals(now);updateCorners() end
    if not openingEnabled and not angleEnabled then return end
    local ch=Player.Character;local root=ch and ch:FindFirstChild('HumanoidRootPart')
    local human=ch and ch:FindFirstChildOfClass('Humanoid')
    local ball=ownedBall(Player);local camera=workspace.CurrentCamera
    if not root or not human or human.Health<=0 or not ball or not camera then return end
    local facing=flat(camera.CFrame.LookVector)
    if facing.Magnitude<0.05 then facing=flat(root.CFrame.LookVector) end
    if facing.Magnitude<0.001 then return end;facing=facing.Unit
    local goal,best=nil,0.25
    for _,mouth in ipairs(goals) do
        if mouth.Parent and math.abs(mouth.Position.Y-root.Position.Y)<45 then
            local d=flat(mouth.Position-root.Position)
            if d.Magnitude>3 and d.Magnitude<600 then
                local score=facing:Dot(d.Unit)
                if score>best then goal,best=mouth,score end
            end
        end
    end
    if not goal then return end
    local half=math.max(0,goal.Size.Z*0.5-2)
    if half<1 then return end
    local y=math.clamp(ball.Position.Y,goal.Position.Y-goal.Size.Y/2+1,goal.Position.Y+goal.Size.Y/2-1)
    local center=Vector3.new(goal.Position.X,y,goal.Position.Z)
    local axis=flat(goal.CFrame.LookVector)
    if axis.Magnitude<0.001 then return end;axis=axis.Unit
    local a,b=center-axis*half,center+axis*half
    local opponents={};local mine=team(Player)
    for _,other in ipairs(Players:GetPlayers()) do
        if other~=Player and (not mine or team(other)~=mine) then
            local c=other.Character;local r=c and c:FindFirstChild('HumanoidRootPart')
            local h=c and c:FindFirstChildOfClass('Humanoid')
            if r and h and h.Health>0 and math.abs(r.Position.Y-root.Position.Y)<12 then
                opponents[#opponents+1]=flat(r.Position)
            end
        end
    end
    local function clear(origin,target)
        local start=flat(origin);local delta=flat(target)-start;local length2=delta:Dot(delta)
        if length2<0.01 then return false end
        for _,pos in ipairs(opponents) do
            local t=(pos-start):Dot(delta)/length2
            if t>0 and t<1 and (pos-(start+delta*t)).Magnitude<3 then return false end
        end
        return true
    end
    local function assess(origin,draw)
        local count=0
        for i=1,17 do
            local left=a:Lerp(b,(i-1)/17);local right=a:Lerp(b,i/17)
            if clear(origin,(left+right)/2) then
                count=count+1;if draw then line(strips[i],left,right) end
            end
        end
        local da,db=flat(a-origin),flat(b-origin)
        if da.Magnitude<0.01 or db.Magnitude<0.01 then return 0,0 end
        local angle=math.deg(math.acos(math.clamp(da.Unit:Dot(db.Unit),-1,1)))
        return angle*count/17,angle
    end
    local score,angle=assess(ball.Position,openingEnabled)
    if angleEnabled then
        line(edges[1],ball.Position,a);line(edges[2],ball.Position,b)
        local right=flat(camera.CFrame.RightVector)
        if right.Magnitude<0.01 then return end;right=right.Unit
        local leftScore=assess(ball.Position-right*5,false)
        local rightScore=assess(ball.Position+right*5,false)
        local hint='Hold position'
        if math.max(leftScore,rightScore)>score+1 then hint=leftScore>rightScore and 'Try moving LEFT' or 'Try moving RIGHT' end
        angleText.Text=string.format('Goal angle: %.0f° | Est. open: %.0f°\n%s',angle,score,hint)
        angleGui.Adornee=root;angleGui.Enabled=true
    end
end)

function Session.Unload()
    if not Session.Alive then return end
    Session.Alive=false
    for _,c in ipairs(Session.Connections) do c:Disconnect() end
    visuals:Destroy();Gui:Destroy()
    if Env.StrikerTesting==Session then Env.StrikerTesting=nil end
end
button('Unload',10,141,140,Session.Unload)
local hint=label('End: hide panel',143,22)
hint.Position=UDim2.fromOffset(155,143);hint.Size=UDim2.fromOffset(145,22)
connect(Input.InputBegan,function(input,processed)
    if processed or Input:GetFocusedTextBox() then return end
    if input.KeyCode==Enum.KeyCode.End then panel.Visible=not panel.Visible end
end)
connect(Player.CharacterAdded,hideGuides)
