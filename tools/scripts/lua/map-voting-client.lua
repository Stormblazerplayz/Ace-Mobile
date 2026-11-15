-- @title Map voting buttons
-- @category Game rounds
-- @kind LocalScript
-- @where Put this LocalScript in StarterPlayer > StarterPlayerScripts. It works with the Map voting (server part) script.
-- @keywords vote buttons, map vote gui, voting screen, pick a map gui, vote countdown
-- @about Shows a button for each map while voting is open; click one to vote, and your choice turns green.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local voteEvent = ReplicatedStorage:WaitForChild("VoteMap")

local gui = Instance.new("ScreenGui")
gui.Name = "MapVote"
gui.ResetOnSpawn = false
gui.Enabled = false
gui.Parent = player:WaitForChild("PlayerGui")

local holder = Instance.new("Frame")
holder.AnchorPoint = Vector2.new(0.5, 1)
holder.Position = UDim2.new(0.5, 0, 1, -40)
holder.Size = UDim2.fromOffset(560, 120)
holder.BackgroundTransparency = 1
holder.Parent = gui
local layout = Instance.new("UIListLayout")
layout.FillDirection = Enum.FillDirection.Horizontal
layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
layout.Padding = UDim.new(0, 10)
layout.Parent = holder

local timerLabel = Instance.new("TextLabel")
timerLabel.AnchorPoint = Vector2.new(0.5, 1)
timerLabel.Position = UDim2.new(0.5, 0, 1, -170)
timerLabel.Size = UDim2.fromOffset(300, 34)
timerLabel.BackgroundTransparency = 1
timerLabel.Font = Enum.Font.GothamBlack
timerLabel.TextScaled = true
timerLabel.TextColor3 = Color3.new(1, 1, 1)
timerLabel.TextStrokeTransparency = 0
timerLabel.Parent = gui

local buttons = {}

local function build()
	for _, button in ipairs(buttons) do
		button:Destroy()
	end
	buttons = {}
	local text = ReplicatedStorage:GetAttribute("VoteOptions") or ""
	for name in string.gmatch(text, "[^,]+") do
		local button = Instance.new("TextButton")
		button.Size = UDim2.fromOffset(170, 110)
		button.Text = name
		button.TextScaled = true
		button.Font = Enum.Font.GothamBold
		button.TextColor3 = Color3.new(1, 1, 1)
		button.BackgroundColor3 = Color3.fromRGB(60, 60, 75)
		button.Parent = holder
		button.Activated:Connect(function()
			voteEvent:FireServer(name)
			for _, other in ipairs(buttons) do
				other.BackgroundColor3 = Color3.fromRGB(60, 60, 75)
			end
			button.BackgroundColor3 = Color3.fromRGB(60, 170, 90)
		end)
		table.insert(buttons, button)
	end
end

ReplicatedStorage:GetAttributeChangedSignal("VotingOpen"):Connect(function()
	local open = ReplicatedStorage:GetAttribute("VotingOpen") == true
	gui.Enabled = open
	if open then
		build()
	end
end)
ReplicatedStorage:GetAttributeChangedSignal("VoteTime"):Connect(function()
	timerLabel.Text = "Vote for a map! " .. (ReplicatedStorage:GetAttribute("VoteTime") or 0)
end)
if ReplicatedStorage:GetAttribute("VotingOpen") then
	gui.Enabled = true
	build()
end
