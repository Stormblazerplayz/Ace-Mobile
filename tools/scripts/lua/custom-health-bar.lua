-- @title Custom health bar
-- @category GUI
-- @kind LocalScript
-- @where Put this LocalScript in StarterPlayer > StarterPlayerScripts.
-- @keywords health bar, custom health bar, hp bar, health gui, life bar
-- @about Replaces the Roblox health bar with a big smooth one that shows your health number and turns red when low.

local Players = game:GetService("Players")
local StarterGui = game:GetService("StarterGui")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Health, false) -- hide the old one

local gui = Instance.new("ScreenGui")
gui.Name = "HealthBar"
gui.ResetOnSpawn = false
gui.Parent = player:WaitForChild("PlayerGui")

local back = Instance.new("Frame")
back.AnchorPoint = Vector2.new(0, 1)
back.Position = UDim2.new(0, 20, 1, -20)
back.Size = UDim2.fromOffset(260, 26)
back.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
back.Parent = gui
Instance.new("UICorner", back).CornerRadius = UDim.new(0, 8)

local fill = Instance.new("Frame")
fill.Size = UDim2.fromScale(1, 1)
fill.BackgroundColor3 = Color3.fromRGB(70, 220, 90)
fill.Parent = back
Instance.new("UICorner", fill).CornerRadius = UDim.new(0, 8)

local text = Instance.new("TextLabel")
text.Size = UDim2.fromScale(1, 1)
text.BackgroundTransparency = 1
text.Font = Enum.Font.GothamBold
text.TextScaled = true
text.TextColor3 = Color3.new(1, 1, 1)
text.TextStrokeTransparency = 0.5
text.ZIndex = 2
text.Parent = back

local function onCharacterAdded(character)
	local humanoid = character:WaitForChild("Humanoid")
	local function update()
		local fraction = math.clamp(humanoid.Health / humanoid.MaxHealth, 0, 1)
		TweenService:Create(fill, TweenInfo.new(0.25), {
			Size = UDim2.fromScale(fraction, 1),
			-- Green when healthy, red when almost dead
			BackgroundColor3 = Color3.fromRGB(230, 60, 60):Lerp(Color3.fromRGB(70, 220, 90), fraction),
		}):Play()
		text.Text = math.ceil(humanoid.Health) .. " / " .. humanoid.MaxHealth
	end
	humanoid.HealthChanged:Connect(update)
	humanoid:GetPropertyChangedSignal("MaxHealth"):Connect(update)
	update()
end

player.CharacterAdded:Connect(onCharacterAdded)
if player.Character then
	onCharacterAdded(player.Character)
end
