-- @title You died screen
-- @category GUI
-- @kind LocalScript
-- @where Put this LocalScript in StarterPlayer > StarterCharacterScripts.
-- @keywords death screen, you died, game over screen, respawn countdown, wasted screen
-- @about When your character dies the screen fades dark and shows "You died" with who defeated you and a respawn countdown.

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local humanoid = script.Parent:WaitForChild("Humanoid")

humanoid.Died:Connect(function()
	local gui = Instance.new("ScreenGui")
	gui.Name = "DeathScreen"
	gui.IgnoreGuiInset = true
	gui.Parent = player:WaitForChild("PlayerGui") -- removed by itself when you respawn

	local dark = Instance.new("Frame")
	dark.Size = UDim2.fromScale(1, 1)
	dark.BackgroundColor3 = Color3.new(0, 0, 0)
	dark.BackgroundTransparency = 1
	dark.Parent = gui
	TweenService:Create(dark, TweenInfo.new(1), { BackgroundTransparency = 0.4 }):Play()

	local title = Instance.new("TextLabel")
	title.AnchorPoint = Vector2.new(0.5, 0.5)
	title.Position = UDim2.fromScale(0.5, 0.4)
	title.Size = UDim2.fromScale(0.6, 0.15)
	title.BackgroundTransparency = 1
	title.Font = Enum.Font.GothamBlack
	title.TextScaled = true
	title.TextColor3 = Color3.fromRGB(230, 50, 50)
	title.Text = "You died"
	title.Parent = dark

	local info = title:Clone()
	info.Position = UDim2.fromScale(0.5, 0.55)
	info.Size = UDim2.fromScale(0.5, 0.07)
	info.Font = Enum.Font.Gotham
	info.TextColor3 = Color3.new(1, 1, 1)
	info.Parent = dark

	local tag = humanoid:FindFirstChild("creator")
	local killer = tag and tag.Value
	local killerText = (killer and killer:IsA("Player")) and ("Defeated by " .. killer.Name .. "\n") or ""

	-- Players.RespawnTime is how long until you come back
	for seconds = math.ceil(Players.RespawnTime), 1, -1 do
		info.Text = killerText .. "Respawning in " .. seconds
		task.wait(1)
	end
end)
