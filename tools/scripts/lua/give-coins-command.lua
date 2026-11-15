-- @title Give coins command
-- @category Chat and admin
-- @kind Script
-- @where Put this Script in ServerScriptService and add admin UserIds to ADMINS (the owner always counts). Players need a leaderstats Coins value.
-- @keywords give coins command, admin money, add coins command, give stat, cash command
-- @about Admins type /givecoins Name 100 to give a player coins (handy for testing your shop), or /givecoins all 50 for everyone.

local Players = game:GetService("Players")
local TextChatService = game:GetService("TextChatService")

-- Settings: change these!
local ADMINS = {}
local STAT_NAME = "Coins"
local MAX_AMOUNT = 1000000

local function isAdmin(player)
	return player.UserId == game.CreatorId or table.find(ADMINS, player.UserId) ~= nil
end

local function targetsFor(text)
	text = string.lower(text or "")
	if text == "all" then
		return Players:GetPlayers()
	end
	for _, player in ipairs(Players:GetPlayers()) do
		if text ~= "" and string.sub(string.lower(player.Name), 1, #text) == text then
			return { player }
		end
	end
	return {}
end

local command = Instance.new("TextChatCommand")
command.PrimaryAlias = "/givecoins"
command.Parent = TextChatService

command.Triggered:Connect(function(textSource, message)
	local admin = Players:GetPlayerByUserId(textSource.UserId)
	if not admin or not isAdmin(admin) then
		return
	end
	local words = string.split(message, " ")
	local amount = math.floor(tonumber(words[3]) or 0)
	if amount == 0 or math.abs(amount) > MAX_AMOUNT then
		admin:SetAttribute("Notice", "Try: /givecoins Name 100")
		return
	end
	for _, target in ipairs(targetsFor(words[2])) do
		local stats = target:FindFirstChild("leaderstats")
		local stat = stats and stats:FindFirstChild(STAT_NAME)
		if stat then
			stat.Value = math.max(0, stat.Value + amount) -- negative numbers take coins away
			target:SetAttribute("Notice", "An admin gave you " .. amount .. " " .. STAT_NAME)
		end
	end
end)
