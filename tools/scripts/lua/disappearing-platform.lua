-- @title Disappearing platform
-- @category Obstacles
-- @kind Script
-- @where Put this Script inside the platform Part that should fade away when someone steps on it.
-- @keywords disappearing platform, fading platform, vanishing part, platform that disappears, fake floor
-- @about The platform fades away after someone steps on it, then comes back.

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

-- Settings: change these numbers!
local WAIT_BEFORE_FADE = 0.5 -- seconds before it starts fading
local FADE_TIME = 1 -- seconds it takes to fade out
local COME_BACK_TIME = 3 -- seconds before it comes back

local part = script.Parent
local startTransparency = part.Transparency
local busy = false

local function fadeTo(transparency)
	local tween = TweenService:Create(part, TweenInfo.new(FADE_TIME), { Transparency = transparency })
	tween:Play()
	tween.Completed:Wait()
end

part.Touched:Connect(function(hit)
	-- Only players start the fade, and only once at a time
	if busy or not Players:GetPlayerFromCharacter(hit.Parent) then
		return
	end
	busy = true

	task.wait(WAIT_BEFORE_FADE)
	fadeTo(1)
	part.CanCollide = false -- now you fall through!

	task.wait(COME_BACK_TIME)
	part.CanCollide = true
	fadeTo(startTransparency)
	busy = false
end)
