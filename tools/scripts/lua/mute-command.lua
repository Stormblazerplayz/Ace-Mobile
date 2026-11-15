-- @title Mute command
-- @category Chat and admin
-- @kind Script
-- @where Put this Script in ServerScriptService and add admin UserIds to ADMINS (the owner always counts).
-- @keywords mute command, stop chatting, silence player, unmute, chat mute
-- @about Admins can type /mute Name to stop a player from sending chat messages, and /unmute Name to let them talk again.

local Players = game:GetService("Players")
local TextChatService = game:GetService("TextChatService")

local ADMINS = {}
local muted = {} -- muted[userId] = true

local function isAdmin(player)
	return player.UserId == game.CreatorId or table.find(ADMINS, player.UserId) ~= nil
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

-- Every chat channel has a TextSource for each player; CanSend decides if they can talk
local function applyMute(userId)
	for _, channel in ipairs(TextChatService:GetDescendants()) do
		if channel:IsA("TextChannel") then
			for _, source in ipairs(channel:GetChildren()) do
				if source:IsA("TextSource") and source.UserId == userId then
					source.CanSend = not muted[userId]
				end
			end
		end
	end
end

-- New channels or sources (like rejoining) keep the mute
TextChatService.DescendantAdded:Connect(function(object)
	if object:IsA("TextSource") and muted[object.UserId] then
		object.CanSend = false
	end
end)

local function makeCommand(alias, muteIt)
	local command = Instance.new("TextChatCommand")
	command.PrimaryAlias = alias
	command.Parent = TextChatService
	command.Triggered:Connect(function(textSource, message)
		local admin = Players:GetPlayerByUserId(textSource.UserId)
		if not admin or not isAdmin(admin) then
			return
		end
		local target = findPlayer(string.split(message, " ")[2])
		if target then
			muted[target.UserId] = muteIt or nil
			applyMute(target.UserId)
			admin:SetAttribute("Notice", (muteIt and "Muted " or "Unmuted ") .. target.Name)
			target:SetAttribute("Notice", muteIt and "You were muted" or "You can chat again")
		end
	end)
end
makeCommand("/mute", true)
makeCommand("/unmute", false)
