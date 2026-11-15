-- @title Capture the flag
-- @category Game rounds
-- @kind Script
-- @where Put this Script in ServerScriptService. Make two Teams (Red and Blue). In Workspace add Parts named RedFlag and BlueFlag (the flags) and RedBase and BlueBase (where you bring them).
-- @keywords capture the flag, ctf, steal the flag, flag base, team flag game
-- @about Touch the other team's flag to carry it, bring it to your own base to score, and drop it if you die.

local Players = game:GetService("Players")
local Teams = game:GetService("Teams")

-- Settings: change these!
local SCORE_TO_WIN = 3

local flags = {
	Red = { flag = workspace:WaitForChild("RedFlag"), base = workspace:WaitForChild("RedBase") },
	Blue = { flag = workspace:WaitForChild("BlueFlag"), base = workspace:WaitForChild("BlueBase") },
}
local scores = { Red = 0, Blue = 0 }

for teamName, info in pairs(flags) do
	info.home = info.flag.CFrame
	info.flag.Anchored = true
	info.flag.CanCollide = false
	info.carrier = nil
end

local function resetFlag(info)
	info.carrier = nil
	info.flag.CFrame = info.home
end

for teamName, info in pairs(flags) do
	-- Picking up the enemy flag
	info.flag.Touched:Connect(function(hit)
		local player = Players:GetPlayerFromCharacter(hit.Parent)
		local humanoid = hit.Parent:FindFirstChildOfClass("Humanoid")
		if not player or not humanoid or humanoid.Health <= 0 or info.carrier then
			return
		end
		if player.Team and player.Team.Name ~= teamName then
			info.carrier = player
			humanoid.Died:Once(function()
				if info.carrier == player then
					resetFlag(info) -- dropped flags go home
				end
			end)
		end
	end)
	-- Scoring at your own base
	info.base.Touched:Connect(function(hit)
		local player = Players:GetPlayerFromCharacter(hit.Parent)
		if not player or not player.Team or player.Team.Name ~= teamName then
			return
		end
		for enemyName, enemy in pairs(flags) do
			if enemy.carrier == player then
				resetFlag(enemy)
				scores[teamName] += 1
				local team = Teams:FindFirstChild(teamName)
				for _, p in ipairs(Players:GetPlayers()) do
					p:SetAttribute("Notice", player.Name .. " captured the " .. enemyName .. " flag!")
				end
				workspace:SetAttribute("RedScore", scores.Red)
				workspace:SetAttribute("BlueScore", scores.Blue)
				if scores[teamName] >= SCORE_TO_WIN then
					workspace:SetAttribute("Announcement", (team and team.Name or teamName) .. " team wins!")
					scores.Red, scores.Blue = 0, 0
				end
			end
		end
	end)
end

-- Make carried flags float above the carrier's head
while true do
	task.wait(0.1)
	for _, info in pairs(flags) do
		local carrier = info.carrier
		if carrier then
			local character = carrier.Character
			local root = character and character:FindFirstChild("HumanoidRootPart")
			if root and carrier.Parent then
				info.flag.CFrame = root.CFrame * CFrame.new(0, 4, 0.5)
			else
				resetFlag(info)
			end
		end
	end
end
