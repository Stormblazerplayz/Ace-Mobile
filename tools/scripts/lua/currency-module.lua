-- @title Money helper (module)
-- @category Pickups and money
-- @kind ModuleScript
-- @where Put this ModuleScript in ServerScriptService and name it Currency, then require it from your server Scripts.
-- @keywords currency module, add coins function, spend coins safely, money api, give money helper
-- @about Gives your server scripts simple add, spend and get functions for any leaderstats money, so you never write that code twice.

--[[ How to use it from a server Script:
	local Currency = require(game.ServerScriptService.Currency)
	Currency.add(player, "Coins", 50)
	if Currency.spend(player, "Coins", 100) then
		print("Bought it!")
	end
	print(Currency.get(player, "Gems"))
]]

local Currency = {}

-- Finds (or makes) the stat in the player's leaderstats
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

function Currency.get(player, name)
	return getStat(player, name).Value
end

function Currency.add(player, name, amount)
	if type(amount) ~= "number" or amount ~= amount then
		return -- not a real number (amount ~= amount catches NaN)
	end
	local stat = getStat(player, name)
	stat.Value = stat.Value + math.floor(amount)
end

-- Takes money only if they have enough. Returns true if it worked.
function Currency.spend(player, name, amount)
	if type(amount) ~= "number" or amount < 0 then
		return false
	end
	local stat = getStat(player, name)
	if stat.Value < amount then
		return false
	end
	stat.Value = stat.Value - amount
	return true
end

return Currency
