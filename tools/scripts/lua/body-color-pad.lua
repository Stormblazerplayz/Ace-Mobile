-- @title Paint your body pad
-- @category Players
-- @kind Script
-- @where Put this Script inside an Anchored Part; the part's own Color is the paint color.
-- @keywords body color pad, paint character, change skin color, color your avatar, paint pad
-- @about Stepping on the pad paints your whole body the same color as the pad.

local Players = game:GetService("Players")

-- Settings: change this!
local ALSO_HIDE_CLOTHES = true -- take off shirt and pants so the color shows

local pad = script.Parent

pad.Touched:Connect(function(hit)
	local character = hit.Parent
	if not Players:GetPlayerFromCharacter(character) then
		return
	end
	-- BodyColors controls the color of every body part
	local colors = character:FindFirstChildOfClass("BodyColors") or Instance.new("BodyColors")
	colors.HeadColor3 = pad.Color
	colors.TorsoColor3 = pad.Color
	colors.LeftArmColor3 = pad.Color
	colors.RightArmColor3 = pad.Color
	colors.LeftLegColor3 = pad.Color
	colors.RightLegColor3 = pad.Color
	colors.Parent = character

	if ALSO_HIDE_CLOTHES then
		for _, item in ipairs(character:GetChildren()) do
			if item:IsA("Shirt") or item:IsA("Pants") or item:IsA("ShirtGraphic") then
				item:Destroy()
			end
		end
	end
end)
