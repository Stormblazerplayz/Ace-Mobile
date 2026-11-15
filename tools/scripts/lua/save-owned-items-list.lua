-- @title Save things a player owns
-- @category Saving data
-- @kind Script
-- @where Put this Script in ServerScriptService. Other server scripts give items with a BindableEvent in ServerStorage named GiveItem: GiveItem:Fire(player, "RedHat").
-- @keywords owned items, unlocked items, save purchases, item ownership, owned skins list
-- @about Keeps a saved list of every item each player has unlocked (skins, trails, hats) so they never have to buy them twice.

local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local ServerStorage = game:GetService("ServerStorage")

local store = DataStoreService:GetDataStore("OwnedItems_v1")
local giveItem = ServerStorage:FindFirstChild("GiveItem") or Instance.new("BindableEvent")
giveItem.Name = "GiveItem"
giveItem.Parent = ServerStorage

local owned = {} -- owned[player] = { RedHat = true, ... }

-- Each owned item also shows up as a BoolValue in player.OwnedItems, so GUIs can read it
local function showItem(player, itemName)
	local folder = player:FindFirstChild("OwnedItems")
	if folder and not folder:FindFirstChild(itemName) then
		local flag = Instance.new("BoolValue")
		flag.Name = itemName
		flag.Value = true
		flag.Parent = folder
	end
end

Players.PlayerAdded:Connect(function(player)
	local folder = Instance.new("Folder")
	folder.Name = "OwnedItems"
	folder.Parent = player
	local ok, saved = pcall(function()
		return store:GetAsync("Player_" .. player.UserId)
	end)
	if not ok then
		warn("Could not load items for " .. player.Name)
		return
	end
	owned[player] = {}
	for _, itemName in ipairs(type(saved) == "table" and saved or {}) do
		owned[player][itemName] = true
		showItem(player, itemName)
	end
end)

giveItem.Event:Connect(function(player, itemName)
	if owned[player] and type(itemName) == "string" then
		owned[player][itemName] = true
		showItem(player, itemName)
	end
end)

local function save(player)
	local list = owned[player]
	if not list then
		return
	end
	local names = {}
	for itemName in pairs(list) do
		table.insert(names, itemName)
	end
	pcall(function()
		store:SetAsync("Player_" .. player.UserId, names)
	end)
end

Players.PlayerRemoving:Connect(function(player)
	save(player)
	owned[player] = nil
end)
game:BindToClose(function()
	for _, player in ipairs(Players:GetPlayers()) do
		task.spawn(save, player)
	end
	task.wait(3)
end)
