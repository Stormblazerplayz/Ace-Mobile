-- @title Stop chat spam
-- @category Chat and admin
-- @kind Script
-- @where Put this Script in ServerScriptService.
-- @keywords anti spam, chat spam, slow mode, too many messages, spam filter
-- @about If someone sends too many chat messages too fast, their extra messages are not delivered and they get a "slow down" note.

local Players = game:GetService("Players")
local TextChatService = game:GetService("TextChatService")

-- Settings: change these!
local MAX_MESSAGES = 5 -- at most this many...
local PER_SECONDS = 6 -- ...in this many seconds

local recent = {} -- recent[userId] = list of times they sent messages
local checked = {} -- checked[messageId] = true (deliver) or false (block)

local function allowed(userId)
	local now = os.clock()
	local times = recent[userId] or {}
	-- Forget messages older than the time window
	local kept = {}
	for _, t in ipairs(times) do
		if now - t < PER_SECONDS then
			table.insert(kept, t)
		end
	end
	if #kept >= MAX_MESSAGES then
		recent[userId] = kept
		return false
	end
	table.insert(kept, now)
	recent[userId] = kept
	return true
end

local function protect(channel)
	-- ShouldDeliverCallback decides if a message goes out (runs on the server)
	channel.ShouldDeliverCallback = function(message, targetSource)
		local sender = message.TextSource
		if not sender then
			return true
		end
		-- This runs once per person receiving it, so only count the first one
		local id = message.MessageId
		if checked[id] == nil then
			local ok = allowed(sender.UserId)
			checked[id] = ok
			task.delay(10, function()
				checked[id] = nil -- forget old messages
			end)
			if not ok then
				local player = Players:GetPlayerByUserId(sender.UserId)
				if player then
					player:SetAttribute("Notice", "Slow down! Too many messages.")
				end
			end
		end
		return checked[id]
	end
end

local channels = TextChatService:WaitForChild("TextChannels")
for _, channel in ipairs(channels:GetChildren()) do
	if channel:IsA("TextChannel") then
		protect(channel)
	end
end
channels.ChildAdded:Connect(function(channel)
	if channel:IsA("TextChannel") then
		protect(channel)
	end
end)
Players.PlayerRemoving:Connect(function(player)
	recent[player.UserId] = nil
end)
