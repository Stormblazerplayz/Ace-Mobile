-- @title Private server owner powers
-- @category Chat and admin
-- @kind Script
-- @where Put this Script in ServerScriptService. Only works in private (VIP) servers.
-- @keywords private server owner, vip server commands, server owner kick, lock server, private server admin
-- @about The owner of a private server can type /pkick Name to remove someone, and /lock or /unlock to stop new non-friends joining.

local Players = game:GetService("Players")
local TextChatService = game:GetService("TextChatService")

local isPrivate = game.PrivateServerId ~= "" and game.PrivateServerOwnerId ~= 0
local locked = false

local function isServerOwner(player)
	return isPrivate and player.UserId == game.PrivateServerOwnerId
end

local function findPlayer(text)
	text = string.lower(text or "")
	for _, player in ipairs(Players:GetPlayers()) do
		if text ~= "" and string.sub(string.lower(player.Name), 1, #text) == text then
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
		local owner = Players:GetPlayerByUserId(textSource.UserId)
		if owner and isServerOwner(owner) then
			action(owner, string.split(message, " ")[2])
		end
	end)
end

makeCommand("/pkick", function(owner, name)
	local target = findPlayer(name)
	if target and target ~= owner then
		target:Kick("The private server owner removed you.")
	end
end)
makeCommand("/lock", function(owner)
	locked = true
	owner:SetAttribute("Notice", "Server locked: only friends can join")
end)
makeCommand("/unlock", function(owner)
	locked = false
	owner:SetAttribute("Notice", "Server unlocked")
end)

-- While locked, only the owner's friends may join
Players.PlayerAdded:Connect(function(player)
	if not locked or isServerOwner(player) then
		return
	end
	local ok, isFriend = pcall(function()
		return player:IsFriendsWith(game.PrivateServerOwnerId)
	end)
	if not (ok and isFriend) then
		player:Kick("This private server is locked right now.")
	end
end)
