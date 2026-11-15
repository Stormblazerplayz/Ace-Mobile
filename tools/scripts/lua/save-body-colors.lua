-- @title Keep your body paint
-- @category Saving data
-- @kind Script
-- @where Put this Script in ServerScriptService. Works with the Paint your body pad script or anything that changes BodyColors.
-- @keywords save body colors, keep paint color, avatar color saving, remember skin color, colors after respawn
-- @about Remembers the body colors a player painted themselves and puts them back after respawning and when they rejoin.

local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")

local store = DataStoreService:GetDataStore("BodyColors_v1")
local PARTS = { "HeadColor3", "TorsoColor3", "LeftArmColor3", "RightArmColor3", "LeftLegColor3", "RightLegColor3" }
local saved = {} -- saved[player] = { HeadColor3 = {r, g, b}, ... }
local changed = {}

local function apply(player, character)
	local colors = saved[player]
	if not colors then
		return
	end
	local bodyColors = character:WaitForChild("BodyColors", 5) or Instance.new("BodyColors")
	for _, prop in ipairs(PARTS) do
		local c = colors[prop]
		if c then
			bodyColors[prop] = Color3.fromRGB(c[1], c[2], c[3])
		end
	end
	bodyColors.Parent = character
end

local function watch(player, character)
	apply(player, character)
	local bodyColors = character:WaitForChild("BodyColors", 5)
	if not bodyColors then
		return
	end
	bodyColors.Changed:Connect(function()
		local colors = {}
		for _, prop in ipairs(PARTS) do
			local c = bodyColors[prop]
			colors[prop] = { math.floor(c.R * 255), math.floor(c.G * 255), math.floor(c.B * 255) }
		end
		saved[player] = colors
		changed[player] = true
	end)
end

Players.PlayerAdded:Connect(function(player)
	local ok, data = pcall(function()
		return store:GetAsync("Player_" .. player.UserId)
	end)
	if ok and type(data) == "table" then
		saved[player] = data
	end
	-- CharacterAppearanceLoaded waits until the avatar's own colors are on, so ours go on top
	player.CharacterAppearanceLoaded:Connect(function(character)
		watch(player, character)
	end)
	if player.Character then
		watch(player, player.Character)
	end
end)

local function save(player)
	if changed[player] and saved[player] then
		pcall(function()
			store:SetAsync("Player_" .. player.UserId, saved[player])
		end)
	end
end

Players.PlayerRemoving:Connect(function(player)
	save(player)
	saved[player], changed[player] = nil, nil
end)
game:BindToClose(function()
	for _, player in ipairs(Players:GetPlayers()) do
		task.spawn(save, player)
	end
	task.wait(3)
end)
