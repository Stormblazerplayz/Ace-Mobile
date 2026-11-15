-- @title Domino run
-- @category Moving parts
-- @kind Script
-- @where Put this Script inside an Anchored Part on the floor; its front face points where the line of dominoes goes.
-- @keywords dominoes, domino run, knock over dominos, chain reaction, falling dominoes
-- @about Click the part to set up a fresh line of dominoes and knock the first one over.

-- Settings: change these numbers!
local COUNT = 30 -- how many dominoes
local GAP = 2.5 -- studs between dominoes
local SIZE = Vector3.new(3, 5, 0.6)

local base = script.Parent
local folder = Instance.new("Folder")
folder.Name = "Dominoes"
folder.Parent = workspace

local clicker = Instance.new("ClickDetector")
clicker.MaxActivationDistance = 30
clicker.Parent = base

local function buildAndPush()
	folder:ClearAllChildren()
	local first
	for i = 1, COUNT do
		local domino = Instance.new("Part")
		domino.Size = SIZE
		-- Line them up in front of the base, standing on the floor
		local offset = CFrame.new(0, SIZE.Y / 2 - base.Size.Y / 2, -(i * GAP))
		domino.CFrame = base.CFrame * offset
		domino.Color = Color3.fromHSV((i / COUNT) % 1, 0.7, 1) -- rainbow!
		domino.Parent = folder
		domino:SetNetworkOwner(nil)
		first = first or domino
	end
	task.wait(1)
	-- Tip the first one over by pushing its top forward
	local push = base.CFrame.LookVector * first.AssemblyMass * 15
	first:ApplyImpulseAtPosition(push, first.Position + Vector3.new(0, SIZE.Y / 2, 0))
end

local busy = false
clicker.MouseClick:Connect(function()
	if busy then
		return
	end
	busy = true
	buildAndPush()
	task.wait(3)
	busy = false
end)
