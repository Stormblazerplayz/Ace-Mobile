-- @title Glass bridge (pick the right panel)
-- @category Obstacles
-- @kind Script
-- @where Put this Script in ServerScriptService, then make a Folder named GlassBridge in Workspace with one Folder per row, each holding two Anchored glass Parts side by side.
-- @keywords glass bridge, pick the right glass, fake glass panel, guess the safe tile, glass stepping stones
-- @about In every row one glass panel is real and one is fake and shatters when you step on it.

local Players = game:GetService("Players")

-- Settings: change these numbers!
local RESHUFFLE_EVERY = 60 -- seconds before the safe panels are picked again
local BROKEN_TIME = 3 -- seconds a broken panel stays gone

local bridge = workspace:WaitForChild("GlassBridge")
local fake = {} -- part -> true if it is a fake panel

local function shuffle()
	table.clear(fake)
	for _, row in ipairs(bridge:GetChildren()) do
		local panels = {}
		for _, part in ipairs(row:GetChildren()) do
			if part:IsA("BasePart") then
				table.insert(panels, part)
			end
		end
		if #panels >= 2 then
			-- Pick one panel at random to be the safe one, the rest are fake
			local safeIndex = math.random(1, #panels)
			for i, panel in ipairs(panels) do
				fake[panel] = i ~= safeIndex
			end
		end
	end
end

local function setupPanel(panel)
	panel.Material = Enum.Material.Glass
	panel.Transparency = 0.4
	panel.Touched:Connect(function(hit)
		if not fake[panel] or not panel.CanCollide then
			return
		end
		if not Players:GetPlayerFromCharacter(hit.Parent) then
			return
		end
		-- Shatter!
		panel.CanCollide = false
		panel.Transparency = 1
		task.wait(BROKEN_TIME)
		panel.CanCollide = true
		panel.Transparency = 0.4
	end)
end

for _, part in ipairs(bridge:GetDescendants()) do
	if part:IsA("BasePart") then
		setupPanel(part)
	end
end

while true do
	shuffle()
	task.wait(RESHUFFLE_EVERY)
end
