-- @title Changing seasons
-- @category World and effects
-- @kind Script
-- @where Put this Script in ServerScriptService; parts tagged Leaves (Tag Editor) change color with the seasons too.
-- @keywords seasons, spring summer autumn winter, season changer, fall leaves, changing seasons
-- @about Cycles through spring, summer, autumn and winter, changing grass, leaves and light colors each season.

local CollectionService = game:GetService("CollectionService")
local Lighting = game:GetService("Lighting")

-- Settings: how long each season lasts and its colors
local SEASON_LENGTH = 300 -- seconds
local SEASONS = {
	{ name = "Spring", grass = Color3.fromRGB(110, 200, 90), leaves = Color3.fromRGB(120, 210, 110), ambient = Color3.fromRGB(140, 140, 140) },
	{ name = "Summer", grass = Color3.fromRGB(90, 170, 60), leaves = Color3.fromRGB(60, 150, 50), ambient = Color3.fromRGB(160, 150, 130) },
	{ name = "Autumn", grass = Color3.fromRGB(170, 150, 70), leaves = Color3.fromRGB(220, 120, 40), ambient = Color3.fromRGB(150, 120, 100) },
	{ name = "Winter", grass = Color3.fromRGB(230, 235, 240), leaves = Color3.fromRGB(240, 245, 250), ambient = Color3.fromRGB(150, 160, 180) },
}

local terrain = workspace.Terrain

while true do
	for _, season in ipairs(SEASONS) do
		workspace:SetAttribute("Season", season.name) -- other scripts can read this
		-- Terrain grass and leaf colors change for the whole map
		terrain:SetMaterialColor(Enum.Material.Grass, season.grass)
		terrain:SetMaterialColor(Enum.Material.LeafyGrass, season.grass)
		for _, part in ipairs(CollectionService:GetTagged("Leaves")) do
			if part:IsA("BasePart") then
				part.Color = season.leaves
			end
		end
		Lighting.OutdoorAmbient = season.ambient
		-- Snow falls in winter if you have the Snow script
		if season.name == "Winter" then
			workspace:SetAttribute("Weather", "Snow")
		elseif workspace:GetAttribute("Weather") == "Snow" then
			workspace:SetAttribute("Weather", "Clear")
		end
		task.wait(SEASON_LENGTH)
	end
end
