-- @title Roll a dice command
-- @category Chat and admin
-- @kind Script
-- @where Put this Script in ServerScriptService.
-- @keywords dice roll, random number command, roll command, roll d6, chance game
-- @about Type /roll to roll a dice (or /roll 20 for a 20-sided one); the result pops up over your head for everyone to see.

local Players = game:GetService("Players")
local TextChatService = game:GetService("TextChatService")
local Debris = game:GetService("Debris")

local lastRoll = {}

local command = Instance.new("TextChatCommand")
command.PrimaryAlias = "/roll"
command.Parent = TextChatService

command.Triggered:Connect(function(textSource, message)
	local player = Players:GetPlayerByUserId(textSource.UserId)
	local head = player and player.Character and player.Character:FindFirstChild("Head")
	if not head or os.clock() - (lastRoll[player] or 0) < 2 then
		return
	end
	lastRoll[player] = os.clock()
	-- How many sides? Default 6, between 2 and 100
	local sides = math.clamp(math.floor(tonumber(string.split(message, " ")[2]) or 6), 2, 100)
	local result = math.random(1, sides) -- the server rolls, so nobody can cheat

	local billboard = Instance.new("BillboardGui")
	billboard.Size = UDim2.fromOffset(160, 50)
	billboard.StudsOffset = Vector3.new(0, 3, 0)
	billboard.Parent = head
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundColor3 = Color3.new(1, 1, 1)
	label.Font = Enum.Font.GothamBlack
	label.TextScaled = true
	label.Text = "Rolled " .. result .. " / " .. sides
	label.Parent = billboard
	Debris:AddItem(billboard, 4)
end)

Players.PlayerRemoving:Connect(function(player)
	lastRoll[player] = nil
end)
