-- @title AFK tag (server part)
-- @category Players
-- @kind Script
-- @where Put this Script in ServerScriptService and add the AFK detector (client part) LocalScript too.
-- @keywords afk tag, show afk above head, afk sign, idle players, afk label
-- @about Shows a floating AFK sign above players who are away and saves it as an AFK attribute other scripts can check.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- The client uses this RemoteEvent to tell us about AFK
local setAfk = ReplicatedStorage:FindFirstChild("SetAFK") or Instance.new("RemoteEvent")
setAfk.Name = "SetAFK"
setAfk.Parent = ReplicatedStorage

local function updateSign(player)
	local character = player.Character
	local head = character and character:FindFirstChild("Head")
	if not head then
		return
	end
	local sign = head:FindFirstChild("AFKSign")
	if player:GetAttribute("AFK") and not sign then
		sign = Instance.new("BillboardGui")
		sign.Name = "AFKSign"
		sign.Size = UDim2.fromOffset(80, 30)
		sign.StudsOffset = Vector3.new(0, 3.5, 0)
		local label = Instance.new("TextLabel")
		label.Size = UDim2.fromScale(1, 1)
		label.BackgroundTransparency = 1
		label.Text = "AFK"
		label.TextScaled = true
		label.Font = Enum.Font.GothamBlack
		label.TextColor3 = Color3.fromRGB(255, 220, 80)
		label.Parent = sign
		sign.Parent = head
	elseif not player:GetAttribute("AFK") and sign then
		sign:Destroy()
	end
end

setAfk.OnServerEvent:Connect(function(player, afk)
	if typeof(afk) ~= "boolean" then
		return -- ignore weird data
	end
	player:SetAttribute("AFK", afk)
	updateSign(player)
end)

Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(function(character)
		character:WaitForChild("Head")
		updateSign(player)
	end)
end)
