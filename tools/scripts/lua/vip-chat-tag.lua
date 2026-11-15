-- @title Chat tags and name colors
-- @category Chat and admin
-- @kind LocalScript
-- @where Put this LocalScript in StarterPlayer > StarterPlayerScripts. Server scripts give tags with player:SetAttribute("ChatTag", "VIP"). Only use one script that sets OnIncomingMessage.
-- @keywords chat tag, vip tag in chat, chat prefix, colored names in chat, rank tag
-- @about Adds colored tags like [VIP] or [OWNER] in front of names in the chat, and colors names by team.

local Players = game:GetService("Players")
local TextChatService = game:GetService("TextChatService")

-- Settings: tag name = color (as a hex code)
local TAG_COLORS = {
	OWNER = "#FF4040",
	ADMIN = "#FF8C00",
	VIP = "#FFD700",
	PREMIUM = "#B0B0FF",
}

local function tagFor(player)
	if player.UserId == game.CreatorId then
		return "OWNER"
	end
	local tag = player:GetAttribute("ChatTag")
	if type(tag) == "string" and tag ~= "" then
		return string.upper(tag)
	end
	if player.MembershipType == Enum.MembershipType.Premium then
		return "PREMIUM"
	end
	return nil
end

-- This runs for every message before it shows in the chat window
TextChatService.OnIncomingMessage = function(message)
	local properties = Instance.new("TextChatMessageProperties")
	local source = message.TextSource
	local player = source and Players:GetPlayerByUserId(source.UserId)
	if not player then
		return properties
	end
	local prefix = message.PrefixText
	-- Color the name by team (if they are on one)
	if player.Team then
		prefix = string.format("<font color='#%s'>%s</font>", player.TeamColor.Color:ToHex(), prefix)
	end
	local tag = tagFor(player)
	if tag then
		local color = TAG_COLORS[tag] or "#FFFFFF"
		prefix = string.format("<font color='%s'>[%s]</font> %s", color, tag, prefix)
	end
	properties.PrefixText = prefix
	return properties
end
