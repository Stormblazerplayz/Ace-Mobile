-- @title Progress bar maker (module)
-- @category GUI
-- @kind ModuleScript
-- @where Put this ModuleScript in ReplicatedStorage and name it ProgressBar. In a LocalScript: local bar = require(game.ReplicatedStorage.ProgressBar).new(parentFrame) then bar:Set(0.5).
-- @keywords progress bar module, bar fill module, fill bar, percent bar, reusable bar
-- @about A reusable module that makes a smooth fill bar you can set to any amount from 0 to 1, with optional text.

local TweenService = game:GetService("TweenService")

local ProgressBar = {}
ProgressBar.__index = ProgressBar

-- new(parent, color) makes a bar that fills its parent
function ProgressBar.new(parent, color)
	local self = setmetatable({}, ProgressBar)
	self.Back = Instance.new("Frame")
	self.Back.Size = UDim2.fromScale(1, 1)
	self.Back.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
	self.Back.Parent = parent
	Instance.new("UICorner", self.Back)

	self.Fill = Instance.new("Frame")
	self.Fill.Size = UDim2.fromScale(0, 1)
	self.Fill.BackgroundColor3 = color or Color3.fromRGB(90, 200, 90)
	self.Fill.Parent = self.Back
	Instance.new("UICorner", self.Fill)

	self.Label = Instance.new("TextLabel")
	self.Label.Size = UDim2.fromScale(1, 1)
	self.Label.BackgroundTransparency = 1
	self.Label.Font = Enum.Font.GothamBold
	self.Label.TextScaled = true
	self.Label.TextColor3 = Color3.new(1, 1, 1)
	self.Label.Text = ""
	self.Label.Parent = self.Back
	return self
end

-- Set(amount, text): amount is 0 to 1
function ProgressBar:Set(amount, text)
	amount = math.clamp(amount, 0, 1)
	TweenService:Create(self.Fill, TweenInfo.new(0.25), { Size = UDim2.fromScale(amount, 1) }):Play()
	self.Label.Text = text or (math.floor(amount * 100) .. "%")
end

function ProgressBar:Destroy()
	self.Back:Destroy()
end

return ProgressBar
