-- @title Admin chat commands
-- @category Chat and admin
-- @kind Script
-- @where Put this Script in ServerScriptService and add your friends' UserIds to ADMINS (the game's owner is always an admin).
-- @keywords admin commands, chat commands, kill command, heal command, teleport to player command
-- @about Gives admins chat commands: /heal, /kill, /speed and /goto, each followed by a player's name (or "me").

local Players = game:GetService("Players")
local TextChatService = game:GetService("TextChatService")

-- Settings: extra admins by UserId
local ADMINS = {}

local function isAdmin(player)
	return player.UserId == game.CreatorId or table.find(ADMINS, player.UserId) ~= nil
end

-- "me" means yourself; otherwise the first player whose name starts with the text
local function findPlayer(speaker, text)
	if not text or text == "" or string.lower(text) == "me" then
		return speaker
	end
	text = string.lower(text)
	for _, player in ipairs(Players:GetPlayers()) do
		if string.sub(string.lower(player.Name), 1, #text) == text or string.sub(string.lower(player.DisplayName), 1, #text) == text then
			return player
		end
	end
	return nil
end

local function humanoidOf(player)
	return player.Character and player.Character:FindFirstChildOfClass("Humanoid")
end

-- Each command: what it does to the target player
local COMMANDS = {
	heal = function(admin, target)
		local humanoid = humanoidOf(target)
		if humanoid then
			humanoid.Health = humanoid.MaxHealth
		end
	end,
	kill = function(admin, target)
		local humanoid = humanoidOf(target)
		if humanoid then
			humanoid.Health = 0
		end
	end,
	speed = function(admin, target, number)
		local humanoid = humanoidOf(target)
		if humanoid then
			humanoid.WalkSpeed = math.clamp(tonumber(number) or 16, 0, 200)
		end
	end,
	["goto"] = function(admin, target)
		local theirRoot = target.Character and target.Character:FindFirstChild("HumanoidRootPart")
		if theirRoot and admin.Character then
			admin.Character:PivotTo(theirRoot.CFrame * CFrame.new(0, 0, 4))
		end
	end,
}

for name, action in pairs(COMMANDS) do
	-- A TextChatCommand catches messages that start with its alias
	local command = Instance.new("TextChatCommand")
	command.Name = "Admin_" .. name
	command.PrimaryAlias = "/" .. name
	command.Parent = TextChatService
	command.Triggered:Connect(function(textSource, message)
		local admin = Players:GetPlayerByUserId(textSource.UserId)
		if not admin or not isAdmin(admin) then
			return
		end
		local words = string.split(message, " ")
		local target = findPlayer(admin, words[2])
		if target then
			action(admin, target, words[3])
			admin:SetAttribute("Notice", "/" .. name .. " used on " .. target.Name)
		else
			admin:SetAttribute("Notice", "No player found")
		end
	end)
end
