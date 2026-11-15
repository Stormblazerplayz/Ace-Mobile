-- @title Announce command
-- @category Chat and admin
-- @kind Script
-- @where Put this Script in ServerScriptService. Use it with the Announcement banner GUI script so players see the message.
-- @keywords announce command, server announcement, admin message, broadcast command, shout to everyone
-- @about Admins type /announce followed by a message, and a big banner with that message slides onto everyone's screen.

local Players = game:GetService("Players")
local TextChatService = game:GetService("TextChatService")
local TextService = game:GetService("TextService")

-- Settings: extra admins by UserId (the owner always counts)
local ADMINS = {}

local function isAdmin(player)
	return player.UserId == game.CreatorId or table.find(ADMINS, player.UserId) ~= nil
end

local command = Instance.new("TextChatCommand")
command.PrimaryAlias = "/announce"
command.Parent = TextChatService

command.Triggered:Connect(function(textSource, message)
	local admin = Players:GetPlayerByUserId(textSource.UserId)
	if not admin or not isAdmin(admin) then
		return
	end
	local text = string.sub(message, #"/announce " + 1)
	if text == "" then
		return
	end
	-- Roblox requires filtering text that other players will see
	local ok, filtered = pcall(function()
		local result = TextService:FilterStringAsync(text, admin.UserId)
		return result:GetNonChatStringForBroadcastAsync()
	end)
	if ok then
		workspace:SetAttribute("Announcement", "") -- clear first so the same text can show twice
		workspace:SetAttribute("Announcement", filtered)
	end
end)
