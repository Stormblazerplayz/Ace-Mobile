-- @title Quest tracker
-- @category GUI
-- @kind LocalScript
-- @where Put this LocalScript in StarterPlayer > StarterPlayerScripts. Server scripts set the player attributes QuestName, QuestProgress and QuestGoal.
-- @keywords quest tracker, mission progress, objective list, task tracker, quest log
-- @about Shows your current quest and how far along you are (like "Collect apples 3/10") on the side of the screen.

local Players = game:GetService("Players")

local player = Players.LocalPlayer

local gui = Instance.new("ScreenGui")
gui.Name = "QuestTracker"
gui.ResetOnSpawn = false
gui.Parent = player:WaitForChild("PlayerGui")

local box = Instance.new("Frame")
box.AnchorPoint = Vector2.new(1, 0.5)
box.Position = UDim2.new(1, -16, 0.45, 0)
box.Size = UDim2.fromOffset(240, 80)
box.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
box.BackgroundTransparency = 0.2
box.Parent = gui
Instance.new("UICorner", box)

local title = Instance.new("TextLabel")
title.Position = UDim2.fromOffset(10, 6)
title.Size = UDim2.new(1, -20, 0, 26)
title.BackgroundTransparency = 1
title.Font = Enum.Font.GothamBlack
title.TextXAlignment = Enum.TextXAlignment.Left
title.TextScaled = true
title.TextColor3 = Color3.fromRGB(255, 210, 90)
title.Parent = box

local progress = title:Clone()
progress.Position = UDim2.fromOffset(10, 40)
progress.Font = Enum.Font.Gotham
progress.TextColor3 = Color3.new(1, 1, 1)
progress.Parent = box

local function update()
	local name = player:GetAttribute("QuestName")
	if not name or name == "" then
		box.Visible = false
		return
	end
	box.Visible = true
	local done = player:GetAttribute("QuestProgress") or 0
	local goal = player:GetAttribute("QuestGoal") or 1
	title.Text = tostring(name)
	if done >= goal then
		progress.Text = "Complete!"
		progress.TextColor3 = Color3.fromRGB(90, 230, 90)
	else
		progress.Text = done .. " / " .. goal
		progress.TextColor3 = Color3.new(1, 1, 1)
	end
end

for _, attribute in ipairs({ "QuestName", "QuestProgress", "QuestGoal" }) do
	player:GetAttributeChangedSignal(attribute):Connect(update)
end
update()
