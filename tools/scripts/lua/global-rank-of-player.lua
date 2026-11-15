-- @title Tell players their global rank
-- @category Leaderboards
-- @kind Script
-- @where Put this Script in ServerScriptService. It reads the same board the Global top 10 board script saves to (Wins by default). Use the Notification toasts GUI to show the message.
-- @keywords global rank, my rank, what place am i, leaderboard position, top 100 check
-- @about When a player joins, it checks the top 100 of the global board and tells them their place, like "You are #37 in the world!"

local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")

-- Settings: change these!
local STAT_NAME = "Wins"
local CHECK_TOP = 100 -- how far down the list to look (bigger costs more requests)

local store = DataStoreService:GetOrderedDataStore("Global" .. STAT_NAME .. "_v1")

local function findRank(userId)
	local ok, pages = pcall(function()
		return store:GetSortedAsync(false, 100) -- 100 entries per page
	end)
	if not ok then
		return nil
	end
	local rank = 0
	while rank < CHECK_TOP do
		for _, entry in ipairs(pages:GetCurrentPage()) do
			rank += 1
			if tonumber(entry.key) == userId then
				return rank
			end
		end
		if pages.IsFinished or rank >= CHECK_TOP then
			break
		end
		local nextOk = pcall(function()
			pages:AdvanceToNextPageAsync()
		end)
		if not nextOk then
			break
		end
	end
	return nil
end

Players.PlayerAdded:Connect(function(player)
	task.wait(8) -- let other scripts load their data and show welcome messages first
	if not player.Parent then
		return
	end
	local rank = findRank(player.UserId)
	if rank then
		player:SetAttribute("Notice", "You are #" .. rank .. " in the world for " .. STAT_NAME .. "!")
	else
		player:SetAttribute("Notice", "Get more " .. STAT_NAME .. " to reach the top " .. CHECK_TOP .. "!")
	end
end)
