-- @title Upgrade old save files
-- @category Saving data
-- @kind ModuleScript
-- @where Put this ModuleScript in ServerScriptService and name it Migrate. In your loading code: data = require(game.ServerScriptService.Migrate)(data).
-- @keywords data migration, save version, upgrade old data, change save format, data versioning
-- @about When you change how your game saves, this upgrades old players' saves step by step so nobody loses their stuff.

-- Every save table gets a Version number. When you change your save format,
-- add one more step below and raise LATEST by 1.
local LATEST = 3

local steps = {}

-- Version 1 to 2: we renamed "Money" to "Coins"
steps[1] = function(data)
	data.Coins = data.Money or 0
	data.Money = nil
	return data
end

-- Version 2 to 3: we added a Gems stat and a list of owned items
steps[2] = function(data)
	data.Gems = data.Gems or 0
	data.Owned = data.Owned or {}
	return data
end

return function(data)
	if type(data) ~= "table" then
		-- A brand new player, or a really old save that was just a number
		local oldCoins = type(data) == "number" and data or 0
		data = { Version = 1, Money = oldCoins }
	end
	data.Version = data.Version or 1
	-- Run each step in order until the save is up to date
	while data.Version < LATEST do
		local step = steps[data.Version]
		if not step then
			warn("No migration step for version " .. data.Version)
			break
		end
		data = step(data)
		data.Version += 1
	end
	return data
end
