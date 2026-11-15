-- @title Hide the default Roblox menus
-- @category GUI
-- @kind LocalScript
-- @where Put this LocalScript in StarterPlayer > StarterPlayerScripts and set each line to true or false.
-- @keywords hide backpack, hide player list, core gui, hide health bar, remove default ui
-- @about Turns off built-in Roblox screen parts like the backpack bar, player list or health bar so you can use your own.

local StarterGui = game:GetService("StarterGui")

-- Settings: true = show it, false = hide it
local SHOW = {
	[Enum.CoreGuiType.Backpack] = true,
	[Enum.CoreGuiType.PlayerList] = true,
	[Enum.CoreGuiType.Health] = false,
	[Enum.CoreGuiType.EmotesMenu] = true,
}

for guiType, show in pairs(SHOW) do
	-- Sometimes this fails if the game is still loading, so try a few times
	for _ = 1, 5 do
		local ok = pcall(function()
			StarterGui:SetCoreGuiEnabled(guiType, show)
		end)
		if ok then
			break
		end
		task.wait(1)
	end
end
