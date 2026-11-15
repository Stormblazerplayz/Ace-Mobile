-- @title Click sound on every button
-- @category Sound
-- @kind LocalScript
-- @where Put this LocalScript in StarterPlayer > StarterPlayerScripts and paste a click sound id into CLICK_ID (and a hover sound into HOVER_ID if you want).
-- @keywords button click sound, ui sounds, menu click, gui sound effect, hover sound
-- @about Every button in your game makes a click sound when pressed, without adding a sound to each one.

local Players = game:GetService("Players")
local SoundService = game:GetService("SoundService")

-- Settings: paste ids here
local CLICK_ID = ""
local HOVER_ID = ""

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local function makeSound(id, volume)
	if id == "" then
		return nil
	end
	local sound = Instance.new("Sound")
	sound.SoundId = id
	sound.Volume = volume
	sound.Parent = SoundService
	return sound
end
local click = makeSound(CLICK_ID, 0.6)
local hover = makeSound(HOVER_ID, 0.25)

local function hook(object)
	if not object:IsA("GuiButton") or object:GetAttribute("NoClickSound") then
		return
	end
	object.Activated:Connect(function()
		if click then
			-- PlayLocalSound plays it just for you, even if it overlaps
			SoundService:PlayLocalSound(click)
		end
	end)
	object.MouseEnter:Connect(function()
		if hover then
			SoundService:PlayLocalSound(hover)
		end
	end)
end

for _, object in ipairs(playerGui:GetDescendants()) do
	hook(object)
end
playerGui.DescendantAdded:Connect(hook)
