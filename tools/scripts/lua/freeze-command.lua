-- @title Freeze command
-- @category Chat and admin
-- @kind Script
-- @where Put this Script in ServerScriptService and add admin UserIds to ADMINS (the owner always counts).
-- @keywords freeze command, freeze player, ice block, stop player moving, unfreeze
-- @about Admins type /freeze Name to trap a player in a block of ice so they cannot move, and /thaw Name to let them go.

local Players = game:GetService("Players")
local TextChatService = game:GetService("TextChatService")

local ADMINS = {}

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

local function freeze(target, on)
	local character = target.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not root then
		return
	end
	local oldIce = character:FindFirstChild("AdminIce")
	if oldIce then
		oldIce:Destroy()
	end
	root.Anchored = on -- an anchored body cannot move at all
	if on then
		local ice = Instance.new("Part")
		ice.Name = "AdminIce"
		ice.Size = Vector3.new(5, 7, 5)
		ice.CFrame = root.CFrame
		ice.Anchored = true
		ice.CanCollide = false
		ice.Material = Enum.Material.Ice
		ice.Color = Color3.fromRGB(150, 210, 255)
		ice.Transparency = 0.4
		ice.Parent = character
	end
end

local function makeCommand(alias, on)
	local command = Instance.new("TextChatCommand")
	command.PrimaryAlias = alias
	command.Parent = TextChatService
	command.Triggered:Connect(function(textSource, message)
		local admin = Players:GetPlayerByUserId(textSource.UserId)
		if admin and isAdmin(admin) then
			local target = findPlayer(string.split(message, " ")[2])
			if target then
				freeze(target, on)
			end
		end
	end)
end
makeCommand("/freeze", true)
makeCommand("/thaw", false)
