-- @title Give round prizes (module)
-- @category Game rounds
-- @kind ModuleScript
-- @where Put this ModuleScript in ServerScriptService and name it RoundRewards. Round scripts use require(game.ServerScriptService.RoundRewards).Give(player, "Winner").
-- @keywords round rewards, winner prize, participation prize, reward module, give wins and coins
-- @about One place to set how many coins and wins each kind of round result gives, so all your round scripts reward players the same way.

local RoundRewards = {}

-- Settings: change these prizes!
RoundRewards.Prizes = {
	Winner = { Coins = 100, Wins = 1, Message = "You won! +100 coins" },
	Survivor = { Coins = 50, Wins = 0, Message = "You survived! +50 coins" },
	Played = { Coins = 10, Wins = 0, Message = "Thanks for playing! +10 coins" },
}

local function addStat(player, name, amount)
	local stats = player:FindFirstChild("leaderstats")
	local stat = stats and stats:FindFirstChild(name)
	if stat and amount > 0 then
		stat.Value += amount
	end
end

-- Give(player, kind) gives the prize for that kind (Winner, Survivor or Played)
function RoundRewards.Give(player, kind)
	local prize = RoundRewards.Prizes[kind]
	if not prize or not player.Parent then
		return
	end
	-- Gamepass or upgrade multipliers from other scripts can boost coins
	local multiplier = player:GetAttribute("Multiplier") or 1
	addStat(player, "Coins", math.floor(prize.Coins * multiplier))
	addStat(player, "Wins", prize.Wins)
	player:SetAttribute("Notice", prize.Message)
end

-- GiveAll(list, kind) rewards a whole list of players
function RoundRewards.GiveAll(players, kind)
	for _, player in ipairs(players) do
		RoundRewards.Give(player, kind)
	end
end

return RoundRewards
