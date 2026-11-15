-- @title Wait for enough players (module)
-- @category Game rounds
-- @kind ModuleScript
-- @where Put this ModuleScript in ServerScriptService and name it WaitForPlayers. In a round script: require(game.ServerScriptService.WaitForPlayers)(2).
-- @keywords minimum players, waiting for players, need more players, player count check, enough players
-- @about Pauses your round script until enough players are in the server, showing "Waiting for players (1/2)" in the Status text.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local status = ReplicatedStorage:FindFirstChild("Status") or Instance.new("StringValue")
status.Name = "Status"
status.Parent = ReplicatedStorage

-- Call it with how many players you need. It returns when there are enough.
-- In Studio's Play Solo there is only you, so it lets 1 player through when STUDIO_TEST is true.
local STUDIO_TEST = true

return function(minimum)
	minimum = minimum or 2
	if STUDIO_TEST and game:GetService("RunService"):IsStudio() then
		minimum = 1
	end
	while #Players:GetPlayers() < minimum do
		status.Value = "Waiting for players (" .. #Players:GetPlayers() .. "/" .. minimum .. ")"
		-- Wake up as soon as someone joins, or check again after 5 seconds
		local joined = false
		local connection = Players.PlayerAdded:Connect(function()
			joined = true
		end)
		local waited = 0
		while not joined and waited < 5 do
			task.wait(0.25)
			waited += 0.25
		end
		connection:Disconnect()
	end
	return Players:GetPlayers()
end
