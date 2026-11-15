-- @title See your body in first person
-- @category Camera
-- @kind LocalScript
-- @where Put this LocalScript in StarterPlayer > StarterCharacterScripts.
-- @keywords first person body, see your arms, visible legs, body in first person, look down see feet
-- @about In first person you normally become invisible; this keeps your arms, legs and body visible (but hides your head and hats so they do not block the view).

local RunService = game:GetService("RunService")

local character = script.Parent
local humanoid = character:WaitForChild("Humanoid")

-- Parts we keep hidden: the head and anything attached to it (hats, hair, face)
local function isHeadStuff(part)
	if part.Name == "Head" then
		return true
	end
	local accessory = part:FindFirstAncestorOfClass("Accessory")
	if accessory then
		local handle = accessory:FindFirstChild("Handle")
		local weld = handle and handle:FindFirstChildWhichIsA("Weld")
		return weld ~= nil and weld.Part1 ~= nil and weld.Part1.Name == "Head"
	end
	return false
end

local connection
connection = RunService.RenderStepped:Connect(function()
	if humanoid.Health <= 0 then
		connection:Disconnect()
		return
	end
	for _, part in ipairs(character:GetDescendants()) do
		if part:IsA("BasePart") and not isHeadStuff(part) then
			-- Roblox sets this to 1 in first person; setting it back to 0 shows the part
			part.LocalTransparencyModifier = 0
		end
	end
end)
