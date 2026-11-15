-- @title Sign anyone can write on
-- @category Chat and admin
-- @kind Script
-- @where Put this Script inside a Part named MessageSign that has a SurfaceGui with a TextLabel on its front.
-- @keywords message sign, write on sign, player text sign, text filter, guestbook
-- @about Players type /sign followed by a message to write it on the sign; the text goes through Roblox's filter first so it is safe for everyone.

local Players = game:GetService("Players")
local TextChatService = game:GetService("TextChatService")
local TextService = game:GetService("TextService")

-- Settings: change these!
local COOLDOWN = 30 -- seconds before the same player can write again
local MAX_LENGTH = 80

local sign = script.Parent
local label = sign:FindFirstChildWhichIsA("TextLabel", true)
local lastWrite = {}

local command = Instance.new("TextChatCommand")
command.PrimaryAlias = "/sign"
command.Parent = TextChatService

command.Triggered:Connect(function(textSource, message)
	local player = Players:GetPlayerByUserId(textSource.UserId)
	if not player or not label then
		return
	end
	if os.clock() - (lastWrite[player] or -COOLDOWN) < COOLDOWN then
		player:SetAttribute("Notice", "Wait a bit before writing again")
		return
	end
	local text = string.sub(message, #"/sign " + 1, #"/sign " + MAX_LENGTH)
	if text == "" then
		return
	end
	-- Every text that other players will read MUST be filtered
	local ok, filtered = pcall(function()
		return TextService:FilterStringAsync(text, player.UserId):GetNonChatStringForBroadcastAsync()
	end)
	if ok then
		lastWrite[player] = os.clock()
		label.Text = player.DisplayName .. " wrote:\n" .. filtered
	else
		player:SetAttribute("Notice", "Could not check your text, try again")
	end
end)

Players.PlayerRemoving:Connect(function(player)
	lastWrite[player] = nil
end)
