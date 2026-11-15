-- @title Level gate door
-- @category Doors and buttons
-- @kind Script
-- @where Put this Script inside the Anchored door Part (needs a Level stat in leaderstats, like from the XP and levels script).
-- @keywords level door, level requirement, reach level to enter, locked zone, level gate, next world gate
-- @about Shows the level needed on the door and only lets players with a high enough Level through.

local Players = game:GetService("Players")

-- Settings: change these!
local LEVEL_NEEDED = 10
local STAT_NAME = "Level"

local door = script.Parent
door.Anchored = true
local cooldown = {}

-- Write the level on both sides of the door
for _, face in ipairs({ Enum.NormalId.Front, Enum.NormalId.Back }) do
	local gui = Instance.new("SurfaceGui")
	gui.Face = face
	gui.Parent = door
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.TextScaled = true
	label.Font = Enum.Font.GothamBlack
	label.TextColor3 = Color3.new(1, 1, 1)
	label.Text = "Level " .. LEVEL_NEEDED .. " needed"
	label.Parent = gui
end

local function passThrough(root)
	local side = door.CFrame:PointToObjectSpace(root.Position).Z
	local distance = door.Size.Z / 2 + 3
	local target = door.CFrame * CFrame.new(0, 0, side > 0 and -distance or distance)
	root.Parent:PivotTo(CFrame.new(target.Position) * root.CFrame.Rotation)
end

door.Touched:Connect(function(hit)
	local character = hit.Parent
	local player = Players:GetPlayerFromCharacter(character)
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not player or not root or cooldown[player] then
		return
	end
	local stats = player:FindFirstChild("leaderstats")
	local level = stats and stats:FindFirstChild(STAT_NAME)
	if level and level.Value >= LEVEL_NEEDED then
		cooldown[player] = true
		passThrough(root)
		task.wait(1)
		cooldown[player] = nil
	end
end)
