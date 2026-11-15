-- @title Team score display
-- @category Teams
-- @kind LocalScript
-- @where Put this LocalScript in StarterPlayer > StarterPlayerScripts. Server scripts set scores with team:SetAttribute("Score", number) (the Team points from knockouts script does this).
-- @keywords team scoreboard, team score gui, red vs blue score, team points display, match score
-- @about Shows each team's score in its team color at the top of the screen, updating live.

local Players = game:GetService("Players")
local Teams = game:GetService("Teams")

local player = Players.LocalPlayer

local gui = Instance.new("ScreenGui")
gui.Name = "TeamScores"
gui.ResetOnSpawn = false
gui.Parent = player:WaitForChild("PlayerGui")

local holder = Instance.new("Frame")
holder.AnchorPoint = Vector2.new(0.5, 0)
holder.Position = UDim2.new(0.5, 0, 0, 8)
holder.Size = UDim2.fromOffset(400, 44)
holder.BackgroundTransparency = 1
holder.Parent = gui
local layout = Instance.new("UIListLayout")
layout.FillDirection = Enum.FillDirection.Horizontal
layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
layout.Padding = UDim.new(0, 8)
layout.Parent = holder

local labels = {}

local function addTeam(team)
	if not team:IsA("Team") or labels[team] then
		return
	end
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromOffset(120, 44)
	label.BackgroundColor3 = team.TeamColor.Color
	label.Font = Enum.Font.GothamBlack
	label.TextScaled = true
	label.TextColor3 = Color3.new(1, 1, 1)
	label.TextStrokeTransparency = 0
	label.Parent = holder
	Instance.new("UICorner", label)
	labels[team] = label
	local function update()
		label.Text = team.Name .. ": " .. (team:GetAttribute("Score") or 0)
	end
	team:GetAttributeChangedSignal("Score"):Connect(update)
	update()
end

for _, team in ipairs(Teams:GetTeams()) do
	addTeam(team)
end
Teams.ChildAdded:Connect(addTeam)
Teams.ChildRemoved:Connect(function(team)
	if labels[team] then
		labels[team]:Destroy()
		labels[team] = nil
	end
end)
