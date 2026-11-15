-- @title Enemy brain with states (module)
-- @category NPCs and AI
-- @kind ModuleScript
-- @where Put this ModuleScript in ServerScriptService and name it EnemyBrain. In an enemy's Script: require(game.ServerScriptService.EnemyBrain).Start(script.Parent).
-- @keywords state machine, ai states, enemy brain, idle chase attack, npc behavior module
-- @about A reusable enemy brain that switches between Idle, Chase, Attack and Return states, so all your enemies act the same smart way.

local Players = game:GetService("Players")

local EnemyBrain = {}

-- Default settings (each enemy can change them with attributes of the same name)
local DEFAULTS = { SightRange = 40, AttackRange = 5, Damage = 10, AttackCooldown = 1, LeashRange = 80 }

function EnemyBrain.Start(npc)
	local humanoid = npc:WaitForChild("Humanoid")
	local root = npc:WaitForChild("HumanoidRootPart")
	root:SetNetworkOwner(nil)
	local function setting(name)
		return npc:GetAttribute(name) or DEFAULTS[name]
	end
	local home = root.Position
	local state = "Idle"
	local target = nil
	local lastAttack = 0

	local function findTarget()
		for _, player in ipairs(Players:GetPlayers()) do
			local theirRoot = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
			local theirHumanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
			if theirRoot and theirHumanoid and theirHumanoid.Health > 0 and (theirRoot.Position - root.Position).Magnitude < setting("SightRange") then
				return theirRoot
			end
		end
		return nil
	end

	-- Each state is a function that does one step and returns the next state
	local states = {}
	states.Idle = function()
		target = findTarget()
		return target and "Chase" or "Idle"
	end
	states.Chase = function()
		if not target or not target.Parent or (root.Position - home).Magnitude > setting("LeashRange") then
			return "Return"
		end
		humanoid:MoveTo(target.Position)
		return (target.Position - root.Position).Magnitude <= setting("AttackRange") and "Attack" or "Chase"
	end
	states.Attack = function()
		local theirHumanoid = target and target.Parent and target.Parent:FindFirstChildOfClass("Humanoid")
		if not theirHumanoid or theirHumanoid.Health <= 0 then
			return "Return"
		end
		if os.clock() - lastAttack >= setting("AttackCooldown") then
			lastAttack = os.clock()
			theirHumanoid:TakeDamage(setting("Damage"))
		end
		return "Chase"
	end
	states.Return = function()
		target = nil
		humanoid:MoveTo(home)
		return (root.Position - home).Magnitude < 4 and "Idle" or "Return"
	end

	task.spawn(function()
		while humanoid.Health > 0 and npc.Parent do
			state = states[state]()
			npc:SetAttribute("State", state) -- handy for debugging in the Properties window
			task.wait(0.2)
		end
	end)
end

return EnemyBrain
