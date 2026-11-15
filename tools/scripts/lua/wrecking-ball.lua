-- @title Wrecking ball
-- @category Moving parts
-- @kind Script
-- @where Put this Script inside an unanchored Ball Part, and put an Anchored Part named BallPivot above it where the chain hangs from.
-- @keywords wrecking ball, swinging ball, demolition ball, ball on a chain, knock players over
-- @about The heavy ball swings on a chain forever and sends players flying if it hits them.

local Players = game:GetService("Players")

-- Settings: change these numbers!
local PUSH_EVERY = 2.5 -- seconds between pushes that keep it swinging
local PUSH_POWER = 30 -- how hard each push is
local KNOCK_POWER = 100 -- how far players fly

local ball = script.Parent
local pivot = ball.Parent:WaitForChild("BallPivot")
pivot.Anchored = true
ball.Anchored = false

-- A rod keeps the ball the same distance from the pivot (like a stiff chain)
local a0 = Instance.new("Attachment")
a0.Parent = pivot
local a1 = Instance.new("Attachment")
a1.Parent = ball
local rod = Instance.new("RodConstraint")
rod.Attachment0 = a0
rod.Attachment1 = a1
rod.Length = (pivot.Position - ball.Position).Magnitude
rod.Visible = true
rod.Thickness = 0.4
rod.Parent = ball

ball:SetNetworkOwner(nil)

local recent = {}
ball.Touched:Connect(function(hit)
	local character = hit.Parent
	local player = Players:GetPlayerFromCharacter(character)
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if player and root and not recent[player] and ball.AssemblyLinearVelocity.Magnitude > 10 then
		recent[player] = true
		root.AssemblyLinearVelocity = ball.AssemblyLinearVelocity.Unit * KNOCK_POWER + Vector3.new(0, 30, 0)
		task.delay(1, function()
			recent[player] = nil
		end)
	end
end)

-- Keep it swinging: push the way it is already moving
local direction = pivot.CFrame.LookVector
while true do
	local velocity = ball.AssemblyLinearVelocity
	local flat = Vector3.new(velocity.X, 0, velocity.Z)
	if flat.Magnitude > 1 then
		direction = flat.Unit
	end
	ball:ApplyImpulse(direction * ball.AssemblyMass * PUSH_POWER)
	task.wait(PUSH_EVERY)
end
