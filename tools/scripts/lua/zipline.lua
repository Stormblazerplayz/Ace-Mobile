-- @title Zipline
-- @category Moving parts
-- @kind LocalScript
-- @where Put this LocalScript in StarterPlayer > StarterPlayerScripts, then make a Model in Workspace with two Parts named ZipStart and ZipEnd, and put a ProximityPrompt named Zipline inside ZipStart.
-- @keywords zipline, zip line, slide down a rope, ride the cable, zip wire
-- @about Press E at the start of a zipline to zoom along the cable to the end.

local Players = game:GetService("Players")
local ProximityPromptService = game:GetService("ProximityPromptService")
local RunService = game:GetService("RunService")

-- Settings: change these numbers!
local SPEED = 50 -- studs per second
local HANG_BELOW = 3.5 -- how far below the cable your body hangs

local player = Players.LocalPlayer
local riding = false

ProximityPromptService.PromptTriggered:Connect(function(prompt)
	-- Only zipline prompts, and only one ride at a time
	if prompt.Name ~= "Zipline" or riding then
		return
	end
	local startPart = prompt.Parent
	local endPart = startPart.Parent:FindFirstChild("ZipEnd")
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not endPart or not humanoid or not root then
		return
	end

	riding = true
	humanoid.PlatformStand = true -- stop walking while hanging on
	local from = startPart.Position - Vector3.new(0, HANG_BELOW, 0)
	local to = endPart.Position - Vector3.new(0, HANG_BELOW, 0)
	local direction = (to - from).Unit
	local travelTime = (to - from).Magnitude / SPEED
	local started = os.clock()

	local connection
	connection = RunService.Heartbeat:Connect(function()
		local alpha = math.min((os.clock() - started) / travelTime, 1)
		-- Slide along the line and face the way we are going
		root.CFrame = CFrame.lookAt(from:Lerp(to, alpha), from:Lerp(to, alpha) + Vector3.new(direction.X, 0, direction.Z))
		root.AssemblyLinearVelocity = direction * SPEED
		if alpha >= 1 or humanoid.Health <= 0 then
			connection:Disconnect()
			humanoid.PlatformStand = false
			root.AssemblyLinearVelocity = direction * 20 -- a little hop off the end
			riding = false
		end
	end)
end)
