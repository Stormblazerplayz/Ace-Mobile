-- @title Pay coins to open a door
-- @category Doors and buttons
-- @kind Script
-- @where Put this Script inside the Anchored door Part (needs a Coins stat in leaderstats).
-- @keywords pay to enter, coin door, buy access door, toll door, unlock area with coins
-- @about Press E to pay coins once and unlock the door for yourself; after that you can walk through any time.

local Players = game:GetService("Players")

-- Settings: change these!
local PRICE = 100
local AREA_NAME = "Secret Area"

local door = script.Parent
door.Anchored = true
local paid = {} -- players who already paid this server

local prompt = Instance.new("ProximityPrompt")
prompt.ActionText = "Unlock (" .. PRICE .. " coins)"
prompt.ObjectText = AREA_NAME
prompt.Parent = door

local function passThrough(root)
	local side = door.CFrame:PointToObjectSpace(root.Position).Z
	local distance = door.Size.Z / 2 + 3
	local target = door.CFrame * CFrame.new(0, 0, side > 0 and -distance or distance)
	root.Parent:PivotTo(CFrame.new(target.Position) * root.CFrame.Rotation)
end

prompt.Triggered:Connect(function(player)
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	if not root then
		return
	end
	if not paid[player] then
		local stats = player:FindFirstChild("leaderstats")
		local coins = stats and stats:FindFirstChild("Coins")
		if not coins or coins.Value < PRICE then
			player:SetAttribute("Notice", "You need " .. PRICE .. " coins")
			return
		end
		coins.Value -= PRICE
		paid[player] = true
	end
	passThrough(root) -- paid players just press E to go through
end)

Players.PlayerRemoving:Connect(function(player)
	paid[player] = nil
end)
