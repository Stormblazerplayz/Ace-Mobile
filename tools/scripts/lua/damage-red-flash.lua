-- @title Red flash when hurt
-- @category GUI
-- @kind LocalScript
-- @where Put this LocalScript in StarterPlayer > StarterCharacterScripts.
-- @keywords damage flash, red screen, hurt effect, hit indicator screen, pain flash
-- @about Flashes the edges of the screen red whenever your character loses health.

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local humanoid = script.Parent:WaitForChild("Humanoid")

local gui = Instance.new("ScreenGui")
gui.Name = "HurtFlash"
gui.IgnoreGuiInset = true
gui.Parent = player:WaitForChild("PlayerGui") -- ResetOnSpawn is on, so it is remade each life

local flash = Instance.new("Frame")
flash.Size = UDim2.fromScale(1, 1)
flash.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
flash.BackgroundTransparency = 1
flash.Parent = gui

-- A gradient makes the middle clear and the edges red
local gradient = Instance.new("UIGradient")
gradient.Transparency = NumberSequence.new({
	NumberSequenceKeypoint.new(0, 0),
	NumberSequenceKeypoint.new(0.3, 1),
	NumberSequenceKeypoint.new(0.7, 1),
	NumberSequenceKeypoint.new(1, 0),
})
gradient.Parent = flash

local lastHealth = humanoid.Health
humanoid.HealthChanged:Connect(function(health)
	if health < lastHealth then
		-- Bigger hits make a stronger flash
		local strength = math.clamp((lastHealth - health) / 40, 0.3, 1)
		flash.BackgroundTransparency = 1 - 0.6 * strength
		TweenService:Create(flash, TweenInfo.new(0.5), { BackgroundTransparency = 1 }):Play()
	end
	lastHealth = health
end)
