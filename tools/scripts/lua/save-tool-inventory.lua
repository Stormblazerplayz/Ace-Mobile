-- @title Save the tools you own
-- @category Saving data
-- @kind Script
-- @where Put this Script in ServerScriptService and keep a copy of every saveable Tool in a Folder named SavedTools in ServerStorage.
-- @keywords save tools, save inventory, keep my items, backpack saving, tools after rejoin
-- @about Remembers which tools each player had and gives them back when they rejoin and after every respawn.

local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local ServerStorage = game:GetService("ServerStorage")

local store = DataStoreService:GetDataStore("ToolInventory_v1")
local toolFolder = ServerStorage:WaitForChild("SavedTools")
local loaded = {}

-- Collect the names of tools in the backpack, hands and StarterGear
local function toolNames(player)
	local names = {}
	for _, holder in ipairs({ player:FindFirstChild("StarterGear"), player:FindFirstChildOfClass("Backpack"), player.Character }) do
		if holder then
			for _, tool in ipairs(holder:GetChildren()) do
				if tool:IsA("Tool") and toolFolder:FindFirstChild(tool.Name) and not table.find(names, tool.Name) then
					table.insert(names, tool.Name)
				end
			end
		end
	end
	return names
end

Players.PlayerAdded:Connect(function(player)
	local ok, names = pcall(function()
		return store:GetAsync("Player_" .. player.UserId)
	end)
	if not ok then
		warn("Could not load tools for " .. player.Name)
		return
	end
	local gear = player:WaitForChild("StarterGear")
	for _, name in ipairs(type(names) == "table" and names or {}) do
		local template = toolFolder:FindFirstChild(name)
		if template then
			-- StarterGear tools are copied into the backpack on every respawn
			template:Clone().Parent = gear
			local backpack = player:FindFirstChildOfClass("Backpack")
			if backpack then
				template:Clone().Parent = backpack
			end
		end
	end
	loaded[player] = true
end)

local function save(player)
	if not loaded[player] then
		return
	end
	local names = toolNames(player)
	pcall(function()
		store:SetAsync("Player_" .. player.UserId, names)
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
