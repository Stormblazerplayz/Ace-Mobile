-- @title Tycoon dropper
-- @category Pickups and money
-- @kind Script
-- @where Put this Script inside a dropper Model that has a Part named Drop where the money blocks fall out.
-- @keywords tycoon dropper, dropper, ore dropper, money blocks, drops cash parts, tycoon machine
-- @about Drops a small money block every couple of seconds that rolls down your conveyor to the collector.

local Debris = game:GetService("Debris")

-- Settings: change these numbers!
local DROP_EVERY = 2 -- seconds between drops
local DROP_VALUE = 5 -- money each block is worth
local DROP_SIZE = 1
local DROP_COLOR = Color3.fromRGB(255, 200, 40)

local dropper = script.Parent
local dropPoint = dropper:WaitForChild("Drop")

while true do
	task.wait(DROP_EVERY)
	local block = Instance.new("Part")
	block.Name = "TycoonDrop"
	block.Size = Vector3.new(DROP_SIZE, DROP_SIZE, DROP_SIZE)
	block.Color = DROP_COLOR
	block.Material = Enum.Material.SmoothPlastic
	block.CFrame = dropPoint.CFrame - Vector3.new(0, dropPoint.Size.Y / 2 + DROP_SIZE, 0)
	block:SetAttribute("Value", DROP_VALUE) -- the collector reads this
	block.Parent = workspace
	block:SetNetworkOwner(nil)
	Debris:AddItem(block, 30) -- clean up blocks that fall off
end
