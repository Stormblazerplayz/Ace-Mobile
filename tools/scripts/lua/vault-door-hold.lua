-- @title Bank vault door (hold to crack)
-- @category Doors and buttons
-- @kind Script
-- @where Put this Script inside the round Anchored vault door Part (a Cylinder turned to face out works great).
-- @keywords vault door, bank vault, hold to open, crack the safe, heist door
-- @about Hold E for 10 seconds to crack the vault; the big door swings open and closes again later.

local TweenService = game:GetService("TweenService")

-- Settings: change these numbers!
local HOLD_SECONDS = 10
local STAY_OPEN = 15

local door = script.Parent
door.Anchored = true
local closed = door.CFrame
-- Swing open around the door's left edge
local hinge = closed * CFrame.new(0, 0, -door.Size.Z / 2)
local open = hinge * CFrame.Angles(0, math.rad(100), 0) * CFrame.new(0, 0, door.Size.Z / 2)

local prompt = Instance.new("ProximityPrompt")
prompt.ActionText = "Crack vault"
prompt.ObjectText = "Vault"
prompt.HoldDuration = HOLD_SECONDS -- the player must hold the key this long
prompt.Parent = door

prompt.Triggered:Connect(function(player)
	prompt.Enabled = false
	player:SetAttribute("Notice", "Vault cracked!")
	local swing = TweenService:Create(door, TweenInfo.new(3, Enum.EasingStyle.Quad), { CFrame = open })
	swing:Play()
	task.wait(STAY_OPEN)
	local shut = TweenService:Create(door, TweenInfo.new(3, Enum.EasingStyle.Quad), { CFrame = closed })
	shut:Play()
	shut.Completed:Wait()
	prompt.Enabled = true
end)
