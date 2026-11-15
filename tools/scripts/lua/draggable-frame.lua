-- @title Drag a window around
-- @category GUI
-- @kind LocalScript
-- @where Put this LocalScript inside the Frame you want to be draggable (in a ScreenGui in StarterGui).
-- @keywords draggable frame, drag window, move gui with mouse, ui drag detector, movable panel
-- @about Lets players grab the frame with the mouse or a finger and drag it anywhere on the screen.

local frame = script.Parent

-- UIDragDetector is the built-in Roblox object that makes GUI draggable
local dragger = Instance.new("UIDragDetector")
dragger.DragStyle = Enum.UIDragDetectorDragStyle.TranslatePlane
dragger.Parent = frame

-- Keep the frame on the screen when the drag ends
dragger.DragEnd:Connect(function()
	local screen = frame:FindFirstAncestorOfClass("ScreenGui")
	if not screen then
		return
	end
	local screenSize = screen.AbsoluteSize
	local pos = frame.AbsolutePosition
	local size = frame.AbsoluteSize
	if pos.X < 0 or pos.Y < 0 or pos.X + size.X > screenSize.X or pos.Y + size.Y > screenSize.Y then
		-- Snap back to the middle if it went off the edge
		frame.AnchorPoint = Vector2.new(0.5, 0.5)
		frame.Position = UDim2.fromScale(0.5, 0.5)
	end
end)

-- Make the frame slightly see-through while dragging so you can see behind it
local startTransparency = frame.BackgroundTransparency
dragger.DragStart:Connect(function()
	frame.BackgroundTransparency = math.min(startTransparency + 0.3, 1)
end)
dragger.DragEnd:Connect(function()
	frame.BackgroundTransparency = startTransparency
end)
