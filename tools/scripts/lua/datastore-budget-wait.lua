-- @title Wait for DataStore budget (module)
-- @category Saving data
-- @kind ModuleScript
-- @where Put this ModuleScript in ServerScriptService and name it Budget. Before a save call: require(game.ServerScriptService.Budget).WaitFor("Set").
-- @keywords datastore budget, request limit, throttle saving, too many requests, request budget
-- @about Checks how many DataStore requests Roblox lets your server make right now, and waits a moment if you are about to go over the limit.

local DataStoreService = game:GetService("DataStoreService")

local Budget = {}

-- The kinds of request you can wait for
local KINDS = {
	Get = Enum.DataStoreRequestType.GetAsync,
	Set = Enum.DataStoreRequestType.SetIncrementAsync,
	Update = Enum.DataStoreRequestType.UpdateAsync,
	Sorted = Enum.DataStoreRequestType.GetSortedAsync,
}

-- WaitFor("Set") returns when there is room for at least one more request of that kind.
-- It gives up after maxWait seconds (default 10) so a script never waits forever.
function Budget.WaitFor(kind, maxWait)
	local requestType = KINDS[kind] or KINDS.Set
	maxWait = maxWait or 10
	local waited = 0
	while DataStoreService:GetRequestBudgetForRequestType(requestType) < 1 do
		if waited >= maxWait then
			warn("DataStore budget still empty after " .. maxWait .. " seconds")
			return false
		end
		task.wait(0.5)
		waited += 0.5
	end
	return true
end

-- How many requests of that kind you can make right now
function Budget.Left(kind)
	return DataStoreService:GetRequestBudgetForRequestType(KINDS[kind] or KINDS.Set)
end

return Budget
