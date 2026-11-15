-- @title AFK detector (client part)
-- @category Players
-- @kind LocalScript
-- @where Put this LocalScript in StarterPlayer > StarterPlayerScripts, and add the AFK tag (server part) script too.
-- @keywords afk detector, away from keyboard, idle check, not moving detector, tabbed out
-- @about Notices when you have not touched any controls for a while (or left the window) and tells the server you are AFK.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

-- Settings: change this number!
local AFK_AFTER = 60 -- seconds with no input before you count as AFK

local setAfk = ReplicatedStorage:WaitForChild("SetAFK")
local lastInput = os.clock()
local isAfk = false
local focused = true

local function setState(afk)
	if afk ~= isAfk then
		isAfk = afk
		setAfk:FireServer(afk)
	end
end

UserInputService.InputBegan:Connect(function()
	lastInput = os.clock()
	setState(false)
end)
UserInputService.InputChanged:Connect(function(input)
	if input.UserInputType ~= Enum.UserInputType.MouseMovement then
		lastInput = os.clock()
	end
end)
-- Clicking away from the Roblox window counts as AFK straight away
UserInputService.WindowFocusReleased:Connect(function()
	focused = false
	setState(true)
end)
UserInputService.WindowFocused:Connect(function()
	focused = true
	lastInput = os.clock()
	setState(false)
end)

while true do
	task.wait(2)
	if focused then
		setState(os.clock() - lastInput > AFK_AFTER)
	end
end
