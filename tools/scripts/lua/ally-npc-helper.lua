-- @title Helper buddy that fights for you
-- @category NPCs and AI
-- @kind Script
-- @where Put this Script in ServerScriptService and put a buddy NPC Model (with Humanoid and HumanoidRootPart) in ServerStorage named Buddy.
-- @keywords ally npc, helper buddy, companion fighter, npc teammate, sidekick
-- @about Every player gets a buddy who follows them around and attacks any enemy NPC that comes near.

local Players = game:GetService("Players")
local ServerStorage = game:GetService("ServerStorage")

-- Settings: change these!
local FIGHT_RANGE = 25
local DAMAGE = 8
local HIT_EVERY = 1

local template = ServerStorage:WaitForChild("Buddy")

-- Finds the closest enemy: a Humanoid that is not a player and not another buddy
local function closestEnemy(position)
	local best, bestDistance = nil, FIGHT_RANGE
	for _, model in ipairs(workspace:GetChildren()) do
		local humanoid = model:FindFirstChildOfClass("Humanoid")
		local root = model:FindFirstChild("HumanoidRootPart")
		if humanoid and root and humanoid.Health > 0 and not Players:GetPlayerFromCharacter(model) and not model:GetAttribute("IsBuddy") then
			local distance = (root.Position - position).Magnitude
			if distance < bestDistance then
				best, bestDistance = model, distance
			end
		end
	end
	return best, bestDistance
end

local function giveBuddy(player, character)
	local ownerRoot = character:WaitForChild("HumanoidRootPart")
	local buddy = template:Clone()
	buddy.Name = player.Name .. "'s Buddy"
	buddy:SetAttribute("IsBuddy", true)
	buddy:PivotTo(ownerRoot.CFrame * CFrame.new(4, 0, 4))
	buddy.Parent = workspace
	local humanoid = buddy:FindFirstChildOfClass("Humanoid")
	local root = buddy:FindFirstChild("HumanoidRootPart")
	root:SetNetworkOwner(nil)
	local lastHit = 0

	while buddy.Parent and character.Parent and humanoid.Health > 0 do
		local enemy, distance = closestEnemy(root.Position)
		if enemy then
			humanoid:MoveTo(enemy.HumanoidRootPart.Position)
			if distance < 5 and os.clock() - lastHit > HIT_EVERY then
				lastHit = os.clock()
				enemy:FindFirstChildOfClass("Humanoid"):TakeDamage(DAMAGE)
			end
		elseif (root.Position - ownerRoot.Position).Magnitude > 8 then
			-- Stay close to the owner, a little behind them
			humanoid:MoveTo((ownerRoot.CFrame * CFrame.new(3, 0, 4)).Position)
		end
		task.wait(0.25)
	end
	buddy:Destroy()
end

Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(function(character)
		task.spawn(giveBuddy, player, character) -- a new buddy each life
	end)
end)
