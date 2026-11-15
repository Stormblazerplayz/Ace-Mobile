-- @title Click to teleport tool
-- @category Tools and combat
-- @kind Script
-- @where Put this Script inside a Tool with a Handle part, add the Tool aiming (client part) LocalScript to the same Tool, and put the Tool in StarterPack.
-- @keywords click teleport, teleport tool, blink tool, warp where you click, teleport wand
-- @about Click somewhere you can see to blink there instantly; the server checks it is close enough and not through a wall.

local Players = game:GetService("Players")

-- Settings: change these numbers!
local MAX_DISTANCE = 60
local COOLDOWN = 2

local tool = script.Parent
local clickPosition = Instance.new("RemoteEvent")
clickPosition.Name = "ClickPosition"
clickPosition.Parent = tool
local lastTeleport = 0

clickPosition.OnServerEvent:Connect(function(player, target)
	local character = tool.Parent
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if Players:GetPlayerFromCharacter(character) ~= player or typeof(target) ~= "Vector3" or not root then
		return
	end
	if os.clock() - lastTeleport < COOLDOWN then
		return
	end
	local offset = target - root.Position
	if offset.Magnitude > MAX_DISTANCE or offset.Magnitude < 2 then
		return
	end
	-- Make sure there is no wall in the way (no teleporting into closed rooms!)
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { character }
	local blocked = workspace:Raycast(root.Position, offset * 0.95, params)
	if blocked then
		return
	end
	lastTeleport = os.clock()
	-- Land a little above the spot, still facing the same way
	character:PivotTo(CFrame.new(target + Vector3.new(0, 3, 0)) * root.CFrame.Rotation)
end)
