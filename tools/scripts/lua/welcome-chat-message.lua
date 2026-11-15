-- @title Welcome message in chat
-- @category Chat and admin
-- @kind LocalScript
-- @where Put this LocalScript in StarterPlayer > StarterPlayerScripts and change WELCOME_LINES.
-- @keywords welcome message, greet new player, chat welcome, first message, hello in chat
-- @about When you join, the chat greets you by name and shows a few lines about your game.

local Players = game:GetService("Players")
local TextChatService = game:GetService("TextChatService")

-- Settings: change these! {name} is replaced with the player's name
local WELCOME_LINES = {
	"Welcome, {name}! Thanks for playing!",
	"Collect coins and buy cool stuff in the shop.",
	"Type /help to see the chat commands.",
}

local player = Players.LocalPlayer
local general = TextChatService:WaitForChild("TextChannels"):WaitForChild("RBXGeneral")

task.wait(2) -- wait until the chat window is ready
for _, line in ipairs(WELCOME_LINES) do
	local text = string.gsub(line, "{name}", player.DisplayName)
	general:DisplaySystemMessage("<font color='#FFD966'>" .. text .. "</font>")
	task.wait(0.5)
end
