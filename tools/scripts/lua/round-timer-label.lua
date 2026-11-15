-- @title Round timer text
-- @category GUI
-- @kind LocalScript
-- @where Put this LocalScript inside a TextLabel in a ScreenGui in StarterGui (it shows the text from the Round timer with intermission script).
-- @keywords timer on screen, countdown text, show round time, intermission text, timer gui
-- @about Shows the round countdown on every player's screen.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local label = script.Parent

-- The server writes the time into this StringValue
local status = ReplicatedStorage:WaitForChild("Status")

local function update()
	label.Text = status.Value
end

update()
-- Update the text every time the server changes it
status:GetPropertyChangedSignal("Value"):Connect(update)
