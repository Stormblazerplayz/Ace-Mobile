-- @title Zoom in with a scope
-- @category Camera
-- @kind LocalScript
-- @where Put this LocalScript in StarterPlayer > StarterPlayerScripts.
-- @keywords zoom scope, aim down sights, sniper zoom, binoculars, right click zoom
-- @about Hold the right mouse button (or Z, or the Zoom button on a phone) to zoom way in with a round scope overlay and slower aiming.

local ContextActionService = game:GetService("ContextActionService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")

-- Settings: change these!
local ZOOM_FOV = 20
local NORMAL_FOV = 70

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera
local normalSensitivity = UserInputService.MouseDeltaSensitivity

local gui = Instance.new("ScreenGui")
gui.Name = "Scope"
gui.IgnoreGuiInset = true
gui.ResetOnSpawn = false
gui.Enabled = false
gui.Parent = player:WaitForChild("PlayerGui")
-- A see-through circle with a thick black border looks like a scope
local ring = Instance.new("Frame")
ring.AnchorPoint = Vector2.new(0.5, 0.5)
ring.Position = UDim2.fromScale(0.5, 0.5)
ring.Size = UDim2.fromScale(0.8, 0.8)
ring.SizeConstraint = Enum.SizeConstraint.RelativeYY
ring.BackgroundTransparency = 1
ring.Parent = gui
Instance.new("UICorner", ring).CornerRadius = UDim.new(1, 0)
local stroke = Instance.new("UIStroke")
stroke.Thickness = 600
stroke.Color = Color3.new(0, 0, 0)
stroke.Parent = ring

local function zoom(on)
	gui.Enabled = on
	TweenService:Create(camera, TweenInfo.new(0.15), { FieldOfView = on and ZOOM_FOV or NORMAL_FOV }):Play()
	-- Slower mouse while zoomed so aiming is easier
	UserInputService.MouseDeltaSensitivity = on and normalSensitivity * 0.3 or normalSensitivity
end

ContextActionService:BindAction("ScopeZoom", function(_, state)
	if state == Enum.UserInputState.Begin then
		zoom(true)
	elseif state == Enum.UserInputState.End or state == Enum.UserInputState.Cancel then
		zoom(false)
	end
	return Enum.ContextActionResult.Pass
end, true, Enum.UserInputType.MouseButton2, Enum.KeyCode.Z)
ContextActionService:SetTitle("ScopeZoom", "Zoom")
