-- @title Save obby stage
-- @category Saving data
-- @kind Script
-- @where Put this Script in ServerScriptService. Use it with the Stage counter script and numbered SpawnLocations in a Folder named Checkpoints.
-- @keywords save stage, obby progress saving, continue obby, stage datastore, keep my stage
-- @about Saves the highest obby stage each player reached, and when they rejoin it sets their Stage and spawns them at that checkpoint.

local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")

local store = DataStoreService:GetDataStore("ObbyStage_v1")
local checkpoints = workspace:WaitForChild("Checkpoints")
local loaded = {}

Players.PlayerAdded:Connect(function(player)
	local ok, savedStage = pcall(function()
		return store:GetAsync("Player_" .. player.UserId)
	end)
	if not ok then
		return
	end
	local stage = player:WaitForChild("leaderstats"):WaitForChild("Stage")
	if type(savedStage) == "number" and savedStage > stage.Value then
		stage.Value = savedStage
		local checkpoint = checkpoints:FindFirstChild(tostring(savedStage))
		if checkpoint and checkpoint:IsA("SpawnLocation") then
			player.RespawnLocation = checkpoint
			-- Move them now if they already spawned at the start
			local character = player.Character
			if character then
				character:PivotTo(checkpoint.CFrame + Vector3.new(0, 4, 0))
			end
		end
	end
	loaded[player] = true
end)

local function save(player)
	local stats = player:FindFirstChild("leaderstats")
	local stage = stats and stats:FindFirstChild("Stage")
	if loaded[player] and stage then
		pcall(function()
			-- UpdateAsync keeps whichever number is higher
			store:UpdateAsync("Player_" .. player.UserId, function(old)
				return math.max(old or 0, stage.Value)
			end)
		end)
	end
end

Players.PlayerRemoving:Connect(function(player)
	save(player)
	loaded[player] = nil
end)
game:BindToClose(function()
	for _, player in ipairs(Players:GetPlayers()) do
		task.spawn(save, player)
	end
	task.wait(3)
end)
