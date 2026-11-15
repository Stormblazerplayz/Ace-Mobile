-- @title Press all the buttons puzzle
-- @category Doors and buttons
-- @kind Script
-- @where Put this Script inside a Model with an Anchored Part named Door and a Folder named Buttons holding the button Parts.
-- @keywords button puzzle, press all buttons, team puzzle, find every button, multi button door
-- @about Every button must be stepped on before time runs out; then the door opens. Great for team puzzles.

local Players = game:GetService("Players")

-- Settings: change these numbers!
local TIME_LIMIT = 20 -- seconds from the first button to press them all
local OPEN_TIME = 10

local model = script.Parent
local door = model:WaitForChild("Door")
local buttons = {}
for _, part in ipairs(model:WaitForChild("Buttons"):GetChildren()) do
	if part:IsA("BasePart") then
		table.insert(buttons, part)
		part.Color = Color3.fromRGB(200, 40, 40)
	end
end

local pressed = {}
local count = 0
local firstPress = 0
local solved = false

local function reset()
	table.clear(pressed)
	count = 0
	for _, button in ipairs(buttons) do
		button.Color = Color3.fromRGB(200, 40, 40)
	end
end

for _, button in ipairs(buttons) do
	button.Touched:Connect(function(hit)
		if solved or pressed[button] or not Players:GetPlayerFromCharacter(hit.Parent) then
			return
		end
		if count == 0 then
			firstPress = os.clock()
			task.delay(TIME_LIMIT, function()
				if not solved and firstPress ~= 0 and os.clock() - firstPress >= TIME_LIMIT then
					reset() -- too slow, start over
				end
			end)
		end
		pressed[button] = true
		count += 1
		button.Color = Color3.fromRGB(40, 200, 40)

		if count == #buttons then
			solved = true
			door.Transparency = 1
			door.CanCollide = false
			task.wait(OPEN_TIME)
			door.Transparency = 0
			door.CanCollide = true
			firstPress = 0
			reset()
			solved = false
		end
	end)
end
