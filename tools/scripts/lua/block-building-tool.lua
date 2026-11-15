-- @title Block building tool
-- @category Tools and combat
-- @kind Script
-- @where Put this Script inside a Tool with a Handle part, add the Tool aiming (client part) LocalScript to the same Tool, and put the Tool in StarterPack.
-- @keywords building tool, place blocks, build blocks, grid building, block placer, minecraft building
-- @about Click to place blocks that snap to a grid; the server checks you are close enough and limits how many blocks each player can build.

local Players = game:GetService("Players")

-- Settings: change these!
local GRID = 4 -- block size and grid size in studs
local REACH = 40 -- how far away you can build
local MAX_BLOCKS = 200 -- per player
local COOLDOWN = 0.15

local tool = script.Parent
local clickPosition = Instance.new("RemoteEvent")
clickPosition.Name = "ClickPosition"
clickPosition.Parent = tool

local buildFolder = workspace:FindFirstChild("PlayerBuilds") or Instance.new("Folder")
buildFolder.Name = "PlayerBuilds"
buildFolder.Parent = workspace
local lastPlace = 0

-- Round a position to the nearest grid spot
local function snap(position)
	local function r(n)
		return math.floor(n / GRID + 0.5) * GRID
	end
	return Vector3.new(r(position.X), r(position.Y), r(position.Z))
end

clickPosition.OnServerEvent:Connect(function(player, target)
	local character = tool.Parent
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if Players:GetPlayerFromCharacter(character) ~= player or typeof(target) ~= "Vector3" or not root then
		return
	end
	if os.clock() - lastPlace < COOLDOWN or (target - root.Position).Magnitude > REACH then
		return
	end
	lastPlace = os.clock()

	-- Each player's blocks go in their own folder so we can count them
	local myFolder = buildFolder:FindFirstChild(tostring(player.UserId))
	if not myFolder then
		myFolder = Instance.new("Folder")
		myFolder.Name = tostring(player.UserId)
		myFolder.Parent = buildFolder
	end
	if #myFolder:GetChildren() >= MAX_BLOCKS then
		player:SetAttribute("Notice", "Block limit reached!")
		return
	end

	-- Nudge the click point back toward the player so the block sits ON the surface, not inside it
	local towardPlayer = (root.Position - target).Unit * (GRID / 2)
	local position = snap(target + towardPlayer)
	-- Do not place a block inside another block or inside a player
	if #workspace:GetPartBoundsInBox(CFrame.new(position), Vector3.new(GRID, GRID, GRID) * 0.9) > 0 then
		return
	end
	local block = Instance.new("Part")
	block.Size = Vector3.new(GRID, GRID, GRID)
	block.Position = position
	block.Anchored = true
	block.Material = Enum.Material.SmoothPlastic
	block.Color = player.TeamColor.Color
	block.Parent = myFolder
end)

-- Clean up a player's blocks when they leave
Players.PlayerRemoving:Connect(function(player)
	local myFolder = buildFolder:FindFirstChild(tostring(player.UserId))
	if myFolder then
		myFolder:Destroy()
	end
end)
