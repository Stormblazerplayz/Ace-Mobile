-- @title Rejoin where you left
-- @category Saving data
-- @kind Script
-- @where Put this Script in ServerScriptService.
-- @keywords save position, last location, rejoin same place, remember where i was, position saving
-- @about Saves where a player was standing when they left, and puts them back there the first time they spawn next visit.

local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")

local store = DataStoreService:GetDataStore("LastPosition_v1")
local lastPosition = {} -- updated while playing, because the character may be gone when they leave

Players.PlayerAdded:Connect(function(player)
	local ok, saved = pcall(function()
		return store:GetAsync("Player_" .. player.UserId)
	end)
	local character = player.Character or player.CharacterAdded:Wait()
	local root = character:WaitForChild("HumanoidRootPart")
	-- DataStores cannot save a Vector3, so we saved a table {x, y, z}
	if ok and type(saved) == "table" and saved[1] then
		task.wait(0.5) -- let the spawn finish first
		character:PivotTo(CFrame.new(saved[1], saved[2] + 3, saved[3]))
	end
	-- Keep track of the position while they play
	task.spawn(function()
		while player.Parent do
			local current = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
			local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
			if current and humanoid and humanoid.Health > 0 then
				local p = current.Position
				lastPosition[player] = { math.floor(p.X), math.floor(p.Y), math.floor(p.Z) }
			end
			task.wait(2)
		end
	end)
end)

local function save(player)
	local position = lastPosition[player]
	if position then
		pcall(function()
			store:SetAsync("Player_" .. player.UserId, position)
		end)
	end
end

Players.PlayerRemoving:Connect(function(player)
	save(player)
	lastPosition[player] = nil
end)
game:BindToClose(function()
	for _, player in ipairs(Players:GetPlayers()) do
		task.spawn(save, player)
	end
	task.wait(3)
end)
