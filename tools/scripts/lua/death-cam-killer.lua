-- @title Death camera shows who got you
-- @category Camera
-- @kind LocalScript
-- @where Put this LocalScript in StarterPlayer > StarterCharacterScripts. Weapons must add a "creator" tag to victims (the weapon scripts here do).
-- @keywords death cam, killcam, watch your killer, camera after death, who defeated me
-- @about When you are knocked out, the camera follows the player who did it until you respawn.

local Players = game:GetService("Players")

local player = Players.LocalPlayer
local humanoid = script.Parent:WaitForChild("Humanoid")
local camera = workspace.CurrentCamera

humanoid.Died:Connect(function()
	local tag = humanoid:FindFirstChild("creator")
	local killer = tag and tag.Value
	if not (killer and killer:IsA("Player") and killer ~= player) then
		return
	end
	local killerHumanoid = killer.Character and killer.Character:FindFirstChildOfClass("Humanoid")
	if not killerHumanoid then
		return
	end
	task.wait(1) -- see your own fall for a moment first
	-- Following their Humanoid makes the camera orbit around them
	camera.CameraSubject = killerHumanoid

	local gui = Instance.new("ScreenGui")
	gui.Name = "DeathCam"
	gui.Parent = player:WaitForChild("PlayerGui") -- goes away by itself when you respawn
	local label = Instance.new("TextLabel")
	label.AnchorPoint = Vector2.new(0.5, 0)
	label.Position = UDim2.new(0.5, 0, 0, 60)
	label.Size = UDim2.fromOffset(360, 40)
	label.BackgroundColor3 = Color3.new(0, 0, 0)
	label.BackgroundTransparency = 0.4
	label.TextColor3 = Color3.fromRGB(255, 90, 90)
	label.Font = Enum.Font.GothamBold
	label.TextScaled = true
	label.Text = "Watching " .. killer.DisplayName
	label.Parent = gui
end)
