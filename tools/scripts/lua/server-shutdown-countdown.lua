-- @title Shut down with a countdown
-- @category Chat and admin
-- @kind Script
-- @where Put this Script in ServerScriptService. Use it with the Announcement banner GUI. Only the owner and ADMINS can use it.
-- @keywords shutdown command, update server, restart countdown, close server, kick everyone
-- @about Admins type /shutdown to warn everyone with a 30 second countdown before the server closes (handy before an update).

local Players = game:GetService("Players")
local TextChatService = game:GetService("TextChatService")

-- Settings: change these!
local ADMINS = {}
local COUNTDOWN = 30

local function isAdmin(player)
	return player.UserId == game.CreatorId or table.find(ADMINS, player.UserId) ~= nil
end

local shuttingDown = false

-- Once shutting down, anyone who joins is sent away right away
Players.PlayerAdded:Connect(function(player)
	if shuttingDown then
		player:Kick("This server is closing. Please join another one!")
	end
end)

local command = Instance.new("TextChatCommand")
command.PrimaryAlias = "/shutdown"
command.Parent = TextChatService

command.Triggered:Connect(function(textSource)
	local admin = Players:GetPlayerByUserId(textSource.UserId)
	if not admin or not isAdmin(admin) or shuttingDown then
		return
	end
	shuttingDown = true
	for seconds = COUNTDOWN, 1, -1 do
		if seconds == COUNTDOWN or seconds % 10 == 0 or seconds <= 5 then
			workspace:SetAttribute("Announcement", "")
			workspace:SetAttribute("Announcement", "Server closing in " .. seconds .. " seconds!")
		end
		task.wait(1)
	end
	for _, player in ipairs(Players:GetPlayers()) do
		player:Kick("The server closed for an update. Please rejoin!")
	end
end)
