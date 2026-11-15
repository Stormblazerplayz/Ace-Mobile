-- @title Pet that follows you
-- @category Pickups and money
-- @kind Script
-- @where Put this Script in ServerScriptService; optional: put pet Models in a Folder named Pets in ServerStorage and set a player's EquippedPet attribute to a pet's name.
-- @keywords pet follow, pet that follows you, pet system, floating pet, companion pet
-- @about Gives every player a little pet that floats next to them and follows them everywhere.

local Players = game:GetService("Players")
local ServerStorage = game:GetService("ServerStorage")

-- Settings: change these!
local OFFSET = Vector3.new(3, 1, 3) -- right, up, back from the player
local DEFAULT_PET_COLOR = Color3.fromRGB(255, 170, 0)

local petsFolder = ServerStorage:FindFirstChild("Pets")

-- Make the pet: a model from ServerStorage.Pets, or a glowing ball if there is none
local function makePet(petName)
	local template = petsFolder and petName and petsFolder:FindFirstChild(petName)
	if template and template:IsA("Model") and template.PrimaryPart then
		local pet = template:Clone()
		return pet, pet.PrimaryPart
	end
	local ball = Instance.new("Part")
	ball.Shape = Enum.PartType.Ball
	ball.Size = Vector3.new(1.5, 1.5, 1.5)
	ball.Material = Enum.Material.Neon
	ball.Color = DEFAULT_PET_COLOR
	return ball, ball
end

local function givePet(player, character)
	local root = character:WaitForChild("HumanoidRootPart")
	local pet, main = makePet(player:GetAttribute("EquippedPet"))
	pet.Name = "Pet"
	for _, part in ipairs(pet:IsA("BasePart") and { pet } or pet:GetDescendants()) do
		if part:IsA("BasePart") then
			part.Anchored = false
			part.CanCollide = false
			part.Massless = true
		end
	end
	main.CFrame = root.CFrame * CFrame.new(OFFSET)

	-- The pet chases an attachment that sits beside the player
	local target = Instance.new("Attachment")
	target.Name = "PetSpot"
	target.Position = OFFSET
	target.Parent = root
	local petAttachment = Instance.new("Attachment")
	petAttachment.Parent = main

	local align = Instance.new("AlignPosition")
	align.Attachment0 = petAttachment
	align.Attachment1 = target
	align.Responsiveness = 15
	align.MaxForce = math.huge
	align.Parent = main
	local turn = Instance.new("AlignOrientation")
	turn.Attachment0 = petAttachment
	turn.Attachment1 = target
	turn.Responsiveness = 15
	turn.Parent = main

	pet.Parent = character
	main:SetNetworkOwner(player) -- smooth movement for the owner
end

Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(function(character)
		givePet(player, character)
	end)
	-- Changing the equipped pet swaps it straight away
	player:GetAttributeChangedSignal("EquippedPet"):Connect(function()
		local character = player.Character
		if character and character:FindFirstChild("HumanoidRootPart") then
			local old = character:FindFirstChild("Pet")
			if old then
				old:Destroy()
			end
			local spot = character.HumanoidRootPart:FindFirstChild("PetSpot")
			if spot then
				spot:Destroy()
			end
			givePet(player, character)
		end
	end)
end)
