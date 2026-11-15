-- @title Tool aiming (client part)
-- @category Tools and combat
-- @kind LocalScript
-- @where Put this LocalScript inside a Tool together with one of the server weapon scripts (Raycast gun, Rocket launcher, Grenade, Bow, Freeze ray and others).
-- @keywords aim tool, mouse aim, send click position, gun client, shoot where you click, hold to fire
-- @about Sends the spot you click or tap to the tool's server script, holds to keep firing if the tool is automatic, and presses R to reload.

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

local tool = script.Parent
local player = Players.LocalPlayer
local mouse = player:GetMouse() -- works with mouse clicks AND phone taps
local clickPosition = tool:WaitForChild("ClickPosition")

local equipped = false
local holding = false

local function fire()
	mouse.TargetFilter = player.Character -- do not aim at yourself
	clickPosition:FireServer(mouse.Hit.Position)
end

tool.Equipped:Connect(function()
	equipped = true
end)

tool.Unequipped:Connect(function()
	equipped = false
	holding = false
end)

tool.Activated:Connect(function()
	holding = true
	fire()
	-- Automatic tools (Attribute Automatic = true) keep firing while you hold
	if tool:GetAttribute("Automatic") then
		local rate = tool:GetAttribute("FireRate") or 0.1
		while holding and equipped do
			task.wait(rate)
			if holding and equipped then
				fire()
			end
		end
	end
end)

tool.Deactivated:Connect(function()
	holding = false
end)

-- Press R to reload (only if the tool has a Reload event)
UserInputService.InputBegan:Connect(function(input, typing)
	if typing or not equipped or input.KeyCode ~= Enum.KeyCode.R then
		return
	end
	local reload = tool:FindFirstChild("Reload")
	if reload then
		reload:FireServer()
	end
end)
