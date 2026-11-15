-- @title Button that opens and closes a menu
-- @category GUI
-- @kind LocalScript
-- @where Put this LocalScript inside a TextButton or ImageButton, and set FRAME_NAME to the name of a Frame in the same ScreenGui.
-- @keywords open menu button, toggle frame, close button, show and hide gui, popup menu
-- @about Clicking the button pops the menu frame open with a bounce, and clicking again shrinks it closed.

local TweenService = game:GetService("TweenService")

-- Settings: change this!
local FRAME_NAME = "ShopFrame" -- the Frame to open and close

local button = script.Parent
local screenGui = button:FindFirstAncestorOfClass("ScreenGui")
local frame = screenGui:WaitForChild(FRAME_NAME, 10)
if not frame then
	warn("Could not find a Frame named " .. FRAME_NAME)
	return
end

-- A UIScale lets us shrink and grow the whole frame smoothly
local scale = frame:FindFirstChildOfClass("UIScale") or Instance.new("UIScale")
scale.Parent = frame
frame.Visible = false
local isOpen = false

local function setOpen(open)
	isOpen = open
	if open then
		frame.Visible = true
		scale.Scale = 0.6
		TweenService:Create(scale, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play()
	else
		local shrink = TweenService:Create(scale, TweenInfo.new(0.15), { Scale = 0.6 })
		shrink:Play()
		shrink.Completed:Wait()
		if not isOpen then
			frame.Visible = false
		end
	end
end

button.Activated:Connect(function()
	setOpen(not isOpen)
end)

-- A button named CloseButton inside the frame closes it too
local close = frame:FindFirstChild("CloseButton", true)
if close and close:IsA("GuiButton") then
	close.Activated:Connect(function()
		setOpen(false)
	end)
end
