-- @title Ammo counter on screen
-- @category Tools and combat
-- @kind LocalScript
-- @where Put this LocalScript inside a TextLabel in a ScreenGui in StarterGui (works with the Raycast gun script).
-- @keywords ammo counter, bullets left, ammo display, reload text, magazine count
-- @about Shows how many bullets are left in the gun you are holding, and says Reloading while you reload.

local Players = game:GetService("Players")

local label = script.Parent
local player = Players.LocalPlayer
label.Visible = false

local connections = {}

local function clear()
	for _, c in ipairs(connections) do
		c:Disconnect()
	end
	table.clear(connections)
	label.Visible = false
end

local function show(tool)
	clear()
	if tool:GetAttribute("MaxAmmo") == nil then
		return -- this tool has no ammo
	end
	local function update()
		if tool:GetAttribute("Reloading") then
			label.Text = "Reloading..."
		else
			label.Text = tool:GetAttribute("Ammo") .. " / " .. tool:GetAttribute("MaxAmmo")
		end
	end
	label.Visible = true
	update()
	table.insert(connections, tool:GetAttributeChangedSignal("Ammo"):Connect(update))
	table.insert(connections, tool:GetAttributeChangedSignal("Reloading"):Connect(update))
end

local function onCharacterAdded(character)
	clear()
	-- A Tool moves into the character when it is equipped
	character.ChildAdded:Connect(function(child)
		if child:IsA("Tool") then
			show(child)
		end
	end)
	character.ChildRemoved:Connect(function(child)
		if child:IsA("Tool") then
			clear()
		end
	end)
end

player.CharacterAdded:Connect(onCharacterAdded)
if player.Character then
	onCharacterAdded(player.Character)
end
