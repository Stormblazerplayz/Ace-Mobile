-- @title Quest giver NPC
-- @category NPCs and AI
-- @kind Script
-- @where Put this Script inside an NPC Model with a HumanoidRootPart. Tag the things to collect with the tag QuestItem (Tags in the Properties window). Use the Quest tracker GUI to show progress.
-- @keywords quest giver, fetch quest, collect quest, quest npc, mission reward npc
-- @about Talk to the NPC to get a quest to collect items; touch the items to collect them, then come back to the NPC for a coin reward.

local Players = game:GetService("Players")
local CollectionService = game:GetService("CollectionService")

-- Settings: change these!
local QUEST_NAME = "Collect lost apples"
local GOAL = 5
local REWARD = 150

local npc = script.Parent
local root = npc:WaitForChild("HumanoidRootPart")

local prompt = Instance.new("ProximityPrompt")
prompt.ActionText = "Quest"
prompt.ObjectText = npc.Name
prompt.Parent = root

prompt.Triggered:Connect(function(player)
	local current = player:GetAttribute("QuestName")
	if current == QUEST_NAME then
		local progress = player:GetAttribute("QuestProgress") or 0
		if progress >= GOAL then
			-- Quest done: give the reward and clear it
			local coins = player:FindFirstChild("leaderstats") and player.leaderstats:FindFirstChild("Coins")
			if coins then
				coins.Value += REWARD
			end
			player:SetAttribute("QuestName", "")
			player:SetAttribute("QuestsDone", (player:GetAttribute("QuestsDone") or 0) + 1)
			player:SetAttribute("Notice", "Quest complete! +" .. REWARD .. " coins")
		else
			player:SetAttribute("Notice", "Find " .. (GOAL - progress) .. " more!")
		end
	elseif not current or current == "" then
		player:SetAttribute("QuestName", QUEST_NAME)
		player:SetAttribute("QuestProgress", 0)
		player:SetAttribute("QuestGoal", GOAL)
		player:SetAttribute("Notice", "New quest: " .. QUEST_NAME)
	else
		player:SetAttribute("Notice", "Finish your other quest first!")
	end
end)

-- Collecting quest items (each player can collect each item once)
local function setupItem(item)
	if not item:IsA("BasePart") then
		return
	end
	local collectedBy = {}
	item.Touched:Connect(function(hit)
		local player = Players:GetPlayerFromCharacter(hit.Parent)
		if not player or collectedBy[player] or player:GetAttribute("QuestName") ~= QUEST_NAME then
			return
		end
		local progress = player:GetAttribute("QuestProgress") or 0
		if progress < GOAL then
			collectedBy[player] = true
			player:SetAttribute("QuestProgress", progress + 1)
		end
	end)
end
for _, item in ipairs(CollectionService:GetTagged("QuestItem")) do
	setupItem(item)
end
CollectionService:GetInstanceAddedSignal("QuestItem"):Connect(setupItem)
