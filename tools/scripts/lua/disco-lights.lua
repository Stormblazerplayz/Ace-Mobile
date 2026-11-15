-- @title Disco party lights
-- @category World and effects
-- @kind Script
-- @where Put this Script inside a Model or Folder of Parts (dance floor tiles, light bulbs or SpotLights).
-- @keywords disco lights, party lights, dance floor, club lights, flashing colors, light show
-- @about Every beat, all the parts and lights in the folder jump to new random party colors.

-- Settings: change these numbers!
local BEATS_PER_MINUTE = 120
local COLORS = {
	Color3.fromRGB(255, 50, 80),
	Color3.fromRGB(255, 200, 40),
	Color3.fromRGB(60, 255, 120),
	Color3.fromRGB(40, 160, 255),
	Color3.fromRGB(200, 60, 255),
}

local holder = script.Parent
local secondsPerBeat = 60 / BEATS_PER_MINUTE

while true do
	for _, thing in ipairs(holder:GetDescendants()) do
		local color = COLORS[math.random(#COLORS)]
		if thing:IsA("BasePart") then
			thing.Color = color
			thing.Material = Enum.Material.Neon
		elseif thing:IsA("Light") then
			thing.Color = color
		end
	end
	task.wait(secondsPerBeat)
end
