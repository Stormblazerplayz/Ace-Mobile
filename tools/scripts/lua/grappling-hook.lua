-- @title Grappling hook
-- @category Tools and combat
-- @kind Script
-- @where Put this Script inside a Tool with a Handle part, add the Tool aiming (client part) LocalScript to the same Tool, and put the Tool in StarterPack.
-- @keywords grappling hook, grapple, swing to walls, hookshot, pull yourself, spider rope
-- @about Click a wall or ceiling to shoot a rope at it and get pulled there fast.

local Players = game:GetService("Players")

-- Settings: change these numbers!
local RANGE = 120
local PULL_SPEED = 90
local MAX_PULL_TIME = 2.5
local COOLDOWN = 1

local tool = script.Parent
local handle = tool:WaitForChild("Handle")
local clickPosition = Instance.new("RemoteEvent")
clickPosition.Name = "ClickPosition"
clickPosition.Parent = tool
local busy = false

clickPosition.OnServerEvent:Connect(function(player, target)
	local character = tool.Parent
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if busy or Players:GetPlayerFromCharacter(character) ~= player or typeof(target) ~= "Vector3" or not root then
		return
	end
	local offset = target - handle.Position
	if offset.Magnitude < 1 then
		return
	end
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { character }
	local result = workspace:Raycast(handle.Position, offset.Unit * RANGE, params)
	if not result or not result.Instance.Anchored then
		return -- only grab onto things that do not move
	end
	busy = true

	-- An attachment stuck where the hook landed
	local hookPoint = Instance.new("Attachment")
	hookPoint.Parent = result.Instance
	hookPoint.WorldPosition = result.Position

	-- A rope you can see, from the gun to the hook
	local gunPoint = Instance.new("Attachment")
	gunPoint.Parent = handle
	local rope = Instance.new("RopeConstraint")
	rope.Attachment0 = gunPoint
	rope.Attachment1 = hookPoint
	rope.Visible = true
	rope.Length = (result.Position - handle.Position).Magnitude + 5
	rope.Parent = handle

	-- AlignPosition pulls the player's body toward the hook
	local pull = Instance.new("AlignPosition")
	pull.Attachment0 = root:FindFirstChild("RootAttachment")
	pull.Attachment1 = hookPoint
	pull.MaxVelocity = PULL_SPEED
	pull.MaxForce = math.huge
	pull.Responsiveness = 50
	pull.Parent = root

	local started = os.clock()
	while os.clock() - started < MAX_PULL_TIME and (root.Position - result.Position).Magnitude > 5 do
		task.wait()
	end
	pull:Destroy()
	rope:Destroy()
	gunPoint:Destroy()
	hookPoint:Destroy()
	task.wait(COOLDOWN)
	busy = false
end)
