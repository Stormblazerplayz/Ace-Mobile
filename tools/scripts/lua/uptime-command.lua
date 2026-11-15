-- @title How long the server has been up
-- @category Chat and admin
-- @kind Script
-- @where Put this Script in ServerScriptService. Use it with the Notification toasts GUI so players see the answer.
-- @keywords uptime command, server age, how long server running, server time, old server check
-- @about Anyone can type /uptime to see how long this server has been running and how many players are in it.

local Players = game:GetService("Players")
local TextChatService = game:GetService("TextChatService")

local startedAt = os.time() -- when this server started

local function formatTime(seconds)
	local hours = math.floor(seconds / 3600)
	local minutes = math.floor(seconds % 3600 / 60)
	local secs = seconds % 60
	if hours > 0 then
		return string.format("%dh %dm", hours, minutes)
	end
	return string.format("%dm %ds", minutes, secs)
end

local command = Instance.new("TextChatCommand")
command.PrimaryAlias = "/uptime"
command.Parent = TextChatService

command.Triggered:Connect(function(textSource)
	local player = Players:GetPlayerByUserId(textSource.UserId)
	if player then
		local up = formatTime(os.time() - startedAt)
		player:SetAttribute("Notice", "Server up for " .. up .. " with " .. #Players:GetPlayers() .. " players")
	end
end)
