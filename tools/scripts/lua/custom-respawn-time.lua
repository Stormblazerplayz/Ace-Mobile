-- @title Custom respawn time
-- @category Players
-- @kind Script
-- @where Put this Script in ServerScriptService.
-- @keywords respawn time, respawn delay, faster respawn, wait before respawning, respawn timer
-- @about Lets you pick how long players wait before they come back to life, with a shorter wait for VIP user ids.

local Players = game:GetService("Players")

-- Settings: change these!
local RESPAWN_SECONDS = 3
local VIP_RESPAWN_SECONDS = 1
local VIP_USER_IDS = { [1] = true } -- put user ids here

-- We spawn characters ourselves instead of Roblox doing it
Players.CharacterAutoLoads = false

local function onPlayerAdded(player)
	player.CharacterAdded:Connect(function(character)
		local humanoid = character:WaitForChild("Humanoid")
		humanoid.Died:Connect(function()
			local waitTime = VIP_USER_IDS[player.UserId] and VIP_RESPAWN_SECONDS or RESPAWN_SECONDS
			player:SetAttribute("RespawnAt", os.time() + waitTime) -- a GUI could show this
			task.wait(waitTime)
			if player.Parent then
				player:LoadCharacter()
			end
		end)
	end)
	player:LoadCharacter() -- first spawn
end

Players.PlayerAdded:Connect(onPlayerAdded)
for _, player in ipairs(Players:GetPlayers()) do
	task.spawn(onPlayerAdded, player)
end
