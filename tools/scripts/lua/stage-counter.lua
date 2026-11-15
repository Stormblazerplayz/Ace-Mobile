-- @title Obby stage counter
-- @category Obstacles
-- @kind Script
-- @where Put this Script in ServerScriptService, and make a Folder named Checkpoints in Workspace with parts inside named 1, 2, 3 and so on (works great with the Checkpoints script).
-- @keywords stage counter, show my stage, stage on leaderboard, what stage am i on, obby stages
-- @about Shows each player's obby stage on the leaderboard and raises it when they reach a new stage.

local Players = game:GetService("Players")

-- Settings: set to true so players can't skip stages
local ONLY_NEXT_STAGE = false

local checkpoints = workspace:WaitForChild("Checkpoints")

-- Make the Stage number on the leaderboard
local function onPlayerAdded(player)
	local leaderstats = player:FindFirstChild("leaderstats")
	if not leaderstats then
		leaderstats = Instance.new("Folder")
		leaderstats.Name = "leaderstats" -- must be lowercase like this!
		leaderstats.Parent = player
	end
	local stage = Instance.new("IntValue")
	stage.Name = "Stage"
	stage.Value = 0
	stage.Parent = leaderstats
end

Players.PlayerAdded:Connect(onPlayerAdded)
for _, player in ipairs(Players:GetPlayers()) do
	onPlayerAdded(player)
end

-- Touching a stage part raises your Stage number
local function setupStage(part)
	if not part:IsA("BasePart") then
		return
	end
	part.Touched:Connect(function(hit)
		local player = Players:GetPlayerFromCharacter(hit.Parent)
		local number = tonumber(part.Name)
		local leaderstats = player and player:FindFirstChild("leaderstats")
		local stage = leaderstats and leaderstats:FindFirstChild("Stage")
		if not stage or not number then
			return
		end
		if ONLY_NEXT_STAGE then
			if number == stage.Value + 1 then
				stage.Value = number
			end
		elseif number > stage.Value then
			stage.Value = number
		end
	end)
end

for _, part in ipairs(checkpoints:GetChildren()) do
	setupStage(part)
end
checkpoints.ChildAdded:Connect(setupStage)
