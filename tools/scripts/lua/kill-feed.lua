-- @title Kill feed
-- @category GUI
-- @kind LocalScript
-- @where Put this LocalScript in StarterPlayer > StarterPlayerScripts. Weapons must tag victims with a "creator" ObjectValue (the sword and gun scripts here do).
-- @keywords kill feed, knockout feed, elimination list, kill log, defeat messages
-- @about Shows "Player1 defeated Player2" messages in the top right corner that fade away after a few seconds.

local Players = game:GetService("Players")
local Debris = game:GetService("Debris")

local player = Players.LocalPlayer

local gui = Instance.new("ScreenGui")
gui.Name = "KillFeed"
gui.ResetOnSpawn = false
gui.Parent = player:WaitForChild("PlayerGui")

local holder = Instance.new("Frame")
holder.AnchorPoint = Vector2.new(1, 0)
holder.Position = UDim2.new(1, -10, 0, 80)
holder.Size = UDim2.fromOffset(300, 200)
holder.BackgroundTransparency = 1
holder.Parent = gui
local layout = Instance.new("UIListLayout")
layout.Padding = UDim.new(0, 4)
layout.HorizontalAlignment = Enum.HorizontalAlignment.Right
layout.Parent = holder

local function addLine(text)
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromOffset(300, 26)
	label.BackgroundColor3 = Color3.new(0, 0, 0)
	label.BackgroundTransparency = 0.5
	label.TextColor3 = Color3.new(1, 1, 1)
	label.Font = Enum.Font.GothamBold
	label.TextScaled = true
	label.Text = text
	label.Parent = holder
	Debris:AddItem(label, 6)
end

local function watchCharacter(victim, character)
	local humanoid = character:WaitForChild("Humanoid", 10)
	if not humanoid then
		return
	end
	humanoid.Died:Connect(function()
		local tag = humanoid:FindFirstChild("creator")
		local killer = tag and tag.Value
		if killer and killer:IsA("Player") and killer ~= victim then
			addLine(killer.Name .. " defeated " .. victim.Name)
		else
			addLine(victim.Name .. " fell")
		end
	end)
end

local function watchPlayer(other)
	other.CharacterAdded:Connect(function(character)
		watchCharacter(other, character)
	end)
	if other.Character then
		watchCharacter(other, other.Character)
	end
end
Players.PlayerAdded:Connect(watchPlayer)
for _, other in ipairs(Players:GetPlayers()) do
	watchPlayer(other)
end
