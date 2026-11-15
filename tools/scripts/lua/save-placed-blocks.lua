-- @title Save blocks players build
-- @category Saving data
-- @kind Script
-- @where Put this Script in ServerScriptService. It saves blocks inside Workspace.PlayerBuilds.<UserId> (the Block building tool puts them there).
-- @keywords save builds, save placed blocks, building saves, keep my creations, plot saving
-- @about Saves the position and color of every block a player built and rebuilds them when the player comes back.

local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")

local store = DataStoreService:GetDataStore("PlacedBlocks_v1")
local buildFolder = workspace:FindFirstChild("PlayerBuilds") or Instance.new("Folder")
buildFolder.Name = "PlayerBuilds"
buildFolder.Parent = workspace

local MAX_SAVED = 200
local snapshot = {} -- the newest copy of each player's blocks, kept up to date
local loaded = {}

-- Turn a block into a small table: {x, y, z, r, g, b, sizeX, sizeY, sizeZ}
local function pack(part)
	local p, c, s = part.Position, part.Color, part.Size
	return { p.X, p.Y, p.Z, math.floor(c.R * 255), math.floor(c.G * 255), math.floor(c.B * 255), s.X, s.Y, s.Z }
end

local function updateSnapshot(player, folder)
	local list = {}
	for _, part in ipairs(folder:GetChildren()) do
		if part:IsA("BasePart") and #list < MAX_SAVED then
			table.insert(list, pack(part))
		end
	end
	snapshot[player] = list
end

Players.PlayerAdded:Connect(function(player)
	local folder = buildFolder:FindFirstChild(tostring(player.UserId)) or Instance.new("Folder")
	folder.Name = tostring(player.UserId)
	folder.Parent = buildFolder
	local ok, saved = pcall(function()
		return store:GetAsync("Player_" .. player.UserId)
	end)
	if not ok then
		return -- do not save over blocks we failed to load
	end
	for _, info in ipairs(type(saved) == "table" and saved or {}) do
		local block = Instance.new("Part")
		block.Anchored = true
		block.Material = Enum.Material.SmoothPlastic
		block.Position = Vector3.new(info[1], info[2], info[3])
		block.Color = Color3.fromRGB(info[4], info[5], info[6])
		block.Size = Vector3.new(info[7] or 4, info[8] or 4, info[9] or 4)
		block.Parent = folder
	end
	updateSnapshot(player, folder)
	loaded[player] = true
	folder.ChildAdded:Connect(function()
		updateSnapshot(player, folder)
	end)
	folder.ChildRemoved:Connect(function()
		updateSnapshot(player, folder)
	end)
end)

local function save(player)
	if loaded[player] and snapshot[player] then
		pcall(function()
			store:SetAsync("Player_" .. player.UserId, snapshot[player])
		end)
	end
end

Players.PlayerRemoving:Connect(function(player)
	save(player)
	loaded[player], snapshot[player] = nil, nil
end)
game:BindToClose(function()
	for _, player in ipairs(Players:GetPlayers()) do
		task.spawn(save, player)
	end
	task.wait(3)
end)
