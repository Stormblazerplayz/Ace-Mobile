-- @title /help lists all commands
-- @category Chat and admin
-- @kind LocalScript
-- @where Put this LocalScript in StarterPlayer > StarterPlayerScripts. It finds every chat command your scripts made.
-- @keywords help command, list commands, command list, what commands are there, slash help
-- @about Typing /help shows a list of every chat command in your game (only you see it).

local TextChatService = game:GetService("TextChatService")

local general = TextChatService:WaitForChild("TextChannels"):WaitForChild("RBXGeneral")

-- Commands made by this LocalScript only run on your own computer
local help = Instance.new("TextChatCommand")
help.Name = "HelpCommand"
help.PrimaryAlias = "/help"
help.SecondaryAlias = "/commands"
help.Parent = TextChatService

help.Triggered:Connect(function()
	local names = {}
	for _, object in ipairs(TextChatService:GetDescendants()) do
		if object:IsA("TextChatCommand") and object.Enabled and object.PrimaryAlias ~= "" then
			if not table.find(names, object.PrimaryAlias) then
				table.insert(names, object.PrimaryAlias)
			end
		end
	end
	table.sort(names)
	general:DisplaySystemMessage("<font color='#FFD966'>Commands: " .. table.concat(names, ", ") .. "</font>")
end)
