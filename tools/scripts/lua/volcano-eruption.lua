-- @title Erupting volcano
-- @category World and effects
-- @kind Script
-- @where Put this Script inside an Anchored, non-colliding Part sitting in the crater at the top of your volcano.
-- @keywords volcano, eruption, lava rocks, volcano erupts, flying lava
-- @about Every so often the volcano rumbles, glows and shoots burning lava rocks in all directions that hurt players.

local Players = game:GetService("Players")
local Debris = game:GetService("Debris")

-- Settings: change these numbers!
local ERUPT_EVERY = 60 -- seconds between eruptions
local ROCKS = 20
local ROCK_SPEED = 90
local DAMAGE = 25

local crater = script.Parent
crater.CanCollide = false
local glow = Instance.new("PointLight")
glow.Color = Color3.fromRGB(255, 100, 30)
glow.Range = 60
glow.Brightness = 0
glow.Parent = crater

local function throwRock()
	local rock = Instance.new("Part")
	rock.Size = Vector3.new(3, 3, 3)
	rock.Material = Enum.Material.CrackedLava
	rock.Color = Color3.fromRGB(255, 90, 30)
	rock.CFrame = crater.CFrame + Vector3.new(0, 4, 0)
	local fire = Instance.new("Fire")
	fire.Size = 5
	fire.Parent = rock
	rock.Parent = workspace
	rock:SetNetworkOwner(nil)
	-- Mostly up, a bit sideways in a random direction
	local angle = math.random() * math.pi * 2
	local sideways = Vector3.new(math.cos(angle), 0, math.sin(angle)) * math.random(20, 50)
	rock.AssemblyLinearVelocity = Vector3.new(0, ROCK_SPEED, 0) + sideways

	local hurt = {}
	rock.Touched:Connect(function(hit)
		local character = hit.Parent
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		if humanoid and Players:GetPlayerFromCharacter(character) and not hurt[humanoid] then
			hurt[humanoid] = true
			humanoid:TakeDamage(DAMAGE)
		end
	end)
	Debris:AddItem(rock, 8)
end

while true do
	task.wait(ERUPT_EVERY)
	-- Rumble: the glow gets brighter
	for i = 1, 10 do
		glow.Brightness = i / 2
		task.wait(0.2)
	end
	for _ = 1, ROCKS do
		throwRock()
		task.wait(0.1)
	end
	glow.Brightness = 0
end
