-- @title Talk to an NPC
-- @category NPCs and AI
-- @kind Script
-- @where Put this Script inside an NPC Model with a HumanoidRootPart. It uses the Dialog box with typing text LocalScript to show the words.
-- @keywords talk to npc, npc dialogue, speak prompt, npc conversation, chat with npc
-- @about Adds a "Talk" prompt to the NPC; pressing it shows the NPC's lines in a typing dialog box on that player's screen.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Settings: change what the NPC says!
local LINES = {
	"Hello, traveler! Welcome to our village.",
	"The cave to the north is full of treasure...",
	"...but watch out for the monsters inside!",
}

local npc = script.Parent
local root = npc:WaitForChild("HumanoidRootPart")

-- The dialog LocalScript listens to this RemoteEvent
local showDialog = ReplicatedStorage:FindFirstChild("ShowDialog") or Instance.new("RemoteEvent")
showDialog.Name = "ShowDialog"
showDialog.Parent = ReplicatedStorage

local prompt = Instance.new("ProximityPrompt")
prompt.ActionText = "Talk"
prompt.ObjectText = npc.Name
prompt.MaxActivationDistance = 10
prompt.RequiresLineOfSight = false
prompt.Parent = root

prompt.Triggered:Connect(function(player)
	-- Turn the NPC to face the player (only around the up axis)
	local character = player.Character
	local theirRoot = character and character:FindFirstChild("HumanoidRootPart")
	if theirRoot and root.Anchored then
		local look = Vector3.new(theirRoot.Position.X, root.Position.Y, theirRoot.Position.Z)
		root.CFrame = CFrame.lookAt(root.Position, look)
	end
	showDialog:FireClient(player, npc.Name, LINES)
end)
