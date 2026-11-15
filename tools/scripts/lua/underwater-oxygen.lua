-- @title Run out of air underwater
-- @category Players
-- @kind Script
-- @where Put this Script in ServerScriptService (it works with Terrain water).
-- @keywords oxygen, drowning, air underwater, hold your breath, underwater air meter
-- @about Players have limited air when their head is under Terrain water and start losing health when it runs out.

local Players = game:GetService("Players")

-- Settings: change these numbers!
local MAX_AIR = 15 -- seconds of air
local DROWN_DAMAGE = 10 -- health lost each second with no air

local terrain = workspace.Terrain

-- Is this spot inside Terrain water?
local function isInWater(position)
	local region = Region3.new(position - Vector3.new(2, 2, 2), position + Vector3.new(2, 2, 2)):ExpandToGrid(4)
	local materials = terrain:ReadVoxels(region, 4)
	return materials[1][1][1] == Enum.Material.Water
end

Players.PlayerAdded:Connect(function(player)
	player:SetAttribute("Air", MAX_AIR)
end)

while true do
	task.wait(1)
	for _, player in ipairs(Players:GetPlayers()) do
		local character = player.Character
		local head = character and character:FindFirstChild("Head")
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		if head and humanoid and humanoid.Health > 0 then
			local air = player:GetAttribute("Air") or MAX_AIR
			if isInWater(head.Position) then
				air = math.max(air - 1, 0)
				if air == 0 then
					humanoid:TakeDamage(DROWN_DAMAGE)
				end
			else
				air = math.min(air + 3, MAX_AIR) -- breathe again quickly
			end
			-- A GUI can read the "Air" attribute to show bubbles
			player:SetAttribute("Air", air)
		end
	end
end
