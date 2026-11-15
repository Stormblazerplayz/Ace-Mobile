-- @title Tween a whole model (module)
-- @category Moving parts
-- @kind ModuleScript
-- @where Put this ModuleScript in ReplicatedStorage and name it ModelTween, then require it from any Script.
-- @keywords tween a model, move a whole model, model tween module, pivotto tween, smooth model movement
-- @about Lets you smoothly move or turn a whole Model with TweenService, which normally only works on single parts.

--[[ How to use it from a Script:
	local ModelTween = require(game.ReplicatedStorage.ModelTween)
	local door = workspace.BigDoor -- any Model
	local goal = door:GetPivot() * CFrame.new(0, 10, 0) -- 10 studs up
	ModelTween.tween(door, goal, TweenInfo.new(2)):Completed:Wait()
]]

local TweenService = game:GetService("TweenService")

local ModelTween = {}

-- Moves `model` to `goalCFrame` using `tweenInfo`. Returns the Tween so you can wait for it.
function ModelTween.tween(model, goalCFrame, tweenInfo)
	-- Trick: tween a CFrameValue, and every time it changes, move the model there with PivotTo
	local value = Instance.new("CFrameValue")
	value.Value = model:GetPivot()

	local connection = value.Changed:Connect(function(newCFrame)
		model:PivotTo(newCFrame)
	end)

	local tween = TweenService:Create(value, tweenInfo, { Value = goalCFrame })
	tween.Completed:Once(function()
		connection:Disconnect()
		value:Destroy()
	end)
	tween:Play()
	return tween
end

-- Handy extra: move the model by an offset, like ModelTween.moveBy(model, Vector3.new(0, 5, 0), 1)
function ModelTween.moveBy(model, offset, seconds)
	return ModelTween.tween(model, model:GetPivot() + offset, TweenInfo.new(seconds or 1, Enum.EasingStyle.Quad))
end

return ModelTween
