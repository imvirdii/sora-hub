-- PKA Auto Trap test. F8: enable/disable. End: hide/show panel.
-- Tracks only balls associated with an opponent's Trivela (Shot) event.
-- Radius and lead are tuning values, NOT measured server hitbox/startup values.
local Players=game:GetService('Players')
local RS=game:GetService('ReplicatedStorage')
local RunService=game:GetService('RunService')
local Input=game:GetService('UserInputService')
local Player=Players.LocalPlayer
local Event=RS:WaitForChild('Remotes'):WaitForChild('TranciverRemote')
local Env=type(getgenv)=='function' and getgenv() or _G
if Env.PKATrapTest then Env.PKATrapTest.Unload() end
local Config={Enabled=true,Trap='Black Hole Trap',Radius=12,Lead=0.22,
    Interval=1/60,Horizon=0.65,PathStep=0.02,MaxAcceleration=250,
    MaxAge=8,MaxTracked=4,RequestGap=0.5,IgnoreTeammates=true,Debug=true}
local Exceptions={TheNextNagi=true,LeoTheDominican=true}
local ShotSkills={['Trivela (Shot)']=true}
-- These are candidate broadcast actions; the panel/console reports those seen.
local ShotActions={Kick=true,Shot=true,UseSkill=true}
local TrapActions={['Black Hole Trap']='UseSkill',['Creative Trap']='UseSkill',['Zero Reset Turn']='Hold'}
local Session={Alive=true,Connections={}}
Env.PKATrapTest=Session
local tracked,captured={},{}
local lastRequest=-math.huge
local status,lastStatus,lastStatusAt=nil,'',-math.huge
local function connect(signal,callback)
    local c=signal:Connect(callback);Session.Connections[#Session.Connections+1]=c;return c
end
local function report(message,force)
    local now=os.clock()
    if status and message~=lastStatus and (force or now-lastStatusAt>=0.2) then
        status.Text=message;lastStatus=message;lastStatusAt=now
    end
end
local function team(player)
    local folder=RS:FindFirstChild('Teams')
    if folder then
        for _,t in ipairs(folder:GetChildren()) do
            for _,name in pairs(t:GetAttributes()) do if name==player.Name then return t end end
        end
    end
end
local function excluded(player)
    if not player or player==Player or player.Parent~=Players or Exceptions[player.Name] then return true end
    if Config.IgnoreTeammates then
        local mine=team(Player)
        if mine and mine==team(player) then return true end
    end
    return false
end
local function part(value)
    if typeof(value)~='Instance' then return end
    if value:IsA('BasePart') then return value end
    if value:IsA('Model') and value.PrimaryPart then return value.PrimaryPart end
    local b=value:FindFirstChild('Ball')
    if b and b:IsA('BasePart') then return b end
end
local function ownedBall(player)
    local ch=player.Character
    return ch and part(ch:FindFirstChild('Ball'))
end
local function holder(ball)
    local parent=ball.Parent
    for _=1,4 do
        if not parent or parent==workspace then return end
        if parent:IsA('Model') then
            local player=Players:GetPlayerFromCharacter(parent)
            if player then return player end
        end
        parent=parent.Parent
    end
end
-- The original project identifies the match ball by GameBall on its container,
-- not by a part named GameBall. Cache top-level Ball containers only.
local ballContainers={}
local function cacheBall(object)
    if object.Name=='Ball' then ballContainers[object]=true end
end
for _,object in ipairs(workspace:GetChildren()) do cacheBall(object) end
connect(workspace.ChildAdded,cacheBall)
connect(workspace.ChildRemoved,function(object) ballContainers[object]=nil end)
local function isGameBall(ball)
    local object=ball
    for _=1,3 do
        if not object or object==workspace then return false end
        if object:GetAttribute('GameBall') then return true end
        object=object.Parent
    end
    return false
end
local function looseGameBall()
    if workspace:GetAttribute('GameEnded') then return end
    local found
    for object in pairs(ballContainers) do
        if object.Parent==workspace and object:GetAttribute('GameBall') then
            local ball=part(object)
            if ball and not holder(ball) then
                if found and found~=ball then return end -- Ambiguous: don't guess.
                found=ball
            end
        end
    end
    return found
end
local function ready(character,humanoid)
    if not humanoid or humanoid.Health<=0 then return false,'character unavailable' end
    if character:FindFirstChild('Ball') then return false,'already holding a ball' end
    if character:FindFirstChild('HoldingSkill') or Player:GetAttribute('UsingSkill') then return false,'another skill active' end
    if workspace:GetAttribute('PlayersAllowedToUseSkills')==false then return false,'skills disabled' end
    local state=Player:FindFirstChild('PlayerStateFolder')
    if state and state:FindFirstChild('Stun') then return false,'stunned' end
    local cd=RS:FindFirstChild('CooldownsFolder')
    if cd and cd:FindFirstChild(tostring(Player.UserId)..Config.Trap) then return false,Config.Trap..' on cooldown' end
    local equipped=Player:FindFirstChild('EquippedSkills')
    if equipped then
        for slot,skill in pairs(equipped:GetAttributes()) do
            if slot:match('^Slot') and skill==Config.Trap then return true end
        end
    end
    return false,Config.Trap..' not equipped'
end
-- First intersection with a sphere along one predicted segment. Sweeping
-- between samples prevents fast balls skipping over the trigger volume.
local function segmentEntry(a,b,radius)
    local c=a:Dot(a)-radius*radius
    if c<=0 then return 0 end
    local d=b-a
    local aa=d:Dot(d)
    if aa<0.000001 then return end
    local bb=2*a:Dot(d)
    local disc=bb*bb-4*aa*c
    if disc<0 then return end
    local t=(-bb-math.sqrt(disc))/(2*aa)
    if t>=0 and t<=1 then return t end
end
local function arrival(position,velocity,acceleration,root)
    local relative=position-root.Position
    local v=velocity-root.AssemblyLinearVelocity
    local prev=relative
    -- A close ball is actionable even before curve samples stabilize.
    if relative.Magnitude<=Config.Radius then return 0 end
    for t=Config.PathStep,Config.Horizon+0.000001,Config.PathStep do
        local nextPoint=relative+v*t+acceleration*(0.5*t*t)
        local entry=segmentEntry(prev,nextPoint,Config.Radius)
        if entry then return t-Config.PathStep+entry*Config.PathStep end
        prev=nextPoint
    end
end
local function sample(record,position,now)
    if not record.position then
        record.position,record.at=position,now
        record.count,record.acceleration=0,Vector3.zero
        return false
    end
    local dt=now-record.at
    local displacement=position-record.position
    if dt<=0 then return false end
    if dt>0.2 or displacement.Magnitude>80 then
        record.position=nil;record.velocity=nil;record.previousVelocity=nil
        return false
    end
    -- Repeated replicated positions are not proof the moving ball stopped.
    -- Preserve the last estimate briefly and measure across the entire update gap.
    if displacement.Magnitude<0.01 then
        return record.velocity~=nil and dt<=0.10
    end
    local measured=displacement/dt
    if record.previousVelocity then
        local a=(measured-record.previousVelocity)/((dt+(record.previousDt or dt))*0.5)
        -- A bounce, teleport or sudden deflection invalidates the smooth curve.
        if a.Magnitude>Config.MaxAcceleration*3 then
            record.acceleration=Vector3.zero;record.count=0
        else
            if a.Magnitude>Config.MaxAcceleration then a=a.Unit*Config.MaxAcceleration end
            record.acceleration=record.acceleration*0.6+a*0.4
        end
    end
    record.velocity=measured
    record.previousVelocity,record.previousDt=measured,dt
    record.position,record.at=position,now
    record.count=record.count+1
    -- Replication can alternate stationary and moving frames. Such jumps reset
    -- acceleration confidence, but must not discard a usable velocity estimate.
    return true
end
local function predictEntry(record,ball,root,now)
    local position=ball.Position
    if (position-root.Position).Magnitude<=Config.Radius then return 0 end
    if sample(record,position,now) then
        local acceleration=record.acceleration
        local velocity=record.velocity+acceleration*(0.5*(record.previousDt or 0))
        local age=math.min(math.max(now-record.at,0),0.08)
        position=position+velocity*age+acceleration*(0.5*age*age)
        return arrival(position,velocity+acceleration*age,acceleration,root)
    end
    -- Physics velocity can be available on the first released frame, before
    -- there are enough position updates. Position-derived motion takes over.
    local velocity=ball.AssemblyLinearVelocity
    if velocity.Magnitude>2 and (not record.previousVelocity) then
        return arrival(position,velocity,Vector3.zero,root)
    end
end
local Gui=Instance.new('ScreenGui')
Gui.Name='PKAAutoTrapTest';Gui.ResetOnSpawn=false;Gui.Parent=Player:WaitForChild('PlayerGui')
local panel=Instance.new('Frame')
panel.Size=UDim2.fromOffset(310,300);panel.Position=UDim2.new(0,20,0.5,-150)
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
label('PKA AUTO TRAP — TEST',7)
local enabledButton
local function toggle()
    Config.Enabled=not Config.Enabled;table.clear(tracked);table.clear(captured)
    enabledButton.Text=Config.Enabled and 'ON (F8)' or 'OFF (F8)'
    report(Config.Enabled and 'Waiting for a PKA shot event...' or 'Disabled',true)
end
enabledButton=button('ON (F8)',10,35,290,toggle)
local trapButton
local choices={'Black Hole Trap','Creative Trap','Zero Reset Turn'}
local choice=1
trapButton=button('Trap: '..Config.Trap,10,68,290,function()
    choice=choice%#choices+1;Config.Trap=choices[choice];trapButton.Text='Trap: '..Config.Trap
end)
local radiusText=label('Trigger radius: 12 studs',103)
local leadText=label('Activation lead: 220 ms',160)
button('- radius',10,129,140,function()
    Config.Radius=math.max(3,Config.Radius-1);radiusText.Text='Trigger radius: '..Config.Radius..' studs'
end)
button('+ radius',160,129,140,function()
    Config.Radius=math.min(40,Config.Radius+1);radiusText.Text='Trigger radius: '..Config.Radius..' studs'
end)
local function lead(delta)
    Config.Lead=math.clamp(Config.Lead+delta,0,0.5)
    leadText.Text=string.format('Activation lead: %.0f ms',Config.Lead*1000)
end
button('- timing',10,186,140,function()lead(-0.01)end)
button('+ timing',160,186,140,function()lead(0.01)end)
status=label('Waiting for a PKA shot event...',218,40)
function Session.Unload()
    if not Session.Alive then return end
    Session.Alive=false
    for _,c in ipairs(Session.Connections) do c:Disconnect() end
    table.clear(tracked);table.clear(captured);Gui:Destroy()
    if Env.PKATrapTest==Session then Env.PKATrapTest=nil end
end
button('Unload',10,264,140,Session.Unload)
local hint=label('End: hide panel',266,22)
hint.Position=UDim2.fromOffset(155,266);hint.Size=UDim2.fromOffset(145,22)
connect(Input.InputBegan,function(input,processed)
    if processed or Input:GetFocusedTextBox() then return end
    if input.KeyCode==Enum.KeyCode.F8 then toggle()
    elseif input.KeyCode==Enum.KeyCode.End then panel.Visible=not panel.Visible end
end)
connect(Player.CharacterAdded,function()table.clear(tracked);table.clear(captured)end)
connect(Players.PlayerRemoving,function(player)
    captured[player]=nil
    for ball,r in pairs(tracked) do if r.shooter==player then tracked[ball]=nil end end
end)
local function trackBall(ball,shooter,now)
    if not ball or not ball.Parent then return false end
    local old=tracked[ball]
    -- Hold, UseSkill and Kick can describe the same release. Keep the sample
    -- history and one-shot request flag when an acknowledgement arrives later.
    if old and old.shooter==shooter and not holder(ball) then return true end
    local count=0;local oldest,oldestAt
    for b,r in pairs(tracked) do
        count=count+1
        if not oldestAt or r.started<oldestAt then oldest,oldestAt=b,r.started end
    end
    if count>=Config.MaxTracked and oldest then tracked[oldest]=nil end
    tracked[ball]={shooter=shooter,started=now,released=false,fired=false}
    report(holder(ball) and 'PKA ball identified; waiting for release' or 'PKA release detected; measuring curve',true)
    return true
end
local function pollCaptures(now)
    for shooter,r in pairs(captured) do
        if excluded(shooter) or shooter.Character~=r.character then
            captured[shooter]=nil
        elseif now-r.at>5 then
            captured[shooter]=nil
            report('Wind-up expired: no released ball identified',true)
        else
            -- Hold may precede replication of the character's Ball folder.
            if not r.ball or not r.ball.Parent then r.ball=ownedBall(shooter) end
            if r.ball and isGameBall(r.ball) then r.gameBall=true end
            -- Some releases replace the carried object with workspace.Ball.Ball.
            -- Only associate that replacement after this shooter held the match ball.
            if r.gameBall and not ownedBall(shooter) then
                local replacement=looseGameBall()
                if replacement and replacement~=r.beforeRelease then r.ball=replacement end
            end
            local ball=r.ball
            if ball and ball.Parent and ball:IsDescendantOf(workspace) then
                local owner=holder(ball)
                if not owner then
                    trackBall(ball,shooter,now)
                    captured[shooter]=nil
                elseif owner~=shooter then
                    captured[shooter]=nil
                    report('PKA tracking cancelled: ball changed holder',true)
                end
            end
        end
    end
end
connect(Event.OnClientEvent,function(action,shooter,style,skill,value)
    if not Session.Alive or not Config.Enabled or typeof(shooter)~='Instance' or not shooter:IsA('Player') then return end
    if style~='Perfect Kick Accuracy' and not ShotSkills[skill] then return end
    if Config.Debug then print('[PKA Trap event]',action,shooter.Name,style,skill,typeof(value)) end
    if not ShotSkills[skill] then return end
    if excluded(shooter) then report('Shot ignored: teammate, self or exception',true);return end
    local now=os.clock()
    if action=='Hold' then
        local ball=part(value) or ownedBall(shooter)
        captured[shooter]={ball=ball,at=now,character=shooter.Character,
            gameBall=ball and isGameBall(ball),beforeRelease=looseGameBall()}
        report('PKA wind-up detected; waiting for release',true);return
    end
    if not ShotActions[action] then report('PKA event seen: '..tostring(action),true);return end
    local saved=captured[shooter]
    local ball=part(value) or ownedBall(shooter) or (saved and now-saved.at<5 and saved.ball)
    if saved and saved.gameBall and not ownedBall(shooter) then ball=looseGameBall() or ball end
    if not ball or not ball.Parent then
        report('PKA event has no identifiable ball; check console',true);return
    end
    trackBall(ball,shooter,now)
    if not holder(ball) then captured[shooter]=nil end
end)
local elapsed=0
connect(RunService.Heartbeat,function(dt)
    if not Session.Alive or not Config.Enabled then return end
    elapsed=elapsed+dt
    if elapsed<Config.Interval then return end
    elapsed=elapsed%Config.Interval
    local now=os.clock()
    -- Poll wind-ups BEFORE the idle early return. A separate release broadcast
    -- is not required when the captured ball leaves the shooter's character.
    pollCaptures(now)
    if not next(tracked) then return end
    local character=Player.Character
    local root=character and character:FindFirstChild('HumanoidRootPart')
    local humanoid=character and character:FindFirstChildOfClass('Humanoid')
    if not root or not humanoid or humanoid.Health<=0 then table.clear(tracked);return end
    local best,bestEta=nil,math.huge
    local nearest,trackingMessage=math.huge,nil
    for ball,r in pairs(tracked) do
        if not ball.Parent or not ball:IsDescendantOf(workspace) or now-r.started>Config.MaxAge or excluded(r.shooter) then
            tracked[ball]=nil
            report('PKA tracking ended; waiting for next shot')
        elseif r.fired then
            if holder(ball) then tracked[ball]=nil end
        else
            local owner=holder(ball)
            if owner then
                if r.released or owner~=r.shooter then tracked[ball]=nil end
            else
                if not r.released then
                    r.started=now
                    report('PKA release detected; measuring curve',true)
                end
                r.released=true
                local position=ball.Position
                local distance=(position-root.Position).Magnitude
                local eta=predictEntry(r,ball,root,now)
                if eta and eta<bestEta then best,bestEta=r,eta end
                if distance<nearest then
                    nearest=distance
                    trackingMessage=string.format('Tracking: %.1f studs | radius %.0f | %s',distance,Config.Radius,
                        r.velocity and 'no entry predicted yet' or 'sampling movement')
                end
            end
        end
    end
    if best then
        if bestEta>Config.Lead+Config.Interval then
            report(string.format('Predicted entry: %.0f ms',bestEta*1000))
        elseif now-lastRequest<Config.RequestGap then
            report('Waiting: trap request cooldown')
        else
            local canTrap,reason=ready(character,humanoid)
            if canTrap then
                best.fired=true;lastRequest=now
                Event:FireServer(TrapActions[Config.Trap],Config.Trap)
                report('Trap requested: '..Config.Trap,true)
            else report('Waiting: '..reason) end
        end
    elseif trackingMessage then
        report(trackingMessage)
    end
end)
