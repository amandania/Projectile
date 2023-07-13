--[=[
    @class Projectile
    @tag Akshay Mandania
    This class is used to simiulate the motion of a projectile. You can connect into the OnUpdate event to get the current CFrame of the projectile at any time. This is normally used to update the position of a model or part.
]=]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Signal = require(ReplicatedStorage.Source.Utils.Signal)
local Maid = require(ReplicatedStorage.Source.Utils.Maid)
local CreateInstance = require(ReplicatedStorage.Source.Utils.CreateInstance)
local Projectile = {}
Projectile.__index = Projectile

--[=[
    Constructor function to create a Projectile Object. Keep in mind, when you provide an arch height a gravity value will not be applied. If you provide neither it will just go  in a straight line assuming it is not defined to go in a circle.
    
    @param model -- The model or part to simulate the motion of.
    @param raycastIgnoreDescendants -- A table of descendants to ignore when raycasting.
    @param StartCFrame -- The starting CFrame of the projectile.
    @param EndCFrame -- The ending CFrame of the projectile.
    @param Lifetime -- The lifetime of the projectile in seconds.
    @param Gravity -- The gravity of the projectile.
    @param ArchHeight -- The height of the arch of the projectile.
    @param gotoGround -- Whether or not the projectile should go to the ground.
    @param Width -- The width of the projectile.
    @param Curve -- The curve of the projectile.
    @param inCircle -- Whether or not the projectile should go in a circle.
    @param debug -- Whether or not to debug the projectile.
    @return Projectile.
]=]
function Projectile.new(model : Instance, raycastIgnoreDescendants : {}, StartCFrame : CFrame, EndCFrame : CFrame, Lifetime : number, Gravity : number, ArchHeight : number, gotoGround : boolean, Width : number, Curve : number, inCircle : boolean, debug : boolean)
    local self = setmetatable({}, Projectile)
    self.StartCFrame = StartCFrame
    self.EndCFrame = EndCFrame
    self.inCircle = inCircle
    self._active = true;
    self.OriginalStart = StartCFrame
    self.OriginalEnd = EndCFrame
    self.debugProjectile = debug
    self.Lifetime = Lifetime
    self.ArchHeight = ArchHeight or 0
    self.Gravity = Gravity or 0
    self.Width = Width or 0
    self.Curve = Curve or 0
    self.OnUpdate = Signal.new()
    self.OnComplete = Signal.new()
    self.OnHit = Signal.new()
    self.CurrentCFrame = StartCFrame
    self.model = model;
    self.raycastIgnoreDescendants = raycastIgnoreDescendants
    self.hasHit = {}
    local rayParams = RaycastParams.new()
    rayParams.FilterDescendantsInstances = self.raycastIgnoreDescendants or {model, workspace.Visuals}
    rayParams.FilterType = Enum.RaycastFilterType.Blacklist
    self.raycastParams = rayParams
    self.maid = Maid.new()
    self.maid:GiveTask(self.OnUpdate)
    self.maid:GiveTask(self.OnComplete)
    self.maid:GiveTask(self.OnHit)
    if gotoGround then
        model = typeof(model) == "table" and model.model or model
        local castResults = workspace:Raycast(self.EndCFrame.Position + Vector3.new(0, 8, 0), Vector3.new(0, -100, 0), rayParams)
        if castResults.Position then
            local rotationOfEnd = self.EndCFrame - self.EndCFrame.Position
            local originalEndCFrame = self.EndCFrame
            self.EndCFrame = CFrame.new(castResults.Position + (castResults.Normal)) * CFrame.Angles(math.deg(rotationOfEnd.X), math.deg(rotationOfEnd.Y), math.deg(rotationOfEnd.Z))
            self.EndCFrame += Vector3.new(0, model:IsA("Model") and model.PrimaryPart.Size.Y or model.Size.Y, 0)
            self.EndCFrame = CFrame.new(self.EndCFrame.Position, (originalEndCFrame.Position * Vector3.new(1, 0, 1)) + (self.EndCFrame.Position * Vector3.new(0, 1, 0)))
        end
    end
    return self
end

--[=[
    Starts the projectile and update its current CFrame. This will fire the OnUpdate event and the OnComplete event when the projectile has reached its end lifetime or hit something.

    @param hitOffset -- The max distance between the projectile and the hit. Assume there is a fireball and it was casted towards a wall. The offset between the projectile and the wall can be any number causing it stop earlier or later then a raycast would be.
    @param ignoreHit -- Whether or not to ignore the hit offset
]=]
function Projectile:Fire(hitOffset : number, ignoreHit : boolean)
    local start = self.StartCFrame
    local goal = self.EndCFrame
    local lifetime = self.Lifetime
    local archHeight = self.ArchHeight
    local gravity = self.Gravity
    local width = self.Width
    local curve = self.Curve
    local lastPos = start
    local pos = start
    local t = 0
    local dt = 1/60
    self.parts = {}

    self.hitOffset = hitOffset
    self.ignoreHit = ignoreHit
    local samePosition = start.Position == goal.Position
    if samePosition then
        self.inCircle = true;
        start += goal.LookVector*curve
    end
    
    local function step()
        if not self._active then
            self.OnComplete:Fire(lastPos, pos)
            return
        end
        t = t + dt
        local percent = t/lifetime
        
        local x = start.Position.X + (goal.Position.X - start.Position.X)*percent
        local y = start.Position.Y + (goal.Position.Y - start.Position.Y)*percent
        local z = start.Position.Z + (goal.Position.Z - start.Position.Z)*percent

       

        if self.inCircle then
            if samePosition then
                x = start.Position.X + math.cos(math.pi*percent*2)*curve
            else
                x = start.Position.X + ((goal.Position.X - start.Position.X)*percent) * math.cos(math.pi*percent*2)*curve
            end
            z = start.Position.Z + math.sin(math.pi*percent*2)*curve
        end
    
        y = y + archHeight*math.sin(math.pi*percent)
        x = x + width*math.sin(math.pi*percent)
        z = z + curve*math.sin(math.pi*percent)

        if archHeight == 0 and gravity then
            y = start.Position.Y + (goal.Position.Y - start.Position.Y)*percent - (0.5*gravity*percent^2)
        end
        self.currentLifetime = lifetime * percent
        lastPos = pos
        local rotation = pos - pos.Position
        pos = CFrame.new(x, y, z) * rotation    
        self.raycastParams.FilterDescendantsInstances = self.raycastIgnoreDescendants or {self.model}

        hitOffset = hitOffset or 0
        local hit = workspace:Raycast(lastPos.Position, (pos.Position - lastPos.Position).Unit * ((pos.Position - lastPos.Position).Magnitude + hitOffset), self.raycastParams)
        if hit and not self.hasHit[hit.Instance] and not ignoreHit then
            self.hasHit[hit.Instance] = true;
            self.OnHit:Fire(hit)
            self.OnComplete:Fire(lastPos, pos)
            return false;
        end
        
        self.OnUpdate:Fire(lastPos, pos, percent)
        if RunService:IsClient() and self.debugProjectile then
            table.insert(self.parts, CreateInstance("Part", { Size = Vector3.new(1, 1, 1), Color = Color3.new(1, 0, 0), Transparency = 0.5, Anchored = true, CanCollide = false, CFrame = pos, Parent = workspace }))
        end
        
        self.CurrentCFrame = pos
        if t >= lifetime then
            self.OnComplete:Fire(lastPos, pos)
            return false
        end
        
        return true
    end
    self.connection = game:GetService("RunService").Heartbeat:Connect(function()
        if not step() then
            self._active = false;
            self.connection:Disconnect()
            return
        end
        self._active = true;
    end)
end

--[=[
    This function will connect a callback function to a signal. The signal can be OnUpdate, OnComplete, or OnHit.
    
    @param signalName -- The name of the signal to connect to
    @param functionCallback -- The function to call when the signal is fired
]=]
function Projectile:Connect(signalName : string, functionCallback : any)
    if not self[signalName] then
        warn("Signal " .. signalName .. " does not exist")
        return
    end
    self.maid:GiveTask(self[signalName]:Connect(functionCallback))
end


--[=[
    This function will disconnect the active connection for updating the projectile data. Import to note this will not fire the OnComplete event.
 ]=]
function Projectile:Stop()
    self._active = false;
    self.connection:Disconnect()
end

--[=[
    This function will resume the projectile from the current position.
 ]=]
function Projectile:Resume()
    self.StartCFrame = self.CurrentCFrame
    self:Fire(self.hitOffset, self.ignoreHit)
end

--[=[
    This function will reverse the projectile from the current position. This will fire the OnComplete event when the projectile has reached its end lifetime or hit something.

    @param withOffset -- The offset to add to the end position. This is useful if you want to reverse the projectile from the current position but not to the original start position.
 ]=]
function Projectile:Reverse(withOffset : number)
    self:Stop()
    self.hasHit = {}
    self.EndCFrame = self.OriginalStart
    if withOffset then
        self.EndCFrame += withOffset
    end
    local distanceFromCurrentToStart = self.EndCFrame.Position.Y - self.CurrentCFrame.Position.Y
    self.Gravity = distanceFromCurrentToStart
    self.Lifetime = (self.Lifetime - self.currentLifetime)
    self:Resume()
end

--[=[
    This function will destroy the projectile and disconnect all connections.
 ]=]
function Projectile:Destroy()
    self.maid:DoCleaning()

    if self.connection then
        self.connection:Disconnect()
    end
    self._active = false;
    self = nil;
end

return Projectile

