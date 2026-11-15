-- @title Freeze ray
-- @category Tools and combat
-- @kind Script
-- @where Put this Script inside a Tool with a Handle part, add the Tool aiming (client part) LocalScript to the same Tool, and put the Tool in StarterPack.
-- @keywords freeze ray, ice gun, freeze players, frozen solid, ice blast
-- @about Zap a player or NPC to freeze them in a block of ice for a few seconds so they cannot move.

local Players = game:GetService("Players")
local Debris = game:GetService("Debris")

-- Settings: change these numbers!
local FREEZE_TIME = 3
local RANGE = 150
local COOLDOWN = 4

local tool = script.Parent
local handle = tool:WaitForChild("Handle")
local clickPosition = Instance.new("RemoteEvent")
clickPosition.Name = "ClickPosition"
clickPosition.Parent = tool
local lastShot = 0

local function freeze(model)
	local root = model:FindFirstChild("HumanoidRootPart")
	if not root or root.Anchored then
		return
	end
	root.Anchored = true -- an anchored root cannot move at all
	local ice = Instance.new("Highlight")
	ice.FillColor = Color3.fromRGB(160, 220, 255)
	ice.FillTransparency = 0.3
	ice.OutlineColor = Color3.new(1, 1, 1)
	ice.Parent = model
	task.wait(FREEZE_TIME)
	if root.Parent then
		root.Anchored = false
	end
	ice:Destroy()
end

clickPosition.OnServerEvent:Connect(function(player, target)
	local character = tool.Parent
	if Players:GetPlayerFromCharacter(character) ~= player or typeof(target) ~= "Vector3" then
		return
	end
	if os.clock() - lastShot < COOLDOWN then
		return
	end
	local origin = handle.Position
	if (target - origin).Magnitude < 1 then
		return
	end
	lastShot = os.clock()
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { character }
	local direction = (target - origin).Unit * RANGE
	local result = workspace:Raycast(origin, direction, params)

	-- Draw an icy beam
	local finish = result and result.Position or origin + direction
	local beam = Instance.new("Part")
	beam.Anchored = true
	beam.CanCollide = false
	beam.CanQuery = false
	beam.Material = Enum.Material.Neon
	beam.Color = Color3.fromRGB(150, 220, 255)
	beam.Size = Vector3.new(0.3, 0.3, (finish - origin).Magnitude)
	beam.CFrame = CFrame.lookAt((origin + finish) / 2, finish)
	beam.Parent = workspace
	Debris:AddItem(beam, 0.15)

	local model = result and result.Instance:FindFirstAncestorOfClass("Model")
	if model and model:FindFirstChildOfClass("Humanoid") then
		task.spawn(freeze, model)
	end
end)
