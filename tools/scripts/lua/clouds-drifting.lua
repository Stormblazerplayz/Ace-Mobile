-- @title Drifting clouds
-- @category World and effects
-- @kind LocalScript
-- @where Put this LocalScript in StarterPlayer > StarterPlayerScripts.
-- @keywords drifting clouds, moving clouds, fluffy clouds, sky clouds, clouds float by
-- @about Fills the sky with puffy white clouds that slowly float across and wrap around (only on your screen, so it costs the server nothing).

local RunService = game:GetService("RunService")

-- Settings: change these numbers!
local CLOUD_COUNT = 25
local AREA = 1200 -- studs wide the sky area is
local HEIGHT = 250
local WIND = Vector3.new(6, 0, 2) -- direction and speed of the wind

local folder = Instance.new("Folder")
folder.Name = "LocalClouds"
folder.Parent = workspace

local clouds = {}
for _ = 1, CLOUD_COUNT do
	local cloud = Instance.new("Part")
	cloud.Shape = Enum.PartType.Ball
	cloud.Size = Vector3.new(math.random(40, 80), math.random(12, 20), math.random(30, 60))
	cloud.Anchored = true
	cloud.CanCollide = false
	cloud.CanQuery = false
	cloud.CanTouch = false
	cloud.CastShadow = false
	cloud.Material = Enum.Material.SmoothPlastic
	cloud.Color = Color3.new(1, 1, 1)
	cloud.Transparency = 0.15
	cloud.Position = Vector3.new(math.random(-AREA / 2, AREA / 2), HEIGHT + math.random(-20, 20), math.random(-AREA / 2, AREA / 2))
	cloud.Parent = folder
	table.insert(clouds, cloud)
end

RunService.Heartbeat:Connect(function(deltaTime)
	for _, cloud in ipairs(clouds) do
		local p = cloud.Position + WIND * deltaTime
		-- Wrap around to the other side when a cloud floats too far
		if p.X > AREA / 2 then p = p - Vector3.new(AREA, 0, 0) end
		if p.Z > AREA / 2 then p = p - Vector3.new(0, 0, AREA) end
		if p.X < -AREA / 2 then p = p + Vector3.new(AREA, 0, 0) end
		if p.Z < -AREA / 2 then p = p + Vector3.new(0, 0, AREA) end
		cloud.Position = p
	end
end)
