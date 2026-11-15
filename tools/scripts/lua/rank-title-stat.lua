-- @title Rank title on the leaderboard
-- @category Leaderboards
-- @kind Script
-- @where Put this Script in ServerScriptService. It reads a leaderstats value (Wins by default) and shows a title for it.
-- @keywords rank title, noob to legend, player rank name, title stat, rank up names
-- @about Shows a Rank title like Noob, Pro or Legend in the player list, which goes up as your Wins go up.

local Players = game:GetService("Players")

-- Settings: change these! (lowest first)
local STAT_NAME = "Wins"
local RANKS = {
	{ need = 0, title = "Noob" },
	{ need = 5, title = "Rookie" },
	{ need = 20, title = "Pro" },
	{ need = 50, title = "Expert" },
	{ need = 100, title = "Legend" },
}

local function titleFor(amount)
	local title = RANKS[1].title
	for _, rank in ipairs(RANKS) do
		if amount >= rank.need then
			title = rank.title
		end
	end
	return title
end

Players.PlayerAdded:Connect(function(player)
	local leaderstats = player:WaitForChild("leaderstats")
	local stat = leaderstats:WaitForChild(STAT_NAME)
	local rank = Instance.new("StringValue")
	rank.Name = "Rank"
	rank.Parent = leaderstats

	local function update()
		local newTitle = titleFor(stat.Value)
		if rank.Value ~= "" and rank.Value ~= newTitle then
			player:SetAttribute("Notice", "Rank up! You are now " .. newTitle)
		end
		rank.Value = newTitle
	end
	stat.Changed:Connect(update)
	update()
end)
