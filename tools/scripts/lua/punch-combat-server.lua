-- @title Punch combat (server part)
-- @category Tools and combat
-- @kind Script
-- @where Put this Script in ServerScriptService and add the Punch combat (client part) LocalScript too.
-- @keywords punch server, punch hit check, punch damage, fist hitbox, fair punching
-- @about Checks each punch on the server with a cooldown and a small hitbox in front of the player, then damages and knocks back who it hits.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")

-- Settings: change these numbers!
local DAMAGE = 10
local COOLDOWN = 0.5
local REACH = 4 -- how far in front the hitbox is
local KNOCKBACK = 30

local punchEvent = ReplicatedStorage:FindFirstChild("Punch") or Instance.new("RemoteEvent")
punchEvent.Name = "Punch"
punchEvent.Parent = ReplicatedStorage
local lastPunch = {}

punchEvent.OnServerEvent:Connect(function(player)
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not root or not humanoid or humanoid.Health <= 0 then
		return
	end
	if os.clock() - (lastPunch[player] or 0) < COOLDOWN then
		return -- too fast (stops auto clickers and cheaters)
	end
	lastPunch[player] = os.clock()

	-- A box in front of the player is the "fist"
	local params = OverlapParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { character }
	local boxCFrame = root.CFrame * CFrame.new(0, 0, -REACH)
	local hitSomeone = {}
	for _, part in ipairs(workspace:GetPartBoundsInBox(boxCFrame, Vector3.new(4, 5, 4), params)) do
		local model = part:FindFirstAncestorOfClass("Model")
		local enemy = model and model:FindFirstChildOfClass("Humanoid")
		if enemy and enemy.Health > 0 and not hitSomeone[enemy] then
			hitSomeone[enemy] = true
			local tag = Instance.new("ObjectValue")
			tag.Name = "creator"
			tag.Value = player
			tag.Parent = enemy
			Debris:AddItem(tag, 2)
			enemy:TakeDamage(DAMAGE)
			local enemyRoot = model:FindFirstChild("HumanoidRootPart")
			if enemyRoot then
				enemyRoot.AssemblyLinearVelocity = root.CFrame.LookVector * KNOCKBACK + Vector3.new(0, 10, 0)
			end
		end
	end
end)

Players.PlayerRemoving:Connect(function(player)
	lastPunch[player] = nil
end)
