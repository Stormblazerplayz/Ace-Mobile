-- @title Set walk speed and jump height
-- @category Players
-- @kind Script
-- @where Put this Script in ServerScriptService.
-- @keywords walk speed, change walkspeed, jump height, faster players, set player speed, higher jumps
-- @about Gives every player your own walk speed, jump height and health each time they spawn.

local Players = game:GetService("Players")

-- Settings: change these numbers! (Roblox normally uses 16 speed and 7.2 jump height)
local WALK_SPEED = 24
local JUMP_HEIGHT = 10
local MAX_HEALTH = 100

local function onCharacterAdded(character)
	local humanoid = character:WaitForChild("Humanoid")
	humanoid.WalkSpeed = WALK_SPEED
	humanoid.UseJumpPower = false -- use JumpHeight (in studs), which is easier to understand
	humanoid.JumpHeight = JUMP_HEIGHT
	humanoid.MaxHealth = MAX_HEALTH
	humanoid.Health = MAX_HEALTH
end

local function onPlayerAdded(player)
	player.CharacterAdded:Connect(onCharacterAdded)
	if player.Character then
		onCharacterAdded(player.Character)
	end
end

Players.PlayerAdded:Connect(onPlayerAdded)
for _, player in ipairs(Players:GetPlayers()) do
	onPlayerAdded(player)
end
