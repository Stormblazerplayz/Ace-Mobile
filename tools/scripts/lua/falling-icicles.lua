-- @title Falling icicles
-- @category Obstacles
-- @kind Script
-- @where Put this Script inside an Anchored icicle Part hanging from a ceiling.
-- @keywords falling icicle, icicle trap, stalactite falls, ceiling spike drops, falls when you walk under
-- @about When a player walks underneath, the icicle shakes, falls and hurts them, then grows back.

local Players = game:GetService("Players")

-- Settings: change these numbers!
local SEE_DISTANCE = 40 -- how far down it looks for players
local DAMAGE = 40
local REGROW_TIME = 5

local icicle = script.Parent
icicle.Anchored = true
local home = icicle.CFrame
local falling = false
local hurt = {}

local rayParams = RaycastParams.new()
rayParams.FilterType = Enum.RaycastFilterType.Exclude
rayParams.FilterDescendantsInstances = { icicle }

icicle.Touched:Connect(function(hit)
	local character = hit.Parent
	local player = Players:GetPlayerFromCharacter(character)
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if falling and player and humanoid and not hurt[player] then
		hurt[player] = true
		humanoid:TakeDamage(DAMAGE)
	end
end)

while true do
	task.wait(0.2)
	-- Shoot an invisible ray straight down to see what is under the icicle
	local result = workspace:Raycast(icicle.Position, Vector3.new(0, -SEE_DISTANCE, 0), rayParams)
	local hitModel = result and result.Instance:FindFirstAncestorOfClass("Model")
	if hitModel and Players:GetPlayerFromCharacter(hitModel) then
		-- Shake as a warning
		for _ = 1, 6 do
			icicle.CFrame = home * CFrame.Angles(0, 0, math.rad(math.random(-4, 4)))
			task.wait(0.05)
		end
		icicle.CFrame = home
		falling = true
		table.clear(hurt)
		icicle.Anchored = false
		task.wait(REGROW_TIME)
		falling = false
		icicle.Anchored = true
		icicle.CFrame = home
	end
end
