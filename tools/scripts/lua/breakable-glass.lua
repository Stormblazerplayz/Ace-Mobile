-- @title Breakable glass window
-- @category World and effects
-- @kind Script
-- @where Put this Script inside a thin Anchored glass Part (a window).
-- @keywords breakable glass, smash window, shatter glass, glass breaks, crash through window
-- @about Running into the window hard (or clicking it) shatters it into flying shards; it fixes itself later.

local Players = game:GetService("Players")
local Debris = game:GetService("Debris")

-- Settings: change these numbers!
local BREAK_SPEED = 20 -- how fast you must run into it
local SHARDS = 12
local REPAIR_TIME = 10

local glass = script.Parent
glass.Anchored = true
glass.Material = Enum.Material.Glass
glass.Transparency = 0.5
local broken = false

local function shatter()
	if broken then
		return
	end
	broken = true
	glass.Transparency = 1
	glass.CanCollide = false
	for _ = 1, SHARDS do
		local shard = Instance.new("Part")
		shard.Size = Vector3.new(math.random() + 0.3, math.random() + 0.3, 0.1)
		shard.Material = Enum.Material.Glass
		shard.Transparency = 0.4
		shard.Color = glass.Color
		-- Start somewhere on the window
		local offset = Vector3.new((math.random() - 0.5) * glass.Size.X, (math.random() - 0.5) * glass.Size.Y, 0)
		shard.CFrame = glass.CFrame * CFrame.new(offset) * CFrame.Angles(math.random(), math.random(), math.random())
		shard.Parent = workspace
		shard.AssemblyLinearVelocity = Vector3.new(math.random(-15, 15), math.random(0, 15), math.random(-15, 15))
		Debris:AddItem(shard, 4)
	end
	task.wait(REPAIR_TIME)
	glass.Transparency = 0.5
	glass.CanCollide = true
	broken = false
end

glass.Touched:Connect(function(hit)
	if broken then
		return
	end
	local character = hit.Parent
	local root = character and character:FindFirstChild("HumanoidRootPart")
	-- Unanchored things (players, balls, cars) going fast enough break it
	local speed = root and root.AssemblyLinearVelocity.Magnitude or hit.AssemblyLinearVelocity.Magnitude
	if (Players:GetPlayerFromCharacter(character) or not hit.Anchored) and speed >= BREAK_SPEED then
		shatter()
	end
end)

local clicker = Instance.new("ClickDetector")
clicker.Parent = glass
clicker.MouseClick:Connect(shatter)
