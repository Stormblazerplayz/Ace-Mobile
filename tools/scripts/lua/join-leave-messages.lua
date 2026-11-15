-- @title Joined and left messages
-- @category Chat and admin
-- @kind LocalScript
-- @where Put this LocalScript in StarterPlayer > StarterPlayerScripts.
-- @keywords join message, leave message, player joined chat, player left chat, system message
-- @about Shows a gray message in the chat whenever a player joins or leaves the server.

local Players = game:GetService("Players")
local TextChatService = game:GetService("TextChatService")

local general = TextChatService:WaitForChild("TextChannels"):WaitForChild("RBXGeneral")

local function system(text, color)
	-- DisplaySystemMessage shows text in the chat that nobody "said"
	general:DisplaySystemMessage(string.format("<font color='%s'>%s</font>", color, text))
end

Players.PlayerAdded:Connect(function(player)
	system(player.DisplayName .. " joined the game", "#9BE89B")
end)

Players.PlayerRemoving:Connect(function(player)
	if player ~= Players.LocalPlayer then
		system(player.DisplayName .. " left the game", "#E89B9B")
	end
end)
