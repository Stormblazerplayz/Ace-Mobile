-- @title Click to get stronger (simulator tool)
-- @category Pickups and money
-- @kind Script
-- @where Put this Script inside a Tool (with a Handle part, like a dumbbell) in StarterPack.
-- @keywords click to gain, simulator clicking, lift weights, strength simulator, tap to get stronger
-- @about Every click with the tool adds Strength to the leaderboard, boosted by rebirths and upgrades.

local Players = game:GetService("Players")

-- Settings: change these numbers!
local BASE_GAIN = 1
local COOLDOWN = 0.3 -- seconds between clicks (stops auto clickers being too fast)

local tool = script.Parent
local lastClick = {}

local function getStat(player, name)
	local stats = player:FindFirstChild("leaderstats")
	if not stats then
		stats = Instance.new("Folder")
		stats.Name = "leaderstats"
		stats.Parent = player
	end
	local stat = stats:FindFirstChild(name)
	if not stat then
		stat = Instance.new("IntValue")
		stat.Name = name
		stat.Parent = stats
	end
	return stat
end

-- Activated runs on the server when the player clicks while holding the tool
tool.Activated:Connect(function()
	local player = Players:GetPlayerFromCharacter(tool.Parent)
	if not player then
		return
	end
	local now = os.clock()
	if now - (lastClick[player] or 0) < COOLDOWN then
		return
	end
	lastClick[player] = now

	local stats = player:FindFirstChild("leaderstats")
	local rebirths = stats and stats:FindFirstChild("Rebirths")
	local multiplier = (1 + (rebirths and rebirths.Value or 0)) * (player:GetAttribute("Multiplier") or 1)
	local strength = getStat(player, "Strength")
	strength.Value = strength.Value + BASE_GAIN * multiplier
end)
