-- @title Color floor minigame
-- @category Game rounds
-- @kind Script
-- @where Put this Script inside a Model or Folder full of anchored floor tiles (Parts), with something deadly (like a kill brick) below them.
-- @keywords color floor, stand on the color, color tiles, color block game, block party
-- @about Paints the floor tiles random colors, calls out one color, then makes every other tile vanish so players must stand on the right color.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Settings: change these!
local COLORS = {
	Red = Color3.fromRGB(230, 60, 60),
	Blue = Color3.fromRGB(60, 120, 240),
	Green = Color3.fromRGB(70, 200, 90),
	Yellow = Color3.fromRGB(250, 220, 60),
}
local START_TIME = 5 -- seconds to find the color at first
local MIN_TIME = 1.5 -- it gets faster each turn down to this

local tiles = {}
for _, part in ipairs(script.Parent:GetDescendants()) do
	if part:IsA("BasePart") then
		table.insert(tiles, part)
	end
end
local names = {}
for name in pairs(COLORS) do
	table.insert(names, name)
end

local status = ReplicatedStorage:FindFirstChild("Status") or Instance.new("StringValue")
status.Name = "Status"
status.Parent = ReplicatedStorage

local waitTime = START_TIME
while true do
	-- Paint every tile and make them all solid
	for _, tile in ipairs(tiles) do
		local name = names[math.random(1, #names)]
		tile.Color = COLORS[name]
		tile:SetAttribute("ColorName", name)
		tile.Transparency = 0
		tile.CanCollide = true
	end
	local target = names[math.random(1, #names)]
	status.Value = "Stand on " .. target .. "!"
	task.wait(waitTime)
	-- Every tile that is not the target color disappears
	for _, tile in ipairs(tiles) do
		if tile:GetAttribute("ColorName") ~= target then
			tile.Transparency = 1
			tile.CanCollide = false
		end
	end
	task.wait(3)
	waitTime = math.max(MIN_TIME, waitTime - 0.5)
	if waitTime == MIN_TIME then
		waitTime = START_TIME -- start the speed over again
	end
end
