-- @title Team colored shirts
-- @category Teams
-- @kind Script
-- @where Put this Script in ServerScriptService.
-- @keywords team colors, team uniform, team shirt color, color by team, body color team
-- @about Every time a player spawns, their shirt, arms and legs are colored with their team's color so teams are easy to tell apart.

local Players = game:GetService("Players")

-- Settings: which parts get the team color
local COLOR_TORSO = true
local COLOR_ARMS = true
local COLOR_LEGS = false
local REMOVE_CLOTHES = true -- clothes cover body colors, so take them off

local function paint(player, character)
	if not player.Team then
		return
	end
	local color = player.TeamColor.Color
	if REMOVE_CLOTHES then
		for _, item in ipairs(character:GetChildren()) do
			if item:IsA("Shirt") or item:IsA("Pants") or item:IsA("ShirtGraphic") then
				item:Destroy()
			end
		end
	end
	local colors = character:FindFirstChildOfClass("BodyColors") or Instance.new("BodyColors")
	if COLOR_TORSO then
		colors.TorsoColor3 = color
	end
	if COLOR_ARMS then
		colors.LeftArmColor3 = color
		colors.RightArmColor3 = color
	end
	if COLOR_LEGS then
		colors.LeftLegColor3 = color
		colors.RightLegColor3 = color
	end
	colors.Parent = character
end

Players.PlayerAdded:Connect(function(player)
	-- CharacterAppearanceLoaded waits for their avatar, so our colors go on top
	player.CharacterAppearanceLoaded:Connect(function(character)
		paint(player, character)
	end)
	player:GetPropertyChangedSignal("Team"):Connect(function()
		if player.Character then
			paint(player, player.Character)
		end
	end)
end)
