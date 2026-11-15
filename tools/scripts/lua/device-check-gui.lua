-- @title Show GUI only on phone or PC
-- @category GUI
-- @kind LocalScript
-- @where Put this LocalScript in StarterPlayer > StarterPlayerScripts. Name GUI objects MobileOnly or PCOnly (or give them a Device attribute set to Mobile or PC).
-- @keywords mobile only gui, touch screen check, pc only button, device detection, platform gui
-- @about Hides GUI meant for touch screens on computers, and hides keyboard hints on phones and tablets.

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- A touch screen without a keyboard is a phone or tablet
local function isMobile()
	return UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
end

local function apply(object)
	if not object:IsA("GuiObject") then
		return
	end
	local device = object:GetAttribute("Device")
	if object.Name == "MobileOnly" or device == "Mobile" then
		object.Visible = isMobile()
	elseif object.Name == "PCOnly" or device == "PC" then
		object.Visible = not isMobile()
	end
end

local function applyAll()
	for _, object in ipairs(playerGui:GetDescendants()) do
		apply(object)
	end
end

playerGui.DescendantAdded:Connect(apply)
-- If someone plugs in a keyboard, check again
UserInputService:GetPropertyChangedSignal("KeyboardEnabled"):Connect(applyAll)
applyAll()
