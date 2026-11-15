-- @title Tycoon collector
-- @category Pickups and money
-- @kind Script
-- @where Put this Script inside a Part at the end of your conveyor, inside the tycoon Model (use it with the Tycoon claim door script).
-- @keywords tycoon collector, sell drops, collector part, turn drops into cash, tycoon furnace
-- @about Money blocks that touch the collector disappear and their value goes into the tycoon's bank.

local collector = script.Parent
local tycoon = collector:FindFirstAncestorWhichIsA("Model")
local bank = tycoon:WaitForChild("Bank")

collector.Touched:Connect(function(hit)
	local value = hit:GetAttribute("Value")
	if not value or hit:GetAttribute("Collected") then
		return
	end
	hit:SetAttribute("Collected", true) -- never count the same block twice
	bank.Value = bank.Value + value
	hit:Destroy()
end)
