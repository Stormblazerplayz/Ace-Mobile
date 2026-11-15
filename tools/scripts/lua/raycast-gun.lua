-- @title Raycast gun (server part)
-- @category Tools and combat
-- @kind Script
-- @where Put this Script inside a Tool with a Handle part, add the Tool aiming (client part) LocalScript to the same Tool, and put the Tool in StarterPack.
-- @keywords gun, raycast gun, shooting, blaster, pistol, laser gun, gun with ammo
-- @about A gun the server controls: it checks every shot, uses ammo, reloads with R, and draws a laser line to what it hit.

local Players = game:GetService("Players")
local Debris = game:GetService("Debris")

-- Settings: change these!
local DAMAGE = 20
local HEADSHOT_MULTIPLIER = 2
local RANGE = 300
local FIRE_RATE = 0.15 -- seconds between shots
local MAG_SIZE = 12
local RELOAD_TIME = 1.5
local AUTOMATIC = false -- true = hold to keep shooting

local tool = script.Parent
local handle = tool:WaitForChild("Handle")

local clickPosition = Instance.new("RemoteEvent")
clickPosition.Name = "ClickPosition"
clickPosition.Parent = tool
local reloadEvent = Instance.new("RemoteEvent")
reloadEvent.Name = "Reload"
reloadEvent.Parent = tool

tool:SetAttribute("Ammo", MAG_SIZE)
tool:SetAttribute("MaxAmmo", MAG_SIZE)
tool:SetAttribute("Automatic", AUTOMATIC)
tool:SetAttribute("FireRate", FIRE_RATE)

local lastShot = 0
local reloading = false

local function reload()
	if reloading or tool:GetAttribute("Ammo") == MAG_SIZE then
		return
	end
	reloading = true
	tool:SetAttribute("Reloading", true)
	task.wait(RELOAD_TIME)
	tool:SetAttribute("Ammo", MAG_SIZE)
	tool:SetAttribute("Reloading", false)
	reloading = false
end

local function drawTracer(from, to)
	local beam = Instance.new("Part")
	beam.Anchored = true
	beam.CanCollide = false
	beam.CanQuery = false
	beam.CanTouch = false
	beam.Material = Enum.Material.Neon
	beam.Color = Color3.fromRGB(255, 230, 120)
	beam.Size = Vector3.new(0.1, 0.1, (to - from).Magnitude)
	beam.CFrame = CFrame.lookAt((from + to) / 2, to)
	beam.Parent = workspace
	Debris:AddItem(beam, 0.05)
end

local function hurt(attacker, humanoid, amount)
	local victim = Players:GetPlayerFromCharacter(humanoid.Parent)
	if victim and victim.Team and victim.Team == attacker.Team and not attacker.Neutral then
		return -- no hurting teammates
	end
	-- The "creator" tag tells kill scripts who did it
	local tag = Instance.new("ObjectValue")
	tag.Name = "creator"
	tag.Value = attacker
	tag.Parent = humanoid
	Debris:AddItem(tag, 2)
	humanoid:TakeDamage(amount)
end

clickPosition.OnServerEvent:Connect(function(player, target)
	local character = tool.Parent
	-- Only the player holding the gun may shoot it, and only with real data
	if Players:GetPlayerFromCharacter(character) ~= player or typeof(target) ~= "Vector3" then
		return
	end
	if reloading or os.clock() - lastShot < FIRE_RATE * 0.9 then
		return
	end
	local ammo = tool:GetAttribute("Ammo")
	if ammo <= 0 then
		task.spawn(reload)
		return
	end
	lastShot = os.clock()
	tool:SetAttribute("Ammo", ammo - 1)

	local origin = handle.Position
	local offset = target - origin
	if offset.Magnitude < 0.1 then
		return
	end
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { character }
	local result = workspace:Raycast(origin, offset.Unit * RANGE, params)
	drawTracer(origin, result and result.Position or origin + offset.Unit * RANGE)

	if result then
		local model = result.Instance:FindFirstAncestorOfClass("Model")
		local humanoid = model and model:FindFirstChildOfClass("Humanoid")
		if humanoid and humanoid.Health > 0 then
			local damage = result.Instance.Name == "Head" and DAMAGE * HEADSHOT_MULTIPLIER or DAMAGE
			hurt(player, humanoid, damage)
		end
	end
end)

reloadEvent.OnServerEvent:Connect(function(player)
	if Players:GetPlayerFromCharacter(tool.Parent) == player then
		reload()
	end
end)
