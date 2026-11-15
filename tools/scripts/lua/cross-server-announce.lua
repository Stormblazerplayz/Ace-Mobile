-- @title Announce to every server
-- @category Chat and admin
-- @kind Script
-- @where Put this Script in ServerScriptService. Use it with the Announcement banner GUI script. Only the game owner (and ADMINS) can use it.
-- @keywords global announcement, all servers message, messaging service, cross server, network wide message
-- @about The owner types /global followed by a message, and it shows as a banner in every running server of the game.

local Players = game:GetService("Players")
local MessagingService = game:GetService("MessagingService")
local TextChatService = game:GetService("TextChatService")
local TextService = game:GetService("TextService")

local ADMINS = {}
local TOPIC = "GlobalAnnouncement"

local function isAdmin(player)
	return player.UserId == game.CreatorId or table.find(ADMINS, player.UserId) ~= nil
end

-- Listen for messages from any server (including this one)
pcall(function()
	MessagingService:SubscribeAsync(TOPIC, function(packet)
		if type(packet.Data) == "string" then
			workspace:SetAttribute("Announcement", "")
			workspace:SetAttribute("Announcement", "[Global] " .. packet.Data)
		end
	end)
end)

local command = Instance.new("TextChatCommand")
command.PrimaryAlias = "/global"
command.Parent = TextChatService

command.Triggered:Connect(function(textSource, message)
	local admin = Players:GetPlayerByUserId(textSource.UserId)
	if not admin or not isAdmin(admin) then
		return
	end
	local text = string.sub(message, #"/global " + 1)
	if text == "" then
		return
	end
	local ok, err = pcall(function()
		local filtered = TextService:FilterStringAsync(text, admin.UserId):GetNonChatStringForBroadcastAsync()
		MessagingService:PublishAsync(TOPIC, filtered)
	end)
	admin:SetAttribute("Notice", ok and "Sent to all servers" or ("Failed: " .. tostring(err)))
end)
