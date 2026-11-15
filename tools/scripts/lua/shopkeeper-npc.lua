-- @title Shopkeeper NPC
-- @category NPCs and AI
-- @kind Script
-- @where Put this Script inside a shopkeeper NPC Model with a HumanoidRootPart, and put the Tool for sale in ServerStorage (name it in ITEM_NAME).
-- @keywords shopkeeper, npc shop, buy from npc, merchant, trader npc
-- @about Walk up to the shopkeeper and hold E to buy their item for coins; they say thanks or tell you that you need more money.

local Players = game:GetService("Players")
local ServerStorage = game:GetService("ServerStorage")
local Debris = game:GetService("Debris")

-- Settings: change these!
local ITEM_NAME = "Sword"
local PRICE = 75

local npc = script.Parent
local root = npc:WaitForChild("HumanoidRootPart")
local head = npc:FindFirstChild("Head") or root

local prompt = Instance.new("ProximityPrompt")
prompt.ActionText = "Buy " .. ITEM_NAME .. " (" .. PRICE .. " coins)"
prompt.ObjectText = "Shopkeeper"
prompt.HoldDuration = 0.5
prompt.Parent = root

local function say(text)
	-- A speech bubble over the shopkeeper's head (a BillboardGui everyone can see)
	local old = head:FindFirstChild("SpeechBubble")
	if old then
		old:Destroy()
	end
	local bubble = Instance.new("BillboardGui")
	bubble.Name = "SpeechBubble"
	bubble.Size = UDim2.fromOffset(220, 50)
	bubble.StudsOffset = Vector3.new(0, 3, 0)
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundColor3 = Color3.new(1, 1, 1)
	label.TextScaled = true
	label.Font = Enum.Font.GothamMedium
	label.Text = text
	label.Parent = bubble
	bubble.Parent = head
	Debris:AddItem(bubble, 3)
end

prompt.Triggered:Connect(function(player)
	local item = ServerStorage:FindFirstChild(ITEM_NAME)
	local stats = player:FindFirstChild("leaderstats")
	local coins = stats and stats:FindFirstChild("Coins")
	if not item or not coins then
		return
	end
	local backpack = player:FindFirstChildOfClass("Backpack")
	if (backpack and backpack:FindFirstChild(ITEM_NAME)) or (player.Character and player.Character:FindFirstChild(ITEM_NAME)) then
		say("You already have one, friend!")
		return
	end
	if coins.Value < PRICE then
		say("You need " .. (PRICE - coins.Value) .. " more coins!")
		return
	end
	coins.Value -= PRICE
	item:Clone().Parent = backpack
	say("Thanks for shopping, " .. player.DisplayName .. "!")
end)
