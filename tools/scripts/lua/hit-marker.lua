-- @title Hit marker
-- @category GUI
-- @kind LocalScript
-- @where Put this LocalScript in StarterPlayer > StarterPlayerScripts. Weapons must add a "creator" ObjectValue to the humanoid they hit (the weapon scripts here do).
-- @keywords hit marker, hit confirm, x marker, shot feedback, you hit someone
-- @about Flashes a white X in the middle of the screen whenever your weapon hits someone, and a red X if it knocked them out.

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer

local gui = Instance.new("ScreenGui")
gui.Name = "HitMarker"
gui.IgnoreGuiInset = true
gui.ResetOnSpawn = false
gui.Parent = player:WaitForChild("PlayerGui")

local marker = Instance.new("TextLabel")
marker.AnchorPoint = Vector2.new(0.5, 0.5)
marker.Position = UDim2.fromScale(0.5, 0.5)
marker.Size = UDim2.fromOffset(40, 40)
marker.BackgroundTransparency = 1
marker.Text = "X"
marker.Font = Enum.Font.GothamBold
marker.TextScaled = true
marker.TextTransparency = 1
marker.Parent = gui

local function show(color)
	marker.TextColor3 = color
	marker.TextTransparency = 0
	TweenService:Create(marker, TweenInfo.new(0.35), { TextTransparency = 1 }):Play()
end

-- Watch every humanoid in the game for a creator tag that points at us
local function watchHumanoid(humanoid)
	humanoid.ChildAdded:Connect(function(child)
		if child.Name == "creator" and child:IsA("ObjectValue") then
			task.wait() -- let the value arrive
			if child.Value == player then
				show(humanoid.Health <= 0 and Color3.fromRGB(255, 60, 60) or Color3.new(1, 1, 1))
			end
		end
	end)
end

for _, object in ipairs(workspace:GetDescendants()) do
	if object:IsA("Humanoid") then
		watchHumanoid(object)
	end
end
workspace.DescendantAdded:Connect(function(object)
	if object:IsA("Humanoid") then
		watchHumanoid(object)
	end
end)
