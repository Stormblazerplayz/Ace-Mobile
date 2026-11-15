-- @title Overhead name tag with title
-- @category Players
-- @kind Script
-- @where Put this Script in ServerScriptService.
-- @keywords name tag, overhead title, rank above head, billboard name, custom nametag
-- @about Puts a custom name tag above every player's head with their name and a title like Owner, VIP or Player.

local Players = game:GetService("Players")

-- Settings: give special titles to user ids (anyone else gets DEFAULT_TITLE)
local TITLES = {
	[1] = { text = "Owner", color = Color3.fromRGB(255, 200, 0) },
}
local DEFAULT_TITLE = { text = "Player", color = Color3.fromRGB(200, 200, 200) }

local function makeLabel(parent, text, color, y, height)
	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Size = UDim2.new(1, 0, height, 0)
	label.Position = UDim2.new(0, 0, y, 0)
	label.Text = text
	label.TextColor3 = color
	label.TextStrokeTransparency = 0.5
	label.TextScaled = true
	label.Font = Enum.Font.GothamBold
	label.Parent = parent
end

local function onCharacterAdded(player, character)
	local head = character:WaitForChild("Head")
	local humanoid = character:WaitForChild("Humanoid")
	humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None -- hide the normal name

	local title = TITLES[player.UserId] or DEFAULT_TITLE
	local tag = Instance.new("BillboardGui")
	tag.Name = "NameTag"
	tag.Size = UDim2.fromOffset(200, 50)
	tag.StudsOffset = Vector3.new(0, 2.5, 0)
	tag.MaxDistance = 80
	tag.Adornee = head
	makeLabel(tag, player.DisplayName, Color3.new(1, 1, 1), 0, 0.6)
	makeLabel(tag, title.text, title.color, 0.6, 0.4)
	tag.Parent = head
end

Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(function(character)
		onCharacterAdded(player, character)
	end)
end)
