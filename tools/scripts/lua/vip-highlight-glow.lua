-- @title VIP glow outline
-- @category Players
-- @kind Script
-- @where Put this Script in ServerScriptService and put your VIP game pass id below.
-- @keywords vip glow, highlight player, glowing outline, vip outline, gamepass glow
-- @about Players who own the VIP game pass get a glowing gold outline around their character.

local Players = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")

-- Settings: change these!
local VIP_PASS_ID = 0
local GLOW_COLOR = Color3.fromRGB(255, 200, 0)

local vips = {}

local function addGlow(character)
	if character:FindFirstChild("VIPGlow") then
		return
	end
	local glow = Instance.new("Highlight")
	glow.Name = "VIPGlow"
	glow.FillTransparency = 1 -- only the outline
	glow.OutlineColor = GLOW_COLOR
	glow.DepthMode = Enum.HighlightDepthMode.Occluded -- not visible through walls
	glow.Parent = character
end

Players.PlayerAdded:Connect(function(player)
	local ok, owns = pcall(function()
		return MarketplaceService:UserOwnsGamePassAsync(player.UserId, VIP_PASS_ID)
	end)
	vips[player] = ok and owns
	player.CharacterAdded:Connect(function(character)
		if vips[player] then
			addGlow(character)
		end
	end)
	if vips[player] and player.Character then
		addGlow(player.Character)
	end
end)

MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player, passId, bought)
	if bought and passId == VIP_PASS_ID then
		vips[player] = true
		if player.Character then
			addGlow(player.Character)
		end
	end
end)

Players.PlayerRemoving:Connect(function(player)
	vips[player] = nil
end)
