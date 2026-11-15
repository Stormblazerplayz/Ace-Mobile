-- @title Rebirth system (server)
-- @category Pickups and money
-- @kind Script
-- @where Put this Script in ServerScriptService (it makes a RemoteEvent named Rebirth; use the Rebirth button script for the GUI).
-- @keywords rebirth, rebirths, prestige, reset for a multiplier, rebirth system
-- @about Lets players trade in all their coins and strength for a Rebirth that makes them gain faster forever.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Settings: change these numbers!
local BASE_COST = 1000 -- coins needed for the first rebirth
local COST_GROWTH = 2 -- each rebirth costs this many times more

local rebirthEvent = ReplicatedStorage:FindFirstChild("Rebirth") or Instance.new("RemoteEvent")
rebirthEvent.Name = "Rebirth"
rebirthEvent.Parent = ReplicatedStorage

local function costFor(rebirths)
	return math.floor(BASE_COST * COST_GROWTH ^ rebirths)
end

Players.PlayerAdded:Connect(function(player)
	local stats = player:FindFirstChild("leaderstats") or Instance.new("Folder")
	stats.Name = "leaderstats"
	stats.Parent = player
	local rebirths = Instance.new("IntValue")
	rebirths.Name = "Rebirths"
	rebirths.Parent = stats
	player:SetAttribute("RebirthCost", costFor(0)) -- the GUI shows this
	rebirths.Changed:Connect(function(value)
		player:SetAttribute("RebirthCost", costFor(value))
	end)
end)

rebirthEvent.OnServerEvent:Connect(function(player)
	local stats = player:FindFirstChild("leaderstats")
	local coins = stats and stats:FindFirstChild("Coins")
	local rebirths = stats and stats:FindFirstChild("Rebirths")
	if not coins or not rebirths then
		return
	end
	local cost = costFor(rebirths.Value)
	if coins.Value < cost then
		rebirthEvent:FireClient(player, false, "You need " .. cost .. " coins")
		return
	end
	-- Reset progress and add a rebirth
	coins.Value = 0
	local strength = stats:FindFirstChild("Strength")
	if strength then
		strength.Value = 0
	end
	rebirths.Value = rebirths.Value + 1
	rebirthEvent:FireClient(player, true, "Rebirth " .. rebirths.Value .. "!")
end)
