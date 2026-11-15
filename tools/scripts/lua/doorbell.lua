-- @title Doorbell
-- @category Doors and buttons
-- @kind Script
-- @where Put this Script inside the doorbell button Part next to a door.
-- @keywords doorbell, ring the bell, ding dong, knock on door, house bell
-- @about Click the doorbell to play a ding dong sound and show who is at the door.

local Debris = game:GetService("Debris")

-- Settings: change these!
local SOUND_ID = "" -- paste a doorbell sound id from the Creator Store, like "rbxassetid://123456"
local COOLDOWN = 3

local bell = script.Parent
local clicker = Instance.new("ClickDetector")
clicker.MaxActivationDistance = 10
clicker.Parent = bell

local sound = Instance.new("Sound")
sound.SoundId = SOUND_ID
sound.Volume = 1
sound.RollOffMaxDistance = 80 -- people far away cannot hear it
sound.Parent = bell

local ready = true
clicker.MouseClick:Connect(function(player)
	if not ready then
		return
	end
	ready = false
	if SOUND_ID ~= "" then
		sound:Play()
	end

	-- A little bubble that says who rang
	local bubble = Instance.new("BillboardGui")
	bubble.Size = UDim2.fromOffset(200, 40)
	bubble.StudsOffset = Vector3.new(0, 3, 0)
	bubble.Parent = bell
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.TextScaled = true
	label.TextColor3 = Color3.new(1, 1, 1)
	label.TextStrokeTransparency = 0.3
	label.Text = "Ding dong! " .. player.DisplayName .. " is here"
	label.Parent = bubble
	Debris:AddItem(bubble, COOLDOWN)

	task.wait(COOLDOWN)
	ready = true
end)
