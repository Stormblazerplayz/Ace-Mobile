-- @title Tycoon claim door
-- @category Pickups and money
-- @kind Script
-- @where Put this Script inside your tycoon Model, and add a Part named ClaimDoor to the Model.
-- @keywords claim tycoon, tycoon owner, tycoon door, own a base, tycoon entrance
-- @about The first player to touch the door owns the tycoon; it frees up again when they leave the game.

local Players = game:GetService("Players")

local tycoon = script.Parent
local door = tycoon:WaitForChild("ClaimDoor")

-- Other tycoon scripts read these two values
local owner = tycoon:FindFirstChild("Owner") or Instance.new("ObjectValue")
owner.Name = "Owner"
owner.Parent = tycoon
local bank = tycoon:FindFirstChild("Bank") or Instance.new("IntValue")
bank.Name = "Bank" -- money waiting to be collected
bank.Parent = tycoon

-- A sign above the door
local sign = Instance.new("BillboardGui")
sign.Size = UDim2.fromOffset(220, 50)
sign.StudsOffset = Vector3.new(0, door.Size.Y / 2 + 2, 0)
sign.Parent = door
local label = Instance.new("TextLabel")
label.Size = UDim2.fromScale(1, 1)
label.BackgroundTransparency = 1
label.TextScaled = true
label.Font = Enum.Font.GothamBold
label.TextColor3 = Color3.new(1, 1, 1)
label.TextStrokeTransparency = 0.3
label.Text = "Touch to claim!"
label.Parent = sign

door.Touched:Connect(function(hit)
	local player = Players:GetPlayerFromCharacter(hit.Parent)
	if not player or owner.Value ~= nil or player:GetAttribute("OwnsTycoon") then
		return -- already owned, or this player has a tycoon already
	end
	owner.Value = player
	player:SetAttribute("OwnsTycoon", true)
	label.Text = player.DisplayName .. "'s Tycoon"
	door.Transparency = 0.8
	door.CanCollide = false
end)

Players.PlayerRemoving:Connect(function(player)
	if owner.Value == player then
		owner.Value = nil
		bank.Value = 0
		label.Text = "Touch to claim!"
		door.Transparency = 0
		door.CanCollide = true
	end
end)
