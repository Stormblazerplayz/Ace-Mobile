-- @title Coins count up smoothly
-- @category GUI
-- @kind LocalScript
-- @where Put this LocalScript inside a TextLabel in a ScreenGui. It shows the player's leaderstats Coins.
-- @keywords counting number, number roll up, animated coins text, smooth counter, ticking numbers
-- @about Instead of jumping straight to the new number, the coin text quickly counts up (or down) to it and pops a little.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

-- Settings: change this!
local STAT_NAME = "Coins"
local COUNT_TIME = 0.6 -- seconds to reach the new number

local label = script.Parent
local player = Players.LocalPlayer
local stat = player:WaitForChild("leaderstats"):WaitForChild(STAT_NAME)

local scale = Instance.new("UIScale")
scale.Parent = label

local shown = stat.Value
label.Text = tostring(shown)
local animation = nil

stat.Changed:Connect(function(target)
	if animation then
		animation:Disconnect()
	end
	local from = shown
	local elapsed = 0
	scale.Scale = 1.2
	TweenService:Create(scale, TweenInfo.new(0.3), { Scale = 1 }):Play()
	-- Every frame, move the shown number a bit closer to the real one
	animation = RunService.RenderStepped:Connect(function(deltaTime)
		elapsed += deltaTime
		local alpha = math.min(elapsed / COUNT_TIME, 1)
		shown = math.floor(from + (target - from) * alpha + 0.5)
		label.Text = tostring(shown)
		if alpha >= 1 then
			animation:Disconnect()
			animation = nil
		end
	end)
end)
