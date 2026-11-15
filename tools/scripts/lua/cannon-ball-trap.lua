-- @title Cannon that fires balls
-- @category Obstacles
-- @kind Script
-- @where Put this Script inside an Anchored Part (the cannon) and turn the part so its front face points where it should shoot.
-- @keywords cannon trap, cannonball, shooting cannon, ball launcher, fires balls at players
-- @about Shoots a cannonball out of its front face every few seconds that knocks players over and hurts them.

local Players = game:GetService("Players")
local Debris = game:GetService("Debris")

-- Settings: change these numbers!
local FIRE_EVERY = 2 -- seconds between shots
local BALL_SPEED = 80 -- how fast the ball flies
local BALL_SIZE = 3
local DAMAGE = 30
local BALL_LIFETIME = 5 -- seconds before the ball disappears

local cannon = script.Parent

local function fire()
	local ball = Instance.new("Part")
	ball.Shape = Enum.PartType.Ball
	ball.Size = Vector3.new(BALL_SIZE, BALL_SIZE, BALL_SIZE)
	ball.Color = Color3.fromRGB(30, 30, 30)
	ball.Material = Enum.Material.Metal
	-- Start just in front of the cannon
	ball.CFrame = cannon.CFrame * CFrame.new(0, 0, -(cannon.Size.Z / 2 + BALL_SIZE))
	ball.Parent = workspace
	ball:SetNetworkOwner(nil) -- the server moves it, so it flies smoothly
	ball.AssemblyLinearVelocity = cannon.CFrame.LookVector * BALL_SPEED

	local hitPlayers = {}
	ball.Touched:Connect(function(hit)
		local character = hit.Parent
		local player = Players:GetPlayerFromCharacter(character)
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		if player and humanoid and not hitPlayers[player] then
			hitPlayers[player] = true
			humanoid:TakeDamage(DAMAGE)
		end
	end)
	Debris:AddItem(ball, BALL_LIFETIME) -- clean up automatically
end

while true do
	fire()
	task.wait(FIRE_EVERY)
end
