-- @title Sit down anywhere
-- @category Players
-- @kind LocalScript
-- @where Put this LocalScript in StarterPlayer > StarterCharacterScripts.
-- @keywords sit down key, sit anywhere, press x to sit, sit on the ground, take a seat
-- @about Press X (or the Sit button on phones) to sit down on the ground; jump to stand up.

local ContextActionService = game:GetService("ContextActionService")

local character = script.Parent
local humanoid = character:WaitForChild("Humanoid")

local function toggleSit(_, state)
	if state ~= Enum.UserInputState.Begin then
		return Enum.ContextActionResult.Pass
	end
	if humanoid.Sit then
		humanoid.Sit = false
		humanoid.Jump = true -- hop back up
	elseif humanoid.FloorMaterial ~= Enum.Material.Air then
		humanoid.Sit = true -- only sit when standing on something
	end
	return Enum.ContextActionResult.Sink
end

ContextActionService:BindAction("SitDown", toggleSit, true, Enum.KeyCode.X)
ContextActionService:SetTitle("SitDown", "Sit")

humanoid.Died:Connect(function()
	ContextActionService:UnbindAction("SitDown")
end)
