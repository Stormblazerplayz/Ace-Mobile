-- @title NPCs say random lines
-- @category NPCs and AI
-- @kind LocalScript
-- @where Put this LocalScript in StarterPlayer > StarterPlayerScripts. Put NPC Models in a Folder named NPCs in Workspace, and give each a text Attribute named Lines with sentences split by | (like "Hi!|Nice day!").
-- @keywords npc chat bubbles, npc says things, random npc lines, speech bubbles npc, display bubble
-- @about When you walk near an NPC, it says one of its lines in a chat bubble above its head.

local Players = game:GetService("Players")
local TextChatService = game:GetService("TextChatService")

-- Settings: change these!
local TALK_RANGE = 20
local TALK_EVERY = 6 -- seconds between lines for each NPC

local player = Players.LocalPlayer
local npcFolder = workspace:WaitForChild("NPCs")
local lastTalk = {}

local function linesFor(npc)
	local text = npc:GetAttribute("Lines")
	local lines = {}
	if type(text) == "string" then
		for line in string.gmatch(text, "[^|]+") do
			table.insert(lines, line)
		end
	end
	return lines
end

while true do
	task.wait(1)
	local myRoot = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	if myRoot then
		for _, npc in ipairs(npcFolder:GetChildren()) do
			local head = npc:FindFirstChild("Head")
			local lines = linesFor(npc)
			if head and #lines > 0 and (head.Position - myRoot.Position).Magnitude < TALK_RANGE then
				if os.clock() - (lastTalk[npc] or 0) > TALK_EVERY then
					lastTalk[npc] = os.clock()
					-- DisplayBubble shows a bubble only on this player's screen
					TextChatService:DisplayBubble(head, lines[math.random(1, #lines)])
				end
			end
		end
	end
end
