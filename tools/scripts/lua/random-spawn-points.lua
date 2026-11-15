-- @title Spawn at a random spot
-- @category Players
-- @kind Script
-- @where Put this Script in ServerScriptService, then make a Folder named SpawnPoints in Workspace with invisible Anchored Parts where players can appear.
-- @keywords random spawn, spawn points, spawn in random place, scatter players, random spawn location
-- @about Every time a player spawns they appear at a random spot from your SpawnPoints folder.

local Players = game:GetService("Players")

local spawnPoints = workspace:WaitForChild("SpawnPoints")

local function pickSpot()
	local spots = {}
	for _, part in ipairs(spawnPoints:GetChildren()) do
		if part:IsA("BasePart") then
			table.insert(spots, part)
		end
	end
	if #spots == 0 then
		return nil
	end
	return spots[math.random(#spots)]
end

local function onCharacterAdded(character)
	character:WaitForChild("HumanoidRootPart")
	task.wait() -- wait one frame so Roblox finishes placing the character
	local spot = pickSpot()
	if spot then
		-- Stand on top of the spot part
		character:PivotTo(spot.CFrame + Vector3.new(0, spot.Size.Y / 2 + 3, 0))
	end
end

Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(onCharacterAdded)
end)
