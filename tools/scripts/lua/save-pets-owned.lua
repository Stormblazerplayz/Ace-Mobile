-- @title Save hatched pets
-- @category Saving data
-- @kind Script
-- @where Put this Script in ServerScriptService. It saves the OwnedPets folder and EquippedPet attribute used by the Egg hatching and Pet follow scripts.
-- @keywords save pets, pet inventory saving, keep my pets, equipped pet saved, pet datastore
-- @about Saves every pet a player has hatched and which one they have equipped, and gives them back next time.

local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")

local store = DataStoreService:GetDataStore("OwnedPets_v1")
local loaded = {}

Players.PlayerAdded:Connect(function(player)
	local folder = player:FindFirstChild("OwnedPets") or Instance.new("Folder")
	folder.Name = "OwnedPets"
	folder.Parent = player
	local ok, saved = pcall(function()
		return store:GetAsync("Player_" .. player.UserId)
	end)
	if not ok then
		warn("Could not load pets for " .. player.Name)
		return
	end
	if type(saved) == "table" then
		for _, petName in ipairs(saved.Pets or {}) do
			local entry = Instance.new("StringValue")
			entry.Name = petName
			entry.Value = petName
			entry.Parent = folder
		end
		if saved.Equipped then
			player:SetAttribute("EquippedPet", saved.Equipped)
		end
	end
	loaded[player] = true
end)

local function save(player)
	if not loaded[player] then
		return
	end
	local pets = {}
	local folder = player:FindFirstChild("OwnedPets")
	for _, entry in ipairs(folder and folder:GetChildren() or {}) do
		table.insert(pets, entry.Name)
	end
	local data = { Pets = pets, Equipped = player:GetAttribute("EquippedPet") }
	pcall(function()
		store:SetAsync("Player_" .. player.UserId, data)
	end)
end

Players.PlayerRemoving:Connect(function(player)
	save(player)
	loaded[player] = nil
end)
game:BindToClose(function()
	for _, player in ipairs(Players:GetPlayers()) do
		task.spawn(save, player)
	end
	task.wait(3)
end)
