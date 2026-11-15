-- @title NPC comes back after dying
-- @category NPCs and AI
-- @kind Script
-- @where Put this Script inside any NPC Model with a Humanoid.
-- @keywords npc respawn, enemy respawn, mob comes back, respawning enemy, revive npc
-- @about When the NPC is defeated it disappears and a fresh copy appears back at its starting spot after a few seconds.

-- Settings: change this!
local RESPAWN_TIME = 10

local npc = script.Parent
local humanoid = npc:WaitForChild("Humanoid")

-- Make a backup copy right away, before anything gets broken
npc.Archivable = true
local backup = npc:Clone()
local startParent = npc.Parent

humanoid.Died:Connect(function()
	task.wait(RESPAWN_TIME)
	-- The backup has this script inside too, so it will respawn again next time
	local fresh = backup:Clone()
	fresh.Parent = startParent
	npc:Destroy()
end)
