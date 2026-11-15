-- @title Throwable grenade
-- @category Tools and combat
-- @kind Script
-- @where Put this Script inside a Tool with a Handle part, add the Tool aiming (client part) LocalScript to the same Tool, and put the Tool in StarterPack.
-- @keywords grenade, throw grenade, bomb throw, frag grenade, explosive throw
-- @about Throws a grenade in an arc to where you click; it bounces around and explodes after a short fuse.

local Players = game:GetService("Players")
local Debris = game:GetService("Debris")

-- Settings: change these numbers!
local FUSE = 2.5 -- seconds before it explodes
local DAMAGE = 70
local BLAST_RADIUS = 12
local COOLDOWN = 3
local MAX_THROW = 120 -- studs

local tool = script.Parent
local handle = tool:WaitForChild("Handle")
local clickPosition = Instance.new("RemoteEvent")
clickPosition.Name = "ClickPosition"
clickPosition.Parent = tool
local lastThrow = 0

clickPosition.OnServerEvent:Connect(function(player, target)
	local character = tool.Parent
	if Players:GetPlayerFromCharacter(character) ~= player or typeof(target) ~= "Vector3" then
		return
	end
	if os.clock() - lastThrow < COOLDOWN then
		return
	end
	lastThrow = os.clock()

	local start = handle.Position + Vector3.new(0, 1, 0)
	local offset = target - start
	if offset.Magnitude > MAX_THROW then
		offset = offset.Unit * MAX_THROW
	end
	-- Physics trick: pick a flight time, then work out the speed that lands on the target
	local flightTime = math.clamp(offset.Magnitude / 50, 0.4, 1.5)
	local gravity = Vector3.new(0, -workspace.Gravity, 0)
	local velocity = offset / flightTime - gravity * flightTime / 2

	local grenade = Instance.new("Part")
	grenade.Shape = Enum.PartType.Ball
	grenade.Size = Vector3.new(1, 1, 1)
	grenade.Color = Color3.fromRGB(60, 80, 50)
	grenade.Position = start
	grenade.Parent = workspace
	grenade:SetNetworkOwner(nil)
	grenade.AssemblyLinearVelocity = velocity

	task.delay(FUSE, function()
		if not grenade.Parent then
			return
		end
		local boom = Instance.new("Explosion")
		boom.Position = grenade.Position
		boom.BlastRadius = BLAST_RADIUS
		boom.DestroyJointRadiusPercent = 0
		local hurt = {}
		boom.Hit:Connect(function(part, distance)
			local model = part:FindFirstAncestorOfClass("Model")
			local humanoid = model and model:FindFirstChildOfClass("Humanoid")
			if humanoid and not hurt[humanoid] then
				hurt[humanoid] = true
				local victim = Players:GetPlayerFromCharacter(model)
				local teammate = victim and victim ~= player and victim.Team and victim.Team == player.Team and not player.Neutral
				if not teammate then
					local tag = Instance.new("ObjectValue")
					tag.Name = "creator"
					tag.Value = player
					tag.Parent = humanoid
					Debris:AddItem(tag, 2)
					humanoid:TakeDamage(DAMAGE * (1 - distance / BLAST_RADIUS))
				end
			end
		end)
		boom.Parent = workspace
		grenade:Destroy()
	end)
end)
