-- @title Muffled sound underwater
-- @category Sound
-- @kind LocalScript
-- @where Put this LocalScript in StarterPlayer > StarterPlayerScripts. Works with Terrain water.
-- @keywords underwater sound, muffled audio, water reverb, swimming sound effect, underwater tint
-- @about When your camera goes under terrain water, sounds become muffled and echoey and the screen turns a little blue.

local Lighting = game:GetService("Lighting")
local SoundService = game:GetService("SoundService")
local RunService = game:GetService("RunService")

local camera = workspace.CurrentCamera
local terrain = workspace.Terrain

local normalReverb = SoundService.AmbientReverb
local tint = Instance.new("ColorCorrectionEffect")
tint.TintColor = Color3.fromRGB(150, 200, 255)
tint.Enabled = false
tint.Parent = Lighting

-- Ask the terrain which material is at a point
local function isWater(position)
	local region = Region3.new(position - Vector3.new(2, 2, 2), position + Vector3.new(2, 2, 2)):ExpandToGrid(4)
	local materials = terrain:ReadVoxels(region, 4)
	return materials[1][1][1] == Enum.Material.Water
end

local wasUnder = false
RunService.RenderStepped:Connect(function()
	local under = isWater(camera.CFrame.Position)
	if under ~= wasUnder then
		wasUnder = under
		-- AmbientReverb changes how every sound echoes
		SoundService.AmbientReverb = under and Enum.ReverbType.UnderWater or normalReverb
		tint.Enabled = under
	end
end)
