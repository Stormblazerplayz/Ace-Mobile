-- @title Drawbridge
-- @category Moving parts
-- @kind Script
-- @where Put this Script inside the bridge Part (not anchored) and add an Anchored Part named BridgeHinge at the end of the bridge, turned so its red X arrow runs along the hinge line.
-- @keywords drawbridge, castle bridge, bridge goes up and down, lower the bridge, moat bridge
-- @about Press E on the bridge hinge to raise or lower the bridge with a smooth physics hinge.

-- Settings: change these numbers!
local UP_ANGLE = 80 -- degrees when raised (use -80 if it swings the wrong way)
local SWING_SPEED = 1 -- radians per second

local bridge = script.Parent
local hingePart = bridge.Parent:WaitForChild("BridgeHinge")
hingePart.Anchored = true

local a0 = Instance.new("Attachment")
a0.Parent = hingePart
local a1 = Instance.new("Attachment")
a1.Parent = bridge
a1.WorldCFrame = a0.WorldCFrame -- both attachments sit in the same spot

-- A Servo hinge turns to TargetAngle and holds it there
local hinge = Instance.new("HingeConstraint")
hinge.Attachment0 = a0
hinge.Attachment1 = a1
hinge.ActuatorType = Enum.ActuatorType.Servo
hinge.ServoMaxTorque = 1e9
hinge.AngularSpeed = SWING_SPEED
hinge.TargetAngle = 0
hinge.Parent = bridge

bridge.Anchored = false
bridge:SetNetworkOwner(nil)

local prompt = Instance.new("ProximityPrompt")
prompt.ActionText = "Raise bridge"
prompt.ObjectText = "Drawbridge"
prompt.MaxActivationDistance = 15
prompt.Parent = hingePart

prompt.Triggered:Connect(function()
	if hinge.TargetAngle == 0 then
		hinge.TargetAngle = UP_ANGLE
		prompt.ActionText = "Lower bridge"
	else
		hinge.TargetAngle = 0
		prompt.ActionText = "Raise bridge"
	end
end)
