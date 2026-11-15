-- @title Spectate other players
-- @category Camera
-- @kind LocalScript
-- @where Put this LocalScript in StarterPlayer > StarterPlayerScripts.
-- @keywords spectate, watch other players, spectator mode, follow cam, next player button
-- @about A Spectate button lets you watch other players; use the arrow buttons to switch between them and Stop to go back to yourself.

local Players = game:GetService("Players")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

local gui = Instance.new("ScreenGui")
gui.Name = "Spectate"
gui.ResetOnSpawn = false
gui.Parent = player:WaitForChild("PlayerGui")

local function makeButton(text, position, size)
	local button = Instance.new("TextButton")
	button.AnchorPoint = Vector2.new(0.5, 1)
	button.Position = position
	button.Size = size
	button.Text = text
	button.TextScaled = true
	button.Font = Enum.Font.GothamBold
	button.TextColor3 = Color3.new(1, 1, 1)
	button.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
	button.Parent = gui
	return button
end
local spectateButton = makeButton("Spectate", UDim2.new(0.5, 0, 1, -20), UDim2.fromOffset(140, 40))
local prevButton = makeButton("<", UDim2.new(0.5, -130, 1, -20), UDim2.fromOffset(40, 40))
local nextButton = makeButton(">", UDim2.new(0.5, 130, 1, -20), UDim2.fromOffset(40, 40))

local watching = false
local index = 1

local function others()
	local list = {}
	for _, other in ipairs(Players:GetPlayers()) do
		if other ~= player and other.Character and other.Character:FindFirstChildOfClass("Humanoid") then
			table.insert(list, other)
		end
	end
	return list
end

local function show()
	local list = others()
	prevButton.Visible = watching
	nextButton.Visible = watching
	if not watching or #list == 0 then
		watching = false
		prevButton.Visible, nextButton.Visible = false, false
		spectateButton.Text = "Spectate"
		local myHumanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
		camera.CameraSubject = myHumanoid
		return
	end
	index = (index - 1) % #list + 1
	local target = list[index]
	-- CameraSubject is what the camera follows
	camera.CameraSubject = target.Character:FindFirstChildOfClass("Humanoid")
	spectateButton.Text = "Stop (" .. target.DisplayName .. ")"
end

spectateButton.Activated:Connect(function()
	watching = not watching
	show()
end)
prevButton.Activated:Connect(function()
	index -= 1
	show()
end)
nextButton.Activated:Connect(function()
	index += 1
	show()
end)
player.CharacterAdded:Connect(function()
	task.wait()
	show()
end)
show()
