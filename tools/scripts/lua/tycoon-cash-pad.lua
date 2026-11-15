-- @title Tycoon cash collect pad
-- @category Pickups and money
-- @kind Script
-- @where Put this Script inside a Part in your tycoon Model (needs the Tycoon claim door script and a Coins stat in leaderstats).
-- @keywords collect cash pad, tycoon money pad, step to collect, bank pad, get tycoon money
-- @about Shows how much money the tycoon has made; the owner steps on it to collect it all.

local Players = game:GetService("Players")

local STAT_NAME = "Coins"

local pad = script.Parent
local tycoon = pad:FindFirstAncestorWhichIsA("Model")
local owner = tycoon:WaitForChild("Owner")
local bank = tycoon:WaitForChild("Bank")

-- Show the bank amount on the pad
local gui = Instance.new("SurfaceGui")
gui.Face = Enum.NormalId.Top
gui.Parent = pad
local label = Instance.new("TextLabel")
label.Size = UDim2.fromScale(1, 1)
label.BackgroundTransparency = 1
label.TextScaled = true
label.Font = Enum.Font.GothamBold
label.TextColor3 = Color3.fromRGB(120, 255, 120)
label.Parent = gui

local function refresh()
	label.Text = "$" .. bank.Value
end
bank.Changed:Connect(refresh)
refresh()

pad.Touched:Connect(function(hit)
	local player = Players:GetPlayerFromCharacter(hit.Parent)
	if not player or player ~= owner.Value or bank.Value <= 0 then
		return -- only the owner can collect
	end
	local stats = player:FindFirstChild("leaderstats")
	local coins = stats and stats:FindFirstChild(STAT_NAME)
	if coins then
		coins.Value = coins.Value + bank.Value
		bank.Value = 0
	end
end)
