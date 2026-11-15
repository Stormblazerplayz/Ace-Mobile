-- @title Admin ranks (module)
-- @category Chat and admin
-- @kind ModuleScript
-- @where Put this ModuleScript in ServerScriptService and name it Ranks. Other scripts use require(game.ServerScriptService.Ranks).IsAtLeast(player, "Mod").
-- @keywords admin ranks, permission levels, moderator rank, owner rank, group rank admin
-- @about One place to decide who is Owner, Admin, Mod or Player (by UserId or group rank), so every admin script agrees.

local Ranks = {}

-- Settings: change these!
local LEVELS = { Player = 0, Mod = 1, Admin = 2, Owner = 3 }
local BY_USER_ID = {
	-- [123456789] = "Admin",
}
local GROUP_ID = 0 -- your group's id, or 0 for none
local BY_GROUP_RANK = {
	-- group rank number (1 to 255) at or above which you get this level
	{ minRank = 250, level = "Admin" },
	{ minRank = 100, level = "Mod" },
}

local cache = {}

-- GetRank(player) returns "Owner", "Admin", "Mod" or "Player"
function Ranks.GetRank(player)
	if cache[player] then
		return cache[player]
	end
	local rank = "Player"
	if player.UserId == game.CreatorId then
		rank = "Owner"
	elseif BY_USER_ID[player.UserId] then
		rank = BY_USER_ID[player.UserId]
	elseif GROUP_ID ~= 0 then
		local ok, groupRank = pcall(function()
			return player:GetRankInGroup(GROUP_ID)
		end)
		if ok then
			for _, rule in ipairs(BY_GROUP_RANK) do
				if groupRank >= rule.minRank then
					rank = rule.level
					break
				end
			end
		end
	end
	cache[player] = rank
	player.AncestryChanged:Once(function()
		cache[player] = nil -- forget them when they leave
	end)
	return rank
end

-- IsAtLeast(player, "Mod") is true for Mods, Admins and the Owner
function Ranks.IsAtLeast(player, levelName)
	return LEVELS[Ranks.GetRank(player)] >= (LEVELS[levelName] or math.huge)
end

return Ranks
