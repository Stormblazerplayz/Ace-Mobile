-- @title Dialog box with typing text
-- @category GUI
-- @kind LocalScript
-- @where Put this LocalScript in StarterPlayer > StarterPlayerScripts; server scripts show talk with ReplicatedStorage.ShowDialog:FireClient(player, "Name", {"line 1", "line 2"}).
-- @keywords dialog box, typewriter text, npc talking, story text, speech box, cutscene text
-- @about Shows a story box at the bottom of the screen where the words type out one letter at a time; tap to go to the next line.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Settings: change this!
local LETTER_DELAY = 0.03 -- seconds per letter

local player = Players.LocalPlayer
local showDialog = ReplicatedStorage:WaitForChild("ShowDialog") -- a RemoteEvent you add (or the NPC scripts make)

local gui = Instance.new("ScreenGui")
gui.Name = "Dialog"
gui.ResetOnSpawn = false
gui.Enabled = false
gui.Parent = player:WaitForChild("PlayerGui")

local box = Instance.new("TextButton") -- a button so tapping anywhere on it goes to the next line
box.AutoButtonColor = false
box.AnchorPoint = Vector2.new(0.5, 1)
box.Position = UDim2.new(0.5, 0, 1, -30)
box.Size = UDim2.new(0.7, 0, 0, 130)
box.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
box.Text = ""
box.Parent = gui
Instance.new("UICorner", box)

local nameLabel = Instance.new("TextLabel")
nameLabel.Position = UDim2.fromOffset(16, 8)
nameLabel.Size = UDim2.new(1, -32, 0, 28)
nameLabel.BackgroundTransparency = 1
nameLabel.TextXAlignment = Enum.TextXAlignment.Left
nameLabel.Font = Enum.Font.GothamBlack
nameLabel.TextSize = 22
nameLabel.TextColor3 = Color3.fromRGB(255, 210, 90)
nameLabel.Parent = box

local textLabel = nameLabel:Clone()
textLabel.Position = UDim2.fromOffset(16, 40)
textLabel.Size = UDim2.new(1, -32, 1, -50)
textLabel.Font = Enum.Font.Gotham
textLabel.TextColor3 = Color3.new(1, 1, 1)
textLabel.TextWrapped = true
textLabel.TextYAlignment = Enum.TextYAlignment.Top
textLabel.Parent = box

local clicked = Instance.new("BindableEvent")
box.Activated:Connect(function()
	clicked:Fire()
end)

local busy = false
showDialog.OnClientEvent:Connect(function(speaker, lines)
	if busy or type(lines) ~= "table" then
		return
	end
	busy = true
	gui.Enabled = true
	nameLabel.Text = tostring(speaker)
	for _, line in ipairs(lines) do
		line = tostring(line)
		textLabel.Text = line
		-- MaxVisibleGraphemes shows only the first few letters: perfect for typing!
		local skipped = false
		local skip = clicked.Event:Once(function()
			skipped = true
		end)
		for i = 1, #line do
			if skipped then
				break
			end
			textLabel.MaxVisibleGraphemes = i
			task.wait(LETTER_DELAY)
		end
		skip:Disconnect()
		textLabel.MaxVisibleGraphemes = -1 -- show everything
		clicked.Event:Wait() -- wait for a tap before the next line
	end
	gui.Enabled = false
	busy = false
end)
