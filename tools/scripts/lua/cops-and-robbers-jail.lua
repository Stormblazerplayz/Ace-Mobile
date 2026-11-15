-- @title Cops and robbers jail
-- @category Teams
-- @kind Script
-- @where Put this Script in ServerScriptService. Make Teams named Cops and Robbers, and add a Part named JailCell (inside a closed room) to Workspace.
-- @keywords cops and robbers, jail, arrest, prison cell, police game
-- @about When a cop touches a robber, the robber is arrested and sent to jail for a while, and the cop gets a reward.

local Players = game:GetService("Players")
local Teams = game:GetService("Teams")

-- Settings: change these!
local JAIL_TIME = 30
local ARREST_REWARD = 50

local cops = Teams:WaitForChild("Cops")
local robbers = Teams:WaitForChild("Robbers")
local jailCell = workspace:WaitForChild("JailCell")
local jailed = {}

local function arrest(cop, robber)
	jailed[robber] = true
	local character = robber.Character
	if character then
		character:PivotTo(jailCell.CFrame + Vector3.new(0, 4, 0))
	end
	local coins = cop:FindFirstChild("leaderstats") and cop.leaderstats:FindFirstChild("Coins")
	if coins then
		coins.Value += ARREST_REWARD
	end
	cop:SetAttribute("Notice", "You arrested " .. robber.DisplayName .. "! +" .. ARREST_REWARD)
	-- Count down the jail time, then let them out at their spawn
	for seconds = JAIL_TIME, 1, -1 do
		if not robber.Parent then
			return
		end
		robber:SetAttribute("Notice", "In jail: " .. seconds)
		task.wait(1)
	end
	jailed[robber] = nil
	robber:LoadCharacter()
end

local function hookCop(player, character)
	for _, part in ipairs(character:GetChildren()) do
		if part:IsA("BasePart") then
			part.Touched:Connect(function(hit)
				local other = Players:GetPlayerFromCharacter(hit.Parent)
				if player.Team == cops and other and other.Team == robbers and not jailed[other] then
					task.spawn(arrest, player, other)
				end
			end)
		end
	end
end

Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(function(character)
		character:WaitForChild("HumanoidRootPart")
		hookCop(player, character)
		-- A robber who respawns while still jailed goes back to jail
		if jailed[player] then
			task.wait(0.5)
			character:PivotTo(jailCell.CFrame + Vector3.new(0, 4, 0))
		end
	end)
end)
Players.PlayerRemoving:Connect(function(player)
	jailed[player] = nil
end)
