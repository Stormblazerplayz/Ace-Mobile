-- @title Survive the disaster
-- @category Game rounds
-- @kind Script
-- @where Put this Script in ServerScriptService and put a Part named DisasterArea over your map (its size is where disasters happen).
-- @keywords survive the disaster, natural disasters, flood disaster, meteor disaster, disaster round
-- @about Picks a random disaster (flood, meteors or strong wind) each round, and everyone still alive at the end gets a Win.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")

-- Settings: change these!
local DISASTER_TIME = 45
local area = workspace:WaitForChild("DisasterArea")

local status = ReplicatedStorage:FindFirstChild("Status") or Instance.new("StringValue")
status.Name = "Status"
status.Parent = ReplicatedStorage

local function randomPointAbove()
	local half = area.Size / 2
	return area.Position + Vector3.new(math.random(-half.X, half.X), half.Y, math.random(-half.Z, half.Z))
end

local disasters = {}

disasters.Flood = function()
	local water = Instance.new("Part")
	water.Anchored = true
	water.CanCollide = false
	water.Color = Color3.fromRGB(40, 110, 220)
	water.Transparency = 0.4
	water.Size = Vector3.new(area.Size.X, 1, area.Size.Z)
	water.Position = area.Position - Vector3.new(0, area.Size.Y / 2, 0)
	water.Parent = workspace
	for _ = 1, DISASTER_TIME do
		water.Size += Vector3.new(0, 1, 0) -- rise one stud a second
		water.Position += Vector3.new(0, 0.5, 0)
		local top = water.Position.Y + water.Size.Y / 2
		for _, player in ipairs(Players:GetPlayers()) do
			local head = player.Character and player.Character:FindFirstChild("Head")
			local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
			if head and humanoid and head.Position.Y < top then
				humanoid.Health = 0 -- head under water
			end
		end
		task.wait(1)
	end
	water:Destroy()
end

disasters.Meteors = function()
	for _ = 1, DISASTER_TIME * 2 do
		local rock = Instance.new("Part")
		rock.Shape = Enum.PartType.Ball
		rock.Size = Vector3.new(4, 4, 4)
		rock.Material = Enum.Material.Slate
		rock.Color = Color3.fromRGB(90, 60, 50)
		rock.Position = randomPointAbove()
		rock.Parent = workspace
		rock.Touched:Connect(function(hit)
			if hit.Anchored or hit.Parent:FindFirstChildOfClass("Humanoid") then
				local blast = Instance.new("Explosion")
				blast.Position = rock.Position
				blast.BlastRadius = 8
				blast.Parent = workspace
				rock:Destroy()
			end
		end)
		Debris:AddItem(rock, 10)
		task.wait(0.5)
	end
end

disasters.Wind = function()
	local push = Vector3.new(math.random(-1, 1), 0, math.random(-1, 1))
	if push.Magnitude == 0 then
		push = Vector3.new(1, 0, 0)
	end
	push = push.Unit * 40
	for _ = 1, DISASTER_TIME * 2 do
		for _, player in ipairs(Players:GetPlayers()) do
			local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
			if root then
				root.AssemblyLinearVelocity += push * 0.3 -- a gust shoves you
			end
		end
		task.wait(0.5)
	end
end

while true do
	for t = 15, 1, -1 do
		status.Value = "Disaster in " .. t
		task.wait(1)
	end
	local names = {}
	for name in pairs(disasters) do
		table.insert(names, name)
	end
	local name = names[math.random(1, #names)]
	status.Value = "DISASTER: " .. name .. "!"
	disasters[name]()
	-- Everyone still alive wins
	for _, player in ipairs(Players:GetPlayers()) do
		local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
		local stats = player:FindFirstChild("leaderstats")
		if humanoid and humanoid.Health > 0 and stats and stats:FindFirstChild("Wins") then
			stats.Wins.Value += 1
			player:SetAttribute("Notice", "You survived the " .. name .. "!")
		end
	end
	status.Value = "Survivors get a Win!"
	task.wait(5)
end
