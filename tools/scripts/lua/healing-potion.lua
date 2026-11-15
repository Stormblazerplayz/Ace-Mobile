-- @title Healing potion
-- @category Tools and combat
-- @kind Script
-- @where Put this Script inside a Tool with a Handle part (a bottle) and give the Tool to players (StarterPack or a shop).
-- @keywords healing potion, health potion, drink to heal, heal item, potion tool
-- @about Click while holding the potion to drink it and get health back; it has a few sips before it is used up.

local Players = game:GetService("Players")

-- Settings: change these numbers!
local HEAL_PER_SIP = 35
local SIPS = 3
local DRINK_TIME = 0.8 -- seconds per sip

local tool = script.Parent
local handle = tool:WaitForChild("Handle")
local sipsLeft = SIPS
local drinking = false
tool.ToolTip = "Healing Potion (" .. sipsLeft .. " sips)"

tool.Activated:Connect(function()
	local character = tool.Parent
	local player = Players:GetPlayerFromCharacter(character)
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if drinking or not player or not humanoid or humanoid.Health <= 0 then
		return
	end
	if humanoid.Health >= humanoid.MaxHealth then
		return -- already full, save it!
	end
	drinking = true

	-- Tilt the bottle up like you are drinking
	tool.Grip = tool.Grip * CFrame.Angles(math.rad(-60), 0, 0)
	task.wait(DRINK_TIME)
	tool.Grip = tool.Grip * CFrame.Angles(math.rad(60), 0, 0)

	humanoid.Health = math.min(humanoid.Health + HEAL_PER_SIP, humanoid.MaxHealth)
	sipsLeft -= 1
	tool.ToolTip = "Healing Potion (" .. sipsLeft .. " sips)"
	if sipsLeft <= 0 then
		tool:Destroy() -- all gone
		return
	end
	drinking = false
end)
