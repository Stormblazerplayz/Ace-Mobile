-- @title Basic sword
-- @category Tools and combat
-- @kind Script
-- @where Put this Script inside a Tool that has a part named Handle, then put the Tool in StarterPack.
-- @keywords sword, sword script, slash and damage, melee weapon, sword that hurts players
-- @about Click or tap to swing the sword and hurt other players and NPCs it hits (never yourself).

local Players = game:GetService("Players")

-- Settings: change these numbers!
local DAMAGE = 25 -- health taken per hit
local SWING_TIME = 0.4 -- seconds a swing can hit things
local COOLDOWN = 0.8 -- seconds between swings
local TEAM_DAMAGE = false -- true = you can hurt your own team

local tool = script.Parent
local handle = tool:WaitForChild("Handle")
local swinging = false
local canSwing = true
local hitThisSwing = {} -- each enemy can only be hit once per swing

tool.Activated:Connect(function()
	if not canSwing then
		return
	end
	canSwing = false
	swinging = true
	hitThisSwing = {}

	-- Play Roblox's built-in sword slash animation
	local anim = Instance.new("StringValue")
	anim.Name = "toolanim"
	anim.Value = "Slash"
	anim.Parent = tool

	task.wait(SWING_TIME)
	swinging = false
	task.wait(math.max(COOLDOWN - SWING_TIME, 0))
	canSwing = true
end)

handle.Touched:Connect(function(hit)
	if not swinging then
		return
	end
	local owner = tool.Parent -- the character holding the sword
	local character = hit.Parent
	if not character or character == owner then
		return -- no hitting yourself!
	end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid or humanoid.Health <= 0 or hitThisSwing[humanoid] then
		return
	end

	-- Skip teammates (only if your game has teams)
	local ownerPlayer = Players:GetPlayerFromCharacter(owner)
	local victimPlayer = Players:GetPlayerFromCharacter(character)
	if not TEAM_DAMAGE and ownerPlayer and victimPlayer and victimPlayer.Team ~= nil
		and victimPlayer.Team == ownerPlayer.Team then
		return
	end

	hitThisSwing[humanoid] = true
	humanoid:TakeDamage(DAMAGE)
end)
