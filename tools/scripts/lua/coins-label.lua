-- @title Coins on screen
-- @category GUI
-- @kind LocalScript
-- @where Put this LocalScript inside a TextLabel in a ScreenGui in StarterGui (you also need the Leaderstats with saving script).
-- @keywords show coins on screen, coin counter gui, money display, coins text label, how many coins i have
-- @about Shows the player's coins on the screen and updates it when the number changes.

local Players = game:GetService("Players")

-- Settings: change these!
local STAT_NAME = "Coins" -- must match your leaderstats name
local PREFIX = "Coins: " -- text shown before the number

local label = script.Parent
local player = Players.LocalPlayer

-- Wait for the leaderstats made by the server
local leaderstats = player:WaitForChild("leaderstats")
local stat = leaderstats:WaitForChild(STAT_NAME)

local function update()
	label.Text = PREFIX .. tostring(stat.Value)
end

update()
stat:GetPropertyChangedSignal("Value"):Connect(update)
