-- @title NPC waves hello
-- @category NPCs and AI
-- @kind Script
-- @where Put this Script inside an R15 NPC Model (made with the Rig Builder).
-- @keywords npc wave, greeting npc, say hello, welcome npc, friendly villager
-- @about When a player walks up, the NPC turns toward them, waves, and shows "Hello, Name!" above its head.

local Players = game:GetService("Players")
local Debris = game:GetService("Debris")

-- Settings: change these!
local GREET_RANGE = 15
local GREET_AGAIN_AFTER = 30 -- seconds before greeting the same player again

local npc = script.Parent
local humanoid = npc:WaitForChild("Humanoid")
local root = npc:WaitForChild("HumanoidRootPart")
local head = npc:WaitForChild("Head")

local animator = humanoid:FindFirstChildOfClass("Animator") or Instance.new("Animator")
animator.Parent = humanoid
local wave = Instance.new("Animation")
wave.AnimationId = "rbxassetid://507770239" -- Roblox's own R15 wave emote
local waveTrack = animator:LoadAnimation(wave)

local greeted = {}

local function sayHello(player)
	local bubble = Instance.new("BillboardGui")
	bubble.Size = UDim2.fromOffset(200, 40)
	bubble.StudsOffset = Vector3.new(0, 2.5, 0)
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundColor3 = Color3.new(1, 1, 1)
	label.TextScaled = true
	label.Font = Enum.Font.GothamMedium
	label.Text = "Hello, " .. player.DisplayName .. "!"
	label.Parent = bubble
	bubble.Parent = head
	Debris:AddItem(bubble, 3)
end

while true do
	task.wait(0.5)
	for _, player in ipairs(Players:GetPlayers()) do
		local theirRoot = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
		if theirRoot and (theirRoot.Position - root.Position).Magnitude < GREET_RANGE then
			if os.clock() - (greeted[player] or -999) > GREET_AGAIN_AFTER then
				greeted[player] = os.clock()
				-- Turn to face them (only spin around, do not tip over)
				local facing = Vector3.new(theirRoot.Position.X, root.Position.Y, theirRoot.Position.Z)
				npc:PivotTo(CFrame.lookAt(root.Position, facing))
				waveTrack:Play()
				sayHello(player)
			end
		end
	end
end
