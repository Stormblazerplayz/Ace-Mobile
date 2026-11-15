-- @title Stairs that rise from the floor
-- @category Moving parts
-- @kind Script
-- @where Put this Script inside a Model that has a Part named Button and a Folder named Steps holding Anchored step Parts named 1, 2, 3 and so on (build them where they should end up).
-- @keywords stairs appear, rising stairs, hidden steps, secret staircase, steps come out of the floor
-- @about Touching the button makes hidden stairs rise out of the floor one step at a time, then sink back later.

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

-- Settings: change these numbers!
local HIDE_DEPTH = 12 -- how far below the floor the steps hide
local STEP_DELAY = 0.15 -- seconds between each step rising
local STAY_TIME = 10 -- seconds before the stairs sink again

local model = script.Parent
local button = model:WaitForChild("Button")
local steps = {}
for _, step in ipairs(model:WaitForChild("Steps"):GetChildren()) do
	if step:IsA("BasePart") and tonumber(step.Name) then
		table.insert(steps, { part = step, up = step.CFrame })
		step.Anchored = true
		step.CFrame = step.CFrame - Vector3.new(0, HIDE_DEPTH, 0)
	end
end
table.sort(steps, function(a, b)
	return tonumber(a.part.Name) < tonumber(b.part.Name)
end)

local function moveAll(goingUp)
	for _, step in ipairs(steps) do
		local goal = goingUp and step.up or step.up - Vector3.new(0, HIDE_DEPTH, 0)
		TweenService:Create(step.part, TweenInfo.new(0.5, Enum.EasingStyle.Back), { CFrame = goal }):Play()
		task.wait(STEP_DELAY)
	end
end

local busy = false
button.Touched:Connect(function(hit)
	if busy or not Players:GetPlayerFromCharacter(hit.Parent) then
		return
	end
	busy = true
	button.Color = Color3.fromRGB(0, 200, 0)
	moveAll(true)
	task.wait(STAY_TIME)
	moveAll(false)
	button.Color = Color3.fromRGB(200, 0, 0)
	busy = false
end)
