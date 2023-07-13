[Get Projectile Module](https://github.com/amandania/Projectile/blob/main/src/ReplicatedStorage/Shared/Projectile.lua)

Projectile module is used to simulate a projectile motion in various ways.
 - Curved Motion
 - Linear Motion
 - Arch Motion
 - Gravity Motion
 - In place circular motion that curves around the start cframe
    - Start and end cframe must be the same for this to happen

#
### Its Important to note when constructing a projectile object, if gravity and arc are given in the parameters then only arc will get used.
#

Here is a basic example of how i use this projecitle module.

```lua
local model = workspace.Part
local blacklist = { workspace.Visuals }
local currentCFrame = model.CFrame
local endCFrame = model.CFrame + model.CFrame.LookVector * 15
local lifetime = 1 -- 1 second
local gravity = 0; -- No gravity. This can be nil aswell
local height = 10; -- arc, remeber if gravity is wanted we need this to be 0 or nil
local reachGround = false;
local width = 3; -- how fat of curve do i want
local curve = 5; -- speed of curve i believe
local debugMode = false; -- do i want to draw the parts

local launch = Projectile.new(model, blacklist, currentCFrame, endCFrame, lifetime, gravity, height, reachGround, width, curve, debugMode)

-- conenct the onupdate so our part can follow the motion
launch:Connect("OnUpdate", function(lastCframe, newCframe, progress)
    model.CFrame = newCFrame
end)

launch:Fire() -- Start the projectile motion 
```

This sample code will have a slight curve with some arc to reach the end goal 