-- @title Tilting platform
-- @category Obstacles
-- @kind Script
-- @where Put this Script inside a flat Part (it does not need to be Anchored) that players stand on.
-- @keywords tilting platform, seesaw platform, wobbly platform, tipping floor, balance platform
-- @about The platform tips over when players stand near the edge and slowly levels out again.

-- Settings: change these numbers!
local SPRING_STIFFNESS = 20000 -- how hard it pushes back to level
local SPRING_DAMPING = 3000 -- stops it wobbling forever
local MAX_TILT = 35 -- most it can tip (degrees)

local platform = script.Parent
platform.Anchored = false

-- An invisible anchored part in the middle holds the platform up
local anchor = Instance.new("Part")
anchor.Name = "TiltAnchor"
anchor.Size = Vector3.new(1, 1, 1)
anchor.Transparency = 1
anchor.CanCollide = false
anchor.Anchored = true
anchor.CFrame = platform.CFrame
anchor.Parent = platform.Parent

local a0 = Instance.new("Attachment")
a0.Parent = anchor
local a1 = Instance.new("Attachment")
a1.Parent = platform

-- The hinge lets it tip around the X axis
local hinge = Instance.new("HingeConstraint")
hinge.Attachment0 = a0
hinge.Attachment1 = a1
hinge.LimitsEnabled = true
hinge.UpperAngle = MAX_TILT
hinge.LowerAngle = -MAX_TILT
hinge.Parent = platform

-- The spring tries to bring it back to flat
local spring = Instance.new("TorsionSpringConstraint")
spring.Attachment0 = a0
spring.Attachment1 = a1
spring.Stiffness = SPRING_STIFFNESS
spring.Damping = SPRING_DAMPING
spring.Parent = platform

platform:SetNetworkOwner(nil) -- the server runs its physics so everyone sees the same tilt
