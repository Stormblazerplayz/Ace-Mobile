-- @title Win pad
-- @category Game rounds
-- @kind Script
-- @where Put this Script inside the finish Part at the end of your obby or race, and add a Part named Lobby in Workspace if you want winners sent back there.
-- @keywords win pad, finish line, give a win, wins leaderboard, you win part, end of the obby
-- @about Touching the finish gives the player a Win on the leaderboard and sends them back to the lobby.

local Players = game:GetService("Players")

-- Settings: change these!
local LOBBY_NAME = "Lobby" -- winners get sent to a part with this name (if it exists)
local COOLDOWN = 5 -- seconds before the same player can win again

local pad = script.Parent
local recent = {} -- players who just won

pad.Touched:Connect(function(hit)
	local character = hit.Parent
	local player = Players:GetPlayerFromCharacter(character)
	if not player or recent[player] then
		return
	end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid or humanoid.Health <= 0 then
		return
	end
	recent[player] = true

	-- Find (or make) the Wins number on the leaderboard
	local leaderstats = player:FindFirstChild("leaderstats")
	if not leaderstats then
		leaderstats = Instance.new("Folder")
		leaderstats.Name = "leaderstats"
		leaderstats.Parent = player
	end
	local wins = leaderstats:FindFirstChild("Wins")
	if not wins then
		wins = Instance.new("IntValue")
		wins.Name = "Wins"
		wins.Parent = leaderstats
	end
	wins.Value = wins.Value + 1

	-- Send the winner back to the lobby
	local lobby = workspace:FindFirstChild(LOBBY_NAME)
	if lobby and lobby:IsA("BasePart") then
		character:PivotTo(CFrame.new(lobby.Position + Vector3.new(0, lobby.Size.Y / 2 + 3, 0)))
	end

	task.delay(COOLDOWN, function()
		recent[player] = nil
	end)
end)
