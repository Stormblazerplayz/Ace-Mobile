-- @title See teammates through walls
-- @category Teams
-- @kind LocalScript
-- @where Put this LocalScript in StarterPlayer > StarterPlayerScripts.
-- @keywords teammate highlight, see team through walls, team outline, ally glow, friendly outline
-- @about Draws a glowing outline in your team color around your teammates, even when they are behind walls.

local Players = game:GetService("Players")

local me = Players.LocalPlayer

local function refresh(player)
	local character = player.Character
	if not character or player == me then
		return
	end
	local old = character:FindFirstChild("TeamOutline")
	local sameTeam = me.Team ~= nil and player.Team == me.Team
	if not sameTeam then
		if old then
			old:Destroy()
		end
		return
	end
	local outline = old or Instance.new("Highlight")
	outline.Name = "TeamOutline"
	outline.FillTransparency = 1 -- only the outline, not a solid color
	outline.OutlineColor = player.TeamColor.Color
	outline.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop -- shows through walls
	outline.Parent = character
end

local function refreshAll()
	for _, player in ipairs(Players:GetPlayers()) do
		refresh(player)
	end
end

local function watch(player)
	player.CharacterAdded:Connect(function()
		task.wait(0.5)
		refresh(player)
	end)
	player:GetPropertyChangedSignal("Team"):Connect(function()
		if player == me then
			refreshAll() -- I switched teams: everyone might change
		else
			refresh(player)
		end
	end)
	refresh(player)
end

Players.PlayerAdded:Connect(watch)
for _, player in ipairs(Players:GetPlayers()) do
	watch(player)
end
