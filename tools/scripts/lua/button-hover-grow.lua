-- @title Buttons grow when hovered
-- @category GUI
-- @kind LocalScript
-- @where Put this LocalScript inside a ScreenGui in StarterGui. Every button inside that ScreenGui gets the effect.
-- @keywords hover grow, button animation, bouncy buttons, button juice, press shrink
-- @about Makes every button in the ScreenGui grow a little when the mouse is over it and squish when clicked.

local TweenService = game:GetService("TweenService")

local screenGui = script.Parent
local quick = TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

local function addEffect(button)
	if not button:IsA("GuiButton") or button:FindFirstChild("HoverScale") then
		return
	end
	local scale = Instance.new("UIScale")
	scale.Name = "HoverScale"
	scale.Parent = button
	local function to(size)
		TweenService:Create(scale, quick, { Scale = size }):Play()
	end
	button.MouseEnter:Connect(function()
		to(1.08)
	end)
	button.MouseLeave:Connect(function()
		to(1)
	end)
	button.MouseButton1Down:Connect(function()
		to(0.92)
	end)
	button.MouseButton1Up:Connect(function()
		to(1.08)
	end)
end

for _, object in ipairs(screenGui:GetDescendants()) do
	addEffect(object)
end
screenGui.DescendantAdded:Connect(addEffect)
