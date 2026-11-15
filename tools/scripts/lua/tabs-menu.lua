-- @title Menu with tabs
-- @category GUI
-- @kind LocalScript
-- @where Put this LocalScript inside a Frame. Inside the same Frame add a Frame named Tabs with TextButtons, and a Frame named Pages with Frames that have the same names as the buttons.
-- @keywords tabs menu, tab buttons, switch pages, menu sections, tabbed window
-- @about Clicking a tab button shows the page with the same name and hides the others.

local menu = script.Parent
local tabs = menu:WaitForChild("Tabs")
local pages = menu:WaitForChild("Pages")

local ON_COLOR = Color3.fromRGB(80, 150, 240)
local OFF_COLOR = Color3.fromRGB(60, 60, 70)

local function showPage(name)
	for _, page in ipairs(pages:GetChildren()) do
		if page:IsA("GuiObject") then
			page.Visible = page.Name == name
		end
	end
	for _, button in ipairs(tabs:GetChildren()) do
		if button:IsA("GuiButton") then
			button.BackgroundColor3 = button.Name == name and ON_COLOR or OFF_COLOR
		end
	end
end

local first = nil
for _, button in ipairs(tabs:GetChildren()) do
	if button:IsA("GuiButton") then
		first = first or button.Name
		button.Activated:Connect(function()
			showPage(button.Name)
		end)
	end
end

-- Start on the first tab
if first then
	showPage(first)
end
