local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LocalPlayer = Players.LocalPlayer

-- Usernames excluded from opponent-targeted automation (case-insensitive).
local Exceptions = {thenextnagi = true, leothedominican = true}
local function isExcepted(player)
    return player ~= nil and Exceptions[string.lower(player.Name)] == true
end

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
local State = {
    Metavision = false, BallPrediction = false, BallETA = false, ReboundAlert = false,
    AutoTD = false, TDRange = 8, TDPrediction = 0.12, TDAdaptive = true, TDHold = 0.4,
}
local RunService = game:GetService("RunService")
local Player, RS, Event = LocalPlayer, ReplicatedStorage, Transceiver
local Session = {Alive = true, Connections = {}}
local Character, Root, Humanoid
local rotationHumanoid, originalAutoRotate
local lastAutoTD, lastTackle, tdFacingUntil, tdTarget = -math.huge, -math.huge, 0, nil
local cleanupMetavision, resetMetavision
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
local function refreshCharacter()
    local current = LocalPlayer.Character
    if Character ~= current then
        releaseRotation()
        tdTarget, tdFacingUntil = nil, 0
    end
    Character = current
    Root = current and current:FindFirstChild("HumanoidRootPart")
    Humanoid = current and current:FindFirstChildOfClass("Humanoid")
end
refreshCharacter()

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
Frame.Size = UDim2.new(0, 220, 0, 117)
Frame.Position = UDim2.new(0, 15, 0, 15)

Frame.BackgroundColor3 =
    Color3.fromRGB(25, 25, 25)

Frame.BorderSizePixel = 0

Frame.Parent = ScreenGui
local GuiVisible = true

local Corner = Instance.new("UICorner")
Corner.CornerRadius = UDim.new(0, 8)
Corner.Parent = Frame

--------------------------------------------------
--// LABEL
--------------------------------------------------

local Status = Instance.new("TextLabel")

Status.Size = UDim2.new(1, 0, 0, 39)

Status.BackgroundTransparency = 1

Status.Font = Enum.Font.GothamBold
Status.TextSize = 15

Status.Text = "AUTO TRAP: ON"

Status.TextColor3 =
    Color3.fromRGB(85, 255, 85)

Status.Parent = Frame
local MetavisionStatus = Status:Clone()
MetavisionStatus.Name = "MetavisionStatus"
MetavisionStatus.Position = UDim2.new(0, 0, 0, 39)
MetavisionStatus.Parent = Frame
local TDStatus = Status:Clone()
TDStatus.Name = "AutoTDStatus"
TDStatus.Position = UDim2.new(0, 0, 0, 78)
TDStatus.Parent = Frame

--------------------------------------------------
--// UPDATE GUI
--------------------------------------------------

local function UpdateGUI()
    local function update(label, title, enabled)
        label.Text = title .. (enabled and ": ON" or ": OFF")
        label.TextColor3 = enabled and Color3.fromRGB(85, 255, 85) or Color3.fromRGB(255, 80, 80)
    end
    update(Status, "[F2] AUTO TRAP", AutoTrapEnabled)
    update(MetavisionStatus, "[F3] METAVISION", State.Metavision)
    update(TDStatus, "[F4] AUTO TD", State.AutoTD)
end

connect(UserInputService.InputBegan, function(input, gameProcessed)
    -- End hides only the control panel; Metavision visuals stay active.
    if input.KeyCode == Enum.KeyCode.End then
        GuiVisible = not GuiVisible
        Frame.Visible = GuiVisible
        ScreenGui.Enabled = GuiVisible
        return
    end
    if gameProcessed or UserInputService:GetFocusedTextBox() then return end
    if input.KeyCode == Enum.KeyCode.F2 then
        AutoTrapEnabled = not AutoTrapEnabled
    elseif input.KeyCode == Enum.KeyCode.F3 then
        State.Metavision = not State.Metavision
        State.BallPrediction, State.BallETA, State.ReboundAlert = State.Metavision, State.Metavision, State.Metavision
        if resetMetavision then resetMetavision() end
    elseif input.KeyCode == Enum.KeyCode.F4 then
        State.AutoTD = not State.AutoTD
        if not State.AutoTD then
            tdTarget, tdFacingUntil = nil, 0
            releaseRotation()
        end
    else return end
    UpdateGUI()
end)

--------------------------------------------------
--// NORMAL AUTO TRAP
--
-- Impact Shot
-- Explosive Kick
--------------------------------------------------

connect(Transceiver.OnClientEvent, function(
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

    if typeof(player) ~= "Instance" or not player:IsA("Player") or player == LocalPlayer or isExcepted(player) then
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

connect(Transceiver.OnClientEvent, function(
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

    if typeof(player) ~= "Instance" or not player:IsA("Player") or player == LocalPlayer or isExcepted(player) then
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
--// AUTO TD: opponent selection, predictive aim and measured adaptation
--------------------------------------------------
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
local tdReady,rushTargetValid,tdTargetPosition,startAutoTD,trackAutoTD,observeAutoTD
do
local attempt,leadAdjustment=nil,0
local hits,misses,ignored=0,0,0
Session.TDAttempts={}
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
end
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
    if tdTarget or not Root or not Root.Parent or not tdReady(now) then return end
    local best, bestScore = nil, math.huge
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= Player and not isExcepted(player) and not sameTeam(player) then
            local character = player.Character
            local root = character and character:FindFirstChild("HumanoidRootPart")
            local humanoid = character and character:FindFirstChildOfClass("Humanoid")
            local folder = character and character:FindFirstChild("Ball")
            local ball = folder and folder:FindFirstChild("Ball")
            if root and humanoid and ball and ball:IsA("BasePart") then
                local candidate = {player=player, character=character, root=root, humanoid=humanoid, ball=ball}
                if rushTargetValid(candidate) then
                    local _, score, eligible = tdTargetPosition(candidate)
                    if eligible and score < bestScore then best, bestScore = candidate, score end
                end
            end
        end
    end
    if best then startAutoTD(best, now) end
end
local defenseElapsed = 0
connect(RunService.Heartbeat, function(dt)
    if not Session.Alive then return end
    refreshCharacter()
    local now = os.clock()
    observeAutoTD(now)
    defenseElapsed = defenseElapsed + dt
    if defenseElapsed >= 0.03 then
        defenseElapsed = 0
        if State.AutoTD then defenseStep(now) end
    end
end)
connect(RunService.RenderStepped, function()
    if Session.Alive then trackAutoTD(os.clock()) end
end)

--------------------------------------------------
--// METAVISION: air / rolling marker, ETA and rebound cue
--------------------------------------------------
local function ui(class, parent, properties)
    local object = Instance.new(class)
    for key, value in pairs(properties) do object[key] = value end
    object.Parent = parent
    return object
end
local function rounded(object, radius)
    ui("UICorner", object, {CornerRadius=UDim.new(0, radius)})
end
local function gameBall(players)
    if workspace:GetAttribute("GameEnded") then return end
    local fallback
    for _, object in ipairs(workspace:GetChildren()) do
        if object.Name == "Ball" then
            local ball = object:IsA("BasePart") and object or object:FindFirstChild("Ball")
            if ball and ball:IsA("BasePart") then
                if object:GetAttribute("GameBall") then return ball end
                fallback = fallback or ball
            end
        end
    end
    return fallback
end
cleanupMetavision=(function()
-- Local visual aids: no remotes are sent by these features.
local visualFolder=Instance.new('Folder')
visualFolder.Name='LebronMetavisionVisuals'
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
    if not State.ReboundAlert then return end
    if workspace:GetAttribute('GameEnded') then hideCue(reboundCue);return end
    local ball=freeVisualBall(now)
    if not ball then hideCue(reboundCue);return end
    local params=visualRayParams(ball,now)
    if State.ReboundAlert and now<reboundUntil and ball==reboundBall then
        local projected=ball.Position+ball.AssemblyLinearVelocity*0.22
        local ground=workspace:Raycast(projected+Vector3.new(0,12,0),Vector3.new(0,-75,0),params)
        if ground and ground.Normal.Y>=0.65 then moveCue(reboundCue,ground.Position)
        else hideCue(reboundCue) end
    else hideCue(reboundCue) end
end
resetMetavision = function()
    hideLanding()
    hideBallETA()
    hideCue(reboundCue)
    reboundBall, previousBounceVelocity, reboundUntil = nil, nil, 0
    visualBall, nextBallSearch, nextFilterRefresh = nil, 0, 0
end
local visualElapsed = 0
connect(RunService.Heartbeat, function(dt)
    if not Session.Alive or not State.Metavision then return end
    visualElapsed = visualElapsed + dt
    if visualElapsed < 0.05 then return end
    visualElapsed = 0
    local now = os.clock()
    observeBounce(freeVisualBall(now), now)
    updateBallVisuals()
    updateFieldCues(now)
end)
return function()
    resetMetavision()
    visualFolder:Destroy()
end
end)()

-- Destroying this panel releases rotation, visuals and all event connections.
connect(ScreenGui.Destroying, function()
    Session.Alive = false
    tdTarget = nil
    releaseRotation()
    if cleanupMetavision then cleanupMetavision() end
    for _, connection in ipairs(Session.Connections) do connection:Disconnect() end
    table.clear(Session.Connections)
    _G.AutoTrapOnlyRunning = nil
end)
UpdateGUI()
print("Auto Trap Hub loaded | F2 = Auto Trap | F3 = Metavision | F4 = Auto TD | End = Show/Hide")
