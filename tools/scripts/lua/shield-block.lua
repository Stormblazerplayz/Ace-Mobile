-- @title Shield that blocks damage
-- @category Tools and combat
-- @kind Script
-- @where Put this Script inside a Tool with a Handle part (the shield) and put the Tool in StarterPack.
-- @keywords shield, block attacks, blocking, raise shield, parry
-- @about Click to raise your shield for a moment; while it is up you take no damage, then it needs to cool down.

local Players = game:GetService("Players")

-- Settings: change these numbers!
local BLOCK_TIME = 1.5 -- seconds the shield is up
local COOLDOWN = 3 -- seconds before you can block again
local BLOCK_SPEED = 8 -- you walk slowly while blocking

local tool = script.Parent
local handle = tool:WaitForChild("Handle")
local ready = true

tool.Activated:Connect(function()
	local character = tool.Parent
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not ready or not Players:GetPlayerFromCharacter(character) or not humanoid then
		return
	end
	ready = false

	-- An invisible ForceField stops damage from TakeDamage (what most weapons use)
	local block = Instance.new("ForceField")
	block.Visible = false
	block.Parent = character
	character:SetAttribute("Blocking", true)
	local normalSpeed = humanoid.WalkSpeed
	humanoid.WalkSpeed = BLOCK_SPEED
	handle.Material = Enum.Material.ForceField

	task.wait(BLOCK_TIME)
	block:Destroy()
	character:SetAttribute("Blocking", nil)
	if humanoid.Parent then
		humanoid.WalkSpeed = normalSpeed
	end
	handle.Material = Enum.Material.Metal

	task.wait(COOLDOWN)
	ready = true
end)
