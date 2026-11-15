-- @title Tips in chat every few minutes
-- @category Chat and admin
-- @kind LocalScript
-- @where Put this LocalScript in StarterPlayer > StarterPlayerScripts and write your own tips in TIPS.
-- @keywords chat tips, auto messages, hint every few minutes, reminder in chat, rotating tips
-- @about Every few minutes the chat shows a helpful tip, going through your list in order.

local TextChatService = game:GetService("TextChatService")

-- Settings: change these!
local TIPS = {
	"Tip: Rebirth to earn coins faster!",
	"Tip: Invite friends for a bonus.",
	"Tip: Hold Shift to sprint.",
	"Tip: Like the game if you are having fun!",
}
local EVERY = 180 -- seconds between tips

local general = TextChatService:WaitForChild("TextChannels"):WaitForChild("RBXGeneral")

local index = 1
while true do
	task.wait(EVERY)
	general:DisplaySystemMessage("<font color='#7FD4FF'>" .. TIPS[index] .. "</font>")
	index = index % #TIPS + 1
end
