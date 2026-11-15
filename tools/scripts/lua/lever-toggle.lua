-- @title Lever that opens a gate
-- @category Doors and buttons
-- @kind Script
-- @where Put this Script inside a Model with a Part named Lever and a Folder named Gate holding the gate Parts.
-- @keywords lever, pull the lever, lever switch, flip a lever, lever opens gate
-- @about Click the lever to flip it; the gate parts disappear, and flipping it back brings them back.

-- Settings: change these!
local FLIP_ANGLE = 60 -- degrees the lever tilts

local model = script.Parent
local lever = model:WaitForChild("Lever")
local gate = model:WaitForChild("Gate")
local upCFrame = lever.CFrame
local downCFrame = upCFrame * CFrame.Angles(math.rad(FLIP_ANGLE), 0, 0)

local clicker = Instance.new("ClickDetector")
clicker.MaxActivationDistance = 15
clicker.Parent = lever

local pulled = false
clicker.MouseClick:Connect(function()
	pulled = not pulled
	lever.CFrame = pulled and downCFrame or upCFrame
	for _, part in ipairs(gate:GetDescendants()) do
		if part:IsA("BasePart") then
			part.CanCollide = not pulled
			part.Transparency = pulled and 1 or 0
		end
	end
end)
