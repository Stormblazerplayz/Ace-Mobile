-- @title Pop-up spikes
-- @category Obstacles
-- @kind Script
-- @where Put this Script inside an Anchored Part (or spike mesh) sitting where the spikes stick out of the floor.
-- @keywords pop up spikes, spike trap, spikes come out of the floor, timed spikes, hidden spikes
-- @about The spikes slide down into the floor and pop back up, hurting anyone standing on them.

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

-- Settings: change these numbers!
local HIDE_DEPTH = 4 -- how far down the spikes hide (studs)
local UP_TIME = 1.5 -- seconds the spikes stay up
local DOWN_TIME = 2 -- seconds the spikes stay hidden
local DAMAGE = 35

local spikes = script.Parent
spikes.Anchored = true
local upCFrame = spikes.CFrame
local downCFrame = upCFrame * CFrame.new(0, -HIDE_DEPTH, 0)

local popUp = TweenService:Create(spikes, TweenInfo.new(0.15), { CFrame = upCFrame })
local goDown = TweenService:Create(spikes, TweenInfo.new(0.6), { CFrame = downCFrame })

local dangerous = false
local lastHit = {}

spikes.Touched:Connect(function(hit)
	local character = hit.Parent
	local player = Players:GetPlayerFromCharacter(character)
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not dangerous or not player or not humanoid then
		return
	end
	-- Only hurt the same player once each time the spikes pop up
	if lastHit[player] then
		return
	end
	lastHit[player] = true
	humanoid:TakeDamage(DAMAGE)
end)

spikes.CFrame = downCFrame
while true do
	task.wait(DOWN_TIME)
	table.clear(lastHit)
	dangerous = true
	popUp:Play()
	task.wait(UP_TIME)
	dangerous = false
	goDown:Play()
	goDown.Completed:Wait()
end
