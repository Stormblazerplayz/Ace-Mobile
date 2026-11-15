-- @title Try saving again if it fails (module)
-- @category Saving data
-- @kind ModuleScript
-- @where Put this ModuleScript in ServerScriptService and name it SafeStore. Use require(game.ServerScriptService.SafeStore).Get(store, key) and .Update(store, key, function).
-- @keywords datastore retry, retry saving, safe datastore, try again on error, datastore pcall helper
-- @about Wraps DataStore calls so that if Roblox's servers have a hiccup, it waits and tries again a few times before giving up.

local SafeStore = {}

-- Settings: change these!
local TRIES = 4
local FIRST_WAIT = 1 -- seconds; doubles after each failed try (1, 2, 4...)

local function retry(action)
	local waitTime = FIRST_WAIT
	local lastError
	for attempt = 1, TRIES do
		local ok, result = pcall(action)
		if ok then
			return true, result
		end
		lastError = result
		warn("DataStore try " .. attempt .. " failed: " .. tostring(result))
		if attempt < TRIES then
			task.wait(waitTime)
			waitTime *= 2
		end
	end
	return false, lastError
end

-- Get: returns ok, value
function SafeStore.Get(store, key)
	return retry(function()
		return store:GetAsync(key)
	end)
end

-- Update: transform gets the old value and returns the new one
function SafeStore.Update(store, key, transform)
	return retry(function()
		return store:UpdateAsync(key, transform)
	end)
end

-- Set: overwrite with a new value
function SafeStore.Set(store, key, value)
	return retry(function()
		return store:SetAsync(key, value)
	end)
end

return SafeStore
