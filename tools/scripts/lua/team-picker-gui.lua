-- @title Team picker buttons
-- @category Teams
-- @kind LocalScript
-- @where Put this LocalScript in StarterPlayer > StarterPlayerScripts. It needs the Choose your team (server part) script.
-- @keywords team menu, team buttons, team selection screen, pick a side, team gui
-- @about Shows a button for every team in its team color with the number of players; click one to join that team.

local Players = game:GetService("Players")
local Teams = game:GetService("Teams")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local pickTeam = ReplicatedStorage:WaitForChild("PickTeam")

local gui = Instance.new("ScreenGui")
gui.Name = "TeamPicker"
gui.ResetOnSpawn = false
gui.Parent = player:WaitForChild("PlayerGui")

local toggle = Instance.new("TextButton")
toggle.Position = UDim2.new(0, 16, 0.5, -60)
toggle.Size = UDim2.fromOffset(80, 40)
toggle.Text = "Teams"
toggle.TextScaled = true
toggle.Font = Enum.Font.GothamBold
toggle.Parent = gui

local holder = Instance.new("Frame")
holder.AnchorPoint = Vector2.new(0.5, 0.5)
holder.Position = UDim2.fromScale(0.5, 0.5)
holder.Size = UDim2.fromOffset(500, 120)
holder.BackgroundTransparency = 1
holder.Visible = false
holder.Parent = gui
local layout = Instance.new("UIListLayout")
layout.FillDirection = Enum.FillDirection.Horizontal
layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
layout.Padding = UDim.new(0, 10)
layout.Parent = holder

local function build()
	for _, child in ipairs(holder:GetChildren()) do
		if child:IsA("TextButton") then
			child:Destroy()
		end
	end
	for _, team in ipairs(Teams:GetTeams()) do
		local button = Instance.new("TextButton")
		button.Size = UDim2.fromOffset(150, 110)
		button.BackgroundColor3 = team.TeamColor.Color
		button.Font = Enum.Font.GothamBlack
		button.TextScaled = true
		button.TextColor3 = Color3.new(1, 1, 1)
		button.TextStrokeTransparency = 0
		button.Text = team.Name .. "\n" .. #team:GetPlayers() .. " players" .. (player.Team == team and "\n(you)" or "")
		button.Parent = holder
		button.Activated:Connect(function()
			pickTeam:FireServer(team)
			holder.Visible = false
		end)
	end
end

toggle.Activated:Connect(function()
	holder.Visible = not holder.Visible
	if holder.Visible then
		build()
	end
end)
player:GetPropertyChangedSignal("Team"):Connect(function()
	if holder.Visible then
		build()
	end
end)
