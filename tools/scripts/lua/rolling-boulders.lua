-- @title Rolling boulders
-- @category Obstacles
-- @kind Script
-- @where Put this Script inside an Anchored, non-colliding Part at the top of a slope, with its front face pointing down the hill.
-- @keywords rolling boulders, boulder trap, rocks roll down hill, giant rolling ball, avalanche
-- @about Big boulders roll down the hill every few seconds and knock out players they run over.

local Players = game:GetService("Players")
local Debris = game:GetService("Debris")

-- Settings: change these numbers!
local SPAWN_EVERY = 3 -- seconds between boulders
local SIZE = 8 -- how big each boulder is
local START_SPEED = 20 -- starting push down the hill
local DAMAGE = 50
local LIFETIME = 12 -- seconds before a boulder is cleaned up

local spawner = script.Parent
spawner.Anchored = true
spawner.CanCollide = false
spawner.Transparency = 1

local function spawnBoulder()
	local boulder = Instance.new("Part")
	boulder.Shape = Enum.PartType.Ball
	boulder.Size = Vector3.new(SIZE, SIZE, SIZE)
	boulder.Material = Enum.Material.Slate
	boulder.Color = Color3.fromRGB(110, 100, 90)
	boulder.CFrame = spawner.CFrame
	boulder.Parent = workspace
	boulder:SetNetworkOwner(nil)
	boulder.AssemblyLinearVelocity = spawner.CFrame.LookVector * START_SPEED

	local hurt = {}
	boulder.Touched:Connect(function(hit)
		local character = hit.Parent
		local player = Players:GetPlayerFromCharacter(character)
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		if player and humanoid and not hurt[player] then
			hurt[player] = true
			humanoid:TakeDamage(DAMAGE)
		end
	end)
	Debris:AddItem(boulder, LIFETIME)
end

while true do
	spawnBoulder()
	task.wait(SPAWN_EVERY)
end
