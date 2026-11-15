-- @title Keypad code door (server part)
-- @category Doors and buttons
-- @kind Script
-- @where Put this Script inside a Model with two Anchored Parts named Door and Keypad, and also add the Keypad code door (screen part) LocalScript.
-- @keywords keypad door, secret code door, password door, enter a code, pin code lock
-- @about Players type a code on the keypad; only the right code opens the door, and the code stays secret on the server.

-- Settings: change these!
local CODE = "1234" -- the secret code (players never see this)
local OPEN_TIME = 5

local model = script.Parent
local door = model:WaitForChild("Door")
local keypad = model:WaitForChild("Keypad")

-- The prompt the screen part listens for
local prompt = Instance.new("ProximityPrompt")
prompt.Name = "KeypadPrompt"
prompt.ActionText = "Enter code"
prompt.ObjectText = "Keypad"
prompt.Parent = keypad

-- The screen part sends the typed code here
local submit = Instance.new("RemoteFunction")
submit.Name = "SubmitCode"
submit.Parent = model

local lastTry = {}
local opening = false

submit.OnServerInvoke = function(player, typed)
	if typeof(typed) ~= "string" then
		return false
	end
	-- Only 1 try every 2 seconds so nobody can guess super fast
	if os.clock() - (lastTry[player] or 0) < 2 then
		return false
	end
	lastTry[player] = os.clock()
	-- Must be standing near the keypad
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	if not root or (root.Position - keypad.Position).Magnitude > 15 then
		return false
	end
	if typed ~= CODE then
		return false
	end
	if not opening then
		opening = true
		task.spawn(function()
			door.Transparency = 0.8
			door.CanCollide = false
			task.wait(OPEN_TIME)
			door.Transparency = 0
			door.CanCollide = true
			opening = false
		end)
	end
	return true
end
