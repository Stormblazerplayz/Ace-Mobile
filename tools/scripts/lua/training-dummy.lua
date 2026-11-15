-- @title Training dummy
-- @category NPCs and AI
-- @kind Script
-- @where Put this Script inside a dummy Model with a Humanoid (a Rig from the Rig Builder works; anchor its HumanoidRootPart).
-- @keywords training dummy, practice target, damage test dummy, dps dummy, punching bag
-- @about A dummy that never dies: it shows how much damage it took in the last few seconds, then heals back to full.

local npc = script.Parent
local humanoid = npc:WaitForChild("Humanoid")
local head = npc:WaitForChild("Head")

humanoid.MaxHealth = 1000
humanoid.Health = 1000
humanoid.BreakJointsOnDeath = false
humanoid:SetStateEnabled(Enum.HumanoidStateType.Dead, false) -- it can never die

local billboard = Instance.new("BillboardGui")
billboard.Size = UDim2.fromOffset(160, 40)
billboard.StudsOffset = Vector3.new(0, 2.5, 0)
billboard.Parent = head
local label = Instance.new("TextLabel")
label.Size = UDim2.fromScale(1, 1)
label.BackgroundTransparency = 1
label.Font = Enum.Font.GothamBlack
label.TextScaled = true
label.TextColor3 = Color3.fromRGB(255, 220, 80)
label.TextStrokeTransparency = 0
label.Text = "Hit me!"
label.Parent = billboard

local damageTotal = 0
local lastHit = 0
local lastHealth = humanoid.Health

humanoid.HealthChanged:Connect(function(health)
	if health < lastHealth then
		damageTotal += lastHealth - health
		lastHit = os.clock()
		label.Text = "Damage: " .. math.floor(damageTotal)
	end
	lastHealth = health
	if health < 100 then
		humanoid.Health = humanoid.MaxHealth -- never get too low
		lastHealth = humanoid.MaxHealth
	end
end)

-- After 3 seconds with no hits, reset the counter and heal
while true do
	task.wait(0.5)
	if damageTotal > 0 and os.clock() - lastHit > 3 then
		damageTotal = 0
		label.Text = "Hit me!"
		humanoid.Health = humanoid.MaxHealth
		lastHealth = humanoid.MaxHealth
	end
end
