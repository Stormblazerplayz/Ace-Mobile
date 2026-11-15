-- @title Custom chat bubble style
-- @category Chat and admin
-- @kind LocalScript
-- @where Put this LocalScript in StarterPlayer > StarterPlayerScripts and change the colors below.
-- @keywords bubble chat style, chat bubble color, speech bubble look, custom bubbles, bubble font
-- @about Changes how chat bubbles over players' heads look: colors, font, size and how long they stay.

local TextChatService = game:GetService("TextChatService")

local bubbles = TextChatService:WaitForChild("BubbleChatConfiguration")

-- Settings: change these!
bubbles.BackgroundColor3 = Color3.fromRGB(30, 30, 45)
bubbles.BackgroundTransparency = 0.1
bubbles.TextColor3 = Color3.fromRGB(255, 255, 255)
bubbles.TextSize = 18
bubbles.FontFace = Font.fromEnum(Enum.Font.GothamBold)
bubbles.BubbleDuration = 12 -- seconds a bubble stays
bubbles.MaxDistance = 80 -- further than this, bubbles hide
bubbles.TailVisible = true

-- Rounded corners and a gradient make bubbles look fancy
local corner = bubbles:FindFirstChildOfClass("UICorner") or Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 12)
corner.Parent = bubbles

local gradient = bubbles:FindFirstChildOfClass("UIGradient") or Instance.new("UIGradient")
gradient.Color = ColorSequence.new(Color3.fromRGB(80, 80, 140), Color3.fromRGB(40, 40, 70))
gradient.Rotation = 90
gradient.Parent = bubbles
