-- @title Ban command
-- @category Chat and admin
-- @kind Script
-- @where Put this Script in ServerScriptService and add admin UserIds to ADMINS (the game's owner is always an admin).
-- @keywords ban command, ban player, kick command, remove rule breaker, ban api
-- @about Admins can type /ban Name to ban a player from your game, or /kick Name to only remove them from this server.

local Players = game:GetService("Players")
local TextChatService = game:GetService("TextChatService")

-- Settings: change these!
local ADMINS = {}
local BAN_DAYS = 7 -- how long a ban lasts (use -1 for forever)

local function isAdmin(player)
	return player.UserId == game.CreatorId or table.find(ADMINS, player.UserId) ~= nil
end

local function findPlayer(text)
	text = string.lower(text or "")
	if text == "" then
		return nil
	end
	for _, player in ipairs(Players:GetPlayers()) do
		if string.sub(string.lower(player.Name), 1, #text) == text then
			return player
		end
	end
	return nil
end

local function makeCommand(alias, action)
	local command = Instance.new("TextChatCommand")
	command.PrimaryAlias = alias
	command.Parent = TextChatService
	command.Triggered:Connect(function(textSource, message)
		local admin = Players:GetPlayerByUserId(textSource.UserId)
		if not admin or not isAdmin(admin) then
			return
		end
		local target = findPlayer(string.split(message, " ")[2])
		if not target or isAdmin(target) then
			admin:SetAttribute("Notice", "Can't do that to them")
			return
		end
		action(admin, target)
	end)
end

makeCommand("/kick", function(admin, target)
	target:Kick("You were kicked by an admin.")
	admin:SetAttribute("Notice", "Kicked " .. target.Name)
end)

makeCommand("/ban", function(admin, target)
	-- BanAsync bans them from every server of your game
	local ok, err = pcall(function()
		Players:BanAsync({
			UserIds = { target.UserId },
			ApplyToUniverse = true,
			Duration = BAN_DAYS < 0 and -1 or BAN_DAYS * 24 * 60 * 60,
			DisplayReason = "You broke the game's rules.",
			PrivateReason = "Banned by " .. admin.Name,
			ExcludeAltAccounts = false,
		})
	end)
	admin:SetAttribute("Notice", ok and ("Banned " .. target.Name) or ("Ban failed: " .. tostring(err)))
end)
