-- @title Egg hatching with rare pets
-- @category Pickups and money
-- @kind Script
-- @where Put this Script inside an Anchored egg Part (works with the Pet that follows you script and a Coins stat).
-- @keywords egg hatch, hatch pets, open an egg, random pet, rare pets chance, pet egg
-- @about Press E on the egg and pay coins to hatch a random pet; rarer pets have a smaller chance.

local Players = game:GetService("Players")

-- Settings: change these! Bigger weight = more common
local PRICE = 100
local PETS = {
	{ name = "Dog", weight = 60 },
	{ name = "Cat", weight = 30 },
	{ name = "Dragon", weight = 9 },
	{ name = "Golden Unicorn", weight = 1 }, -- super rare: 1 in 100
}

local egg = script.Parent
local prompt = Instance.new("ProximityPrompt")
prompt.ActionText = "Hatch (" .. PRICE .. " coins)"
prompt.ObjectText = "Pet Egg"
prompt.HoldDuration = 0.5
prompt.Parent = egg

-- Pick a pet using weights (like putting names in a hat many times)
local function rollPet()
	local total = 0
	for _, pet in ipairs(PETS) do
		total = total + pet.weight
	end
	local roll = math.random() * total
	for _, pet in ipairs(PETS) do
		roll = roll - pet.weight
		if roll <= 0 then
			return pet.name
		end
	end
	return PETS[1].name
end

prompt.Triggered:Connect(function(player)
	local stats = player:FindFirstChild("leaderstats")
	local coins = stats and stats:FindFirstChild("Coins")
	if not coins or coins.Value < PRICE then
		return
	end
	coins.Value = coins.Value - PRICE
	local petName = rollPet()

	-- Keep a list of owned pets in a folder on the player
	local owned = player:FindFirstChild("OwnedPets")
	if not owned then
		owned = Instance.new("Folder")
		owned.Name = "OwnedPets"
		owned.Parent = player
	end
	local entry = Instance.new("StringValue")
	entry.Name = petName
	entry.Value = petName
	entry.Parent = owned

	player:SetAttribute("EquippedPet", petName) -- show it off right away
	player:SetAttribute("LastHatch", petName) -- a GUI can announce this
end)
