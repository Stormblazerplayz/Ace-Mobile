-- @title Different tools for each team
-- @category Teams
-- @kind Script
-- @where Put this Script in ServerScriptService. In ServerStorage make a Folder named TeamTools, and inside it one Folder per team (same name as the team) holding that team's Tools.
-- @keywords team tools, team loadout, team weapons, class tools, give tools by team
-- @about Each time a player spawns, they get the tools that belong to their team, like handcuffs for police and a crowbar for robbers.

local Players = game:GetService("Players")
local ServerStorage = game:GetService("ServerStorage")

local teamTools = ServerStorage:WaitForChild("TeamTools")

local function giveTools(player)
	local backpack = player:WaitForChild("Backpack")
	local team = player.Team
	local folder = team and teamTools:FindFirstChild(team.Name)
	-- Also give tools from a folder named Everyone to all teams
	for _, source in ipairs({ folder, teamTools:FindFirstChild("Everyone") }) do
		if source then
			for _, tool in ipairs(source:GetChildren()) do
				if tool:IsA("Tool") and not backpack:FindFirstChild(tool.Name) then
					tool:Clone().Parent = backpack
				end
			end
		end
	end
end

Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(function()
		giveTools(player)
	end)
	-- Switching teams: take away old team tools and give the new ones
	player:GetPropertyChangedSignal("Team"):Connect(function()
		local backpack = player:FindFirstChildOfClass("Backpack")
		if backpack then
			backpack:ClearAllChildren()
		end
		local character = player.Character
		local held = character and character:FindFirstChildOfClass("Tool")
		if held then
			held:Destroy()
		end
		giveTools(player)
	end)
end)
