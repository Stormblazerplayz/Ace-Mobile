-- @title Plants swaying in the wind
-- @category World and effects
-- @kind LocalScript
-- @where Put this LocalScript in StarterPlayer > StarterPlayerScripts and put your Anchored grass, flower and bush parts in a Folder named Plants in Workspace.
-- @keywords swaying plants, grass moves in wind, wind animation, waving flowers, swaying trees
-- @about Gently rocks every plant back and forth like a breeze is blowing (on each player's screen, so it is smooth and free for the server).

local RunService = game:GetService("RunService")

-- Settings: change these numbers!
local SWAY_DEGREES = 6
local SWAY_SPEED = 1.5

local folder = workspace:WaitForChild("Plants")
local plants = {}

-- Remember where each plant started, and pivot from its bottom so it bends like a stem
for _, part in ipairs(folder:GetDescendants()) do
	if part:IsA("BasePart") then
		local bottom = part.CFrame * CFrame.new(0, -part.Size.Y / 2, 0)
		table.insert(plants, {
			part = part,
			bottom = bottom,
			offset = bottom:ToObjectSpace(part.CFrame),
			phase = math.random() * math.pi * 2, -- so they do not all move together
		})
	end
end

RunService.RenderStepped:Connect(function()
	local t = os.clock() * SWAY_SPEED
	local camera = workspace.CurrentCamera.CFrame.Position
	for _, plant in ipairs(plants) do
		-- Skip faraway plants to save time
		if (plant.bottom.Position - camera).Magnitude < 150 then
			local angle = math.rad(math.sin(t + plant.phase) * SWAY_DEGREES)
			plant.part.CFrame = plant.bottom * CFrame.Angles(angle, 0, angle * 0.5) * plant.offset
		end
	end
end)
