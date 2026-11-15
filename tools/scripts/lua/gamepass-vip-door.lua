-- @title VIP game pass door
-- @category Doors and buttons
-- @kind Script
-- @where Put this Script inside the Anchored door Part and put your game pass id below.
-- @keywords vip door, gamepass door, game pass only room, buy vip to enter, vip area
-- @about Only players who own the VIP game pass can walk through; everyone else gets asked to buy it.

local Players = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")

-- Settings: change this!
local GAME_PASS_ID = 0

local door = script.Parent
door.Anchored = true
door.CanCollide = true
local owners = {}
local cooldown = {}

local function ownsPass(player)
	if owners[player] == nil then
		local ok, owns = pcall(function()
			return MarketplaceService:UserOwnsGamePassAsync(player.UserId, GAME_PASS_ID)
		end)
		owners[player] = ok and owns
	end
	return owners[player]
end

-- Move the player to the other side of the door
local function passThrough(root)
	local side = door.CFrame:PointToObjectSpace(root.Position).Z
	local distance = door.Size.Z / 2 + 3
	local target = door.CFrame * CFrame.new(0, 0, side > 0 and -distance or distance)
	root.Parent:PivotTo(CFrame.new(target.Position) * root.CFrame.Rotation)
end

door.Touched:Connect(function(hit)
	local character = hit.Parent
	local player = Players:GetPlayerFromCharacter(character)
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not player or not root or cooldown[player] then
		return
	end
	cooldown[player] = true
	if ownsPass(player) then
		passThrough(root)
	else
		MarketplaceService:PromptGamePassPurchase(player, GAME_PASS_ID)
	end
	task.wait(2)
	cooldown[player] = nil
end)

MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player, passId, bought)
	if bought and passId == GAME_PASS_ID then
		owners[player] = true
	end
end)

Players.PlayerRemoving:Connect(function(player)
	owners[player] = nil
	cooldown[player] = nil
end)
