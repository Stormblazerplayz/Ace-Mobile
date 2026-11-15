-- @title Kill brick
-- @category Obstacles
-- @kind Script
-- @where Put this Script inside the Part you want to be deadly.
-- @keywords kill brick, kill part, death brick, lava brick, deadly part
-- @about Touching the part resets the player.

local Players = game:GetService("Players")

local part = script.Parent

-- When something touches the part...
part.Touched:Connect(function(hit)
	-- ...check if it belongs to a player's character
	local character = hit.Parent
	local player = Players:GetPlayerFromCharacter(character)
	if not player then
		return
	end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if humanoid and humanoid.Health > 0 then
		humanoid.Health = 0 -- Oof! Back to spawn.
	end
end)
