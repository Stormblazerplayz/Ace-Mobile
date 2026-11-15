-- @title Send scores to a global board (module)
-- @category Leaderboards
-- @kind ModuleScript
-- @where Put this ModuleScript in ServerScriptService and name it BoardWriter. Use require(game.ServerScriptService.BoardWriter).Submit("Wins", player, 25).
-- @keywords submit score, ordered store writer, save high score, leaderboard module, best score only
-- @about Saves a player's score to a global board, keeping only their best score, and waits politely so DataStore limits are not hit.

local DataStoreService = game:GetService("DataStoreService")

local BoardWriter = {}

local stores = {}
local queue = {} -- waiting saves: queue["Wins|12345"] = {board, userId, score}

local function storeFor(boardName)
	if not stores[boardName] then
		stores[boardName] = DataStoreService:GetOrderedDataStore("Global" .. boardName .. "_v1")
	end
	return stores[boardName]
end

-- Submit(boardName, player, score, lowerIsBetter)
-- lowerIsBetter = true for things like fastest times
function BoardWriter.Submit(boardName, player, score, lowerIsBetter)
	score = math.floor(score)
	local key = boardName .. "|" .. player.UserId
	local waiting = queue[key]
	-- If there is already a better score waiting, keep that one
	if waiting and ((lowerIsBetter and waiting.score <= score) or (not lowerIsBetter and waiting.score >= score)) then
		return
	end
	queue[key] = { board = boardName, userId = player.UserId, score = score, lower = lowerIsBetter }
end

-- Every 30 seconds, write the waiting scores one at a time
task.spawn(function()
	while true do
		task.wait(30)
		for key, item in pairs(queue) do
			queue[key] = nil
			pcall(function()
				storeFor(item.board):UpdateAsync(tostring(item.userId), function(old)
					if old and ((item.lower and old <= item.score) or (not item.lower and old >= item.score)) then
						return nil -- the saved score is already better
					end
					return item.score
				end)
			end)
			task.wait(1) -- small gap between saves
		end
	end
end)

return BoardWriter
