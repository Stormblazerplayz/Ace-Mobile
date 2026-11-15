-- @title Tween sequence (module)
-- @category Moving parts
-- @kind ModuleScript
-- @where Put this ModuleScript in ReplicatedStorage and name it TweenSequence, then require it from any Script.
-- @keywords tween sequence, chain tweens, animation steps, tween one after another, tween list module
-- @about Plays a list of tweens on a part one after another, and can loop them, so you can make little animations easily.

--[[ How to use it from a Script inside a Part:
	local TweenSequence = require(game.ReplicatedStorage.TweenSequence)
	local part = script.Parent
	TweenSequence.play(part, {
		{ time = 1, goal = { Position = part.Position + Vector3.new(0, 5, 0) } },
		{ time = 0.5, goal = { Color = Color3.new(1, 0, 0) }, waitAfter = 1 },
		{ time = 1, goal = { Position = part.Position, Color = part.Color } },
	}, true) -- true = loop forever
]]

local TweenService = game:GetService("TweenService")

local TweenSequence = {}

-- steps: a list of { time = seconds, goal = {Property = value}, style = Enum.EasingStyle (optional), waitAfter = seconds (optional) }
-- loop: true to repeat forever. Returns a function you can call to stop it.
function TweenSequence.play(instance, steps, loop)
	local running = true
	local current

	task.spawn(function()
		repeat
			for _, step in ipairs(steps) do
				if not running or not instance.Parent then
					return
				end
				local info = TweenInfo.new(step.time or 1, step.style or Enum.EasingStyle.Quad)
				current = TweenService:Create(instance, info, step.goal)
				current:Play()
				current.Completed:Wait()
				if step.waitAfter then
					task.wait(step.waitAfter)
				end
			end
		until not loop or not running
	end)

	return function()
		running = false
		if current then
			current:Cancel()
		end
	end
end

return TweenSequence
