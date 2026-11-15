-- @title Hovering part you can push
-- @category Moving parts
-- @kind Script
-- @where Put this Script inside an unanchored Part you want to float in the air.
-- @keywords hover part, floating physics part, push the floating block, levitating part, align position hover
-- @about The part floats in place with physics, so players can bump it around and it drifts back home.

-- Settings: change these numbers!
local HOVER_HEIGHT = 0 -- extra studs above where you placed it
local STRENGTH = 15 -- how fast it gets back home (Responsiveness)
local KEEP_UPRIGHT = true -- stop it tipping over?

local part = script.Parent
part.Anchored = false
local home = part.CFrame + Vector3.new(0, HOVER_HEIGHT, 0)

local attachment = Instance.new("Attachment")
attachment.Parent = part

-- AlignPosition pulls the part toward a spot (OneAttachment means "toward a position")
local align = Instance.new("AlignPosition")
align.Mode = Enum.PositionAlignmentMode.OneAttachment
align.Attachment0 = attachment
align.Position = home.Position
align.Responsiveness = STRENGTH
align.MaxForce = part.AssemblyMass * workspace.Gravity * 5
align.Parent = part

if KEEP_UPRIGHT then
	local orient = Instance.new("AlignOrientation")
	orient.Mode = Enum.OrientationAlignmentMode.OneAttachment
	orient.Attachment0 = attachment
	orient.CFrame = home.Rotation
	orient.Responsiveness = STRENGTH
	orient.Parent = part
end

part:SetNetworkOwner(nil)
