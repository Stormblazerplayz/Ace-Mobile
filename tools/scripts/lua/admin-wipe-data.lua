-- @title Reset a player's save (admin)
-- @category Saving data
-- @kind Script
-- @where Put this Script in ServerScriptService, put your own UserId in ADMINS, and set STORE_NAMES to the DataStore names your game uses.
-- @keywords wipe data, reset save, delete player data, admin reset, clear datastore
-- @about Lets an admin type "/wipe PlayerName" in chat to delete that player's saved data (useful for testing or removing cheated stats).

local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local TextChatService = game:GetService("TextChatService")

-- Settings: change these!
local ADMINS = { 123456789 } -- your UserId (find it in your Roblox profile link)
local STORE_NAMES = { "PlayerCoins_v1", "PlayerProfile_v1" }

local function findPlayer(text)
	text = string.lower(text)
	for _, player in ipairs(Players:GetPlayers()) do
		if string.sub(string.lower(player.Name), 1, #text) == text then
			return player
		end
	end
	return nil
end

local function wipe(admin, target)
	local key = "Player_" .. target.UserId
	for _, storeName in ipairs(STORE_NAMES) do
		local ok, err = pcall(function()
			DataStoreService:GetDataStore(storeName):RemoveAsync(key)
		end)
		if not ok then
			admin:SetAttribute("Notice", "Wipe failed in " .. storeName .. ": " .. tostring(err))
			return
		end
	end
	-- Kick them so their old numbers are not saved again when they leave
	target:Kick("Your data was reset by an admin. Please rejoin!")
	admin:SetAttribute("Notice", "Wiped " .. target.Name)
end

-- A chat command: typing "/wipe Name" in chat runs this on the server
local command = Instance.new("TextChatCommand")
command.Name = "WipeCommand"
command.PrimaryAlias = "/wipe"
command.Parent = TextChatService

command.Triggered:Connect(function(textSource, message)
	local admin = Players:GetPlayerByUserId(textSource.UserId)
	if not admin or not table.find(ADMINS, admin.UserId) then
		return -- only admins!
	end
	local name = string.match(message, "^/wipe%s+(%S+)")
	if not name then
		return
	end
	local target = findPlayer(name)
	if target then
		wipe(admin, target)
	else
		admin:SetAttribute("Notice", "No player called " .. name)
	end
end)
