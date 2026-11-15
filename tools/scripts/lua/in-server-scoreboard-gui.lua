-- @title Custom scoreboard screen
-- @category Leaderboards
-- @kind LocalScript
-- @where Put this LocalScript in StarterPlayer > StarterPlayerScripts. It shows every value in each player's leaderstats.
-- @keywords scoreboard gui, custom player list, tab scoreboard, score table, stats screen
-- @about Hold Tab (or tap the Scores button) to see a big scoreboard of everyone in the server, sorted by the first stat.

local Players = game:GetService("Players")
local ContextActionService = game:GetService("ContextActionService")

local player = Players.LocalPlayer

local gui = Instance.new("ScreenGui")
gui.Name = "Scoreboard"
gui.ResetOnSpawn = false
gui.Enabled = false
gui.Parent = player:WaitForChild("PlayerGui")

local panel = Instance.new("Frame")
panel.AnchorPoint = Vector2.new(0.5, 0.5)
panel.Position = UDim2.fromScale(0.5, 0.5)
panel.Size = UDim2.fromOffset(460, 360)
panel.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
panel.BackgroundTransparency = 0.1
panel.Parent = gui
local layout = Instance.new("UIListLayout")
layout.SortOrder = Enum.SortOrder.LayoutOrder
layout.Parent = panel

local function addRow(order, cells, color)
	local row = Instance.new("TextLabel")
	row.LayoutOrder = order
	row.Size = UDim2.new(1, 0, 0, 30)
	row.BackgroundTransparency = 1
	row.Font = Enum.Font.Code
	row.TextSize = 18
	row.TextXAlignment = Enum.TextXAlignment.Left
	row.TextColor3 = color or Color3.new(1, 1, 1)
	local text = ""
	for i, cell in ipairs(cells) do
		-- Pad each cell to the same width so the columns line up
		text ..= string.format(i == 1 and "%-18s" or "%10s", string.sub(tostring(cell), 1, i == 1 and 17 or 9))
	end
	row.Text = "  " .. text
	row.Parent = panel
end

local function refresh()
	for _, child in ipairs(panel:GetChildren()) do
		if child:IsA("TextLabel") then
			child:Destroy()
		end
	end
	local statNames = {}
	local mine = player:FindFirstChild("leaderstats")
	for _, stat in ipairs(mine and mine:GetChildren() or {}) do
		table.insert(statNames, stat.Name)
	end
	local header = { "Player" }
	for _, name in ipairs(statNames) do
		table.insert(header, name)
	end
	addRow(0, header, Color3.fromRGB(255, 210, 90))
	local rows = {}
	for _, other in ipairs(Players:GetPlayers()) do
		local stats = other:FindFirstChild("leaderstats")
		local cells = { other.DisplayName }
		for _, name in ipairs(statNames) do
			local stat = stats and stats:FindFirstChild(name)
			table.insert(cells, stat and stat.Value or "-")
		end
		table.insert(rows, { cells = cells, sortBy = tonumber(cells[2]) or 0, me = other == player })
	end
	table.sort(rows, function(a, b)
		return a.sortBy > b.sortBy
	end)
	for i, row in ipairs(rows) do
		addRow(i, row.cells, row.me and Color3.fromRGB(120, 220, 255) or nil)
	end
end

ContextActionService:BindAction("ShowScores", function(_, state)
	if state == Enum.UserInputState.Begin then
		refresh()
		gui.Enabled = true
	elseif state == Enum.UserInputState.End or state == Enum.UserInputState.Cancel then
		gui.Enabled = false
	end
	return Enum.ContextActionResult.Sink
end, true, Enum.KeyCode.Tab)
ContextActionService:SetTitle("ShowScores", "Scores")
