-- @title Cutscene camera
-- @category Camera
-- @kind LocalScript
-- @where Put this LocalScript in StarterPlayer > StarterPlayerScripts. Make a Folder named CutsceneShots in Workspace with anchored, invisible Parts named 1, 2, 3... facing where the camera should look. A server script replays it with player:SetAttribute("Cutscene", os.clock()).
-- @keywords cutscene, camera tween, intro scene, cinematic camera, camera path
-- @about The camera glides smoothly from shot 1 to shot 2 to shot 3 like a movie, with black bars, then gives control back.

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

-- Settings: change these!
local SECONDS_PER_SHOT = 3
local PLAY_ON_JOIN = true

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera
local shotsFolder = workspace:WaitForChild("CutsceneShots")

-- Black movie bars at the top and bottom
local gui = Instance.new("ScreenGui")
gui.Name = "CutsceneBars"
gui.IgnoreGuiInset = true
gui.ResetOnSpawn = false
gui.Enabled = false
gui.Parent = player:WaitForChild("PlayerGui")
for _, y in ipairs({ 0, 0.88 }) do
	local bar = Instance.new("Frame")
	bar.Position = UDim2.fromScale(0, y)
	bar.Size = UDim2.fromScale(1, 0.12)
	bar.BackgroundColor3 = Color3.new(0, 0, 0)
	bar.BorderSizePixel = 0
	bar.Parent = gui
end

local playing = false
local function play()
	if playing then
		return
	end
	local shots = {}
	for _, part in ipairs(shotsFolder:GetChildren()) do
		if tonumber(part.Name) then
			table.insert(shots, part)
		end
	end
	table.sort(shots, function(a, b)
		return tonumber(a.Name) < tonumber(b.Name)
	end)
	if #shots == 0 then
		return
	end
	playing = true
	gui.Enabled = true
	camera.CameraType = Enum.CameraType.Scriptable
	camera.CFrame = shots[1].CFrame
	for i = 2, #shots do
		local tween = TweenService:Create(camera, TweenInfo.new(SECONDS_PER_SHOT, Enum.EasingStyle.Sine), { CFrame = shots[i].CFrame })
		tween:Play()
		tween.Completed:Wait()
	end
	task.wait(1)
	camera.CameraType = Enum.CameraType.Custom
	gui.Enabled = false
	playing = false
end

player:GetAttributeChangedSignal("Cutscene"):Connect(function()
	if player:GetAttribute("Cutscene") then
		play()
	end
end)
if PLAY_ON_JOIN then
	player.CharacterAdded:Wait()
	task.wait(1)
	play()
end
