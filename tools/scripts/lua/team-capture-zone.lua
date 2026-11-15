-- @title Team capture point
-- @category Teams
-- @kind Script
-- @where Put this Script inside an anchored, see-through Part that marks the capture area (CanCollide off). Make a few of them for a domination game!
-- @keywords team capture area, domination, control point, team zone capture, flag point
-- @about Standing in the zone slowly captures it for your team (it changes to your color), and the owning team earns a point every few seconds.

local Players = game:GetService("Players")

-- Settings: change these!
local CAPTURE_TIME = 8 -- seconds for one player to capture
local POINT_EVERY = 5 -- seconds between points for the owner

local zone = script.Parent
local owner = nil -- the Team that owns it now
local progress = 0 -- 0 to 1
local capturingTeam = nil
local pointTimer = 0

local params = OverlapParams.new()

local function teamsInZone()
	local counts = {}
	for _, part in ipairs(workspace:GetPartsInPart(zone, params)) do
		local player = Players:GetPlayerFromCharacter(part.Parent)
		local humanoid = part.Parent:FindFirstChildOfClass("Humanoid")
		if player and player.Team and humanoid and humanoid.Health > 0 and part.Name == "HumanoidRootPart" then
			counts[player.Team] = (counts[player.Team] or 0) + 1
		end
	end
	return counts
end

while true do
	task.wait(0.5)
	local counts = teamsInZone()
	local present = {}
	for team in pairs(counts) do
		table.insert(present, team)
	end
	if #present == 1 and present[1] ~= owner then
		-- Only one team here and it is not the owner: capture!
		local team = present[1]
		if capturingTeam ~= team then
			capturingTeam, progress = team, 0
		end
		progress += 0.5 * counts[team] / CAPTURE_TIME -- more players capture faster
		zone.Color = owner and owner.TeamColor.Color:Lerp(team.TeamColor.Color, progress) or Color3.new(1, 1, 1):Lerp(team.TeamColor.Color, progress)
		if progress >= 1 then
			owner, capturingTeam, progress = team, nil, 0
			zone.Color = team.TeamColor.Color
			for _, player in ipairs(Players:GetPlayers()) do
				player:SetAttribute("Notice", team.Name .. " captured " .. zone.Name .. "!")
			end
		end
	elseif #present == 0 then
		capturingTeam, progress = nil, 0
		zone.Color = owner and owner.TeamColor.Color or Color3.new(1, 1, 1)
	end
	-- The owner earns points
	if owner then
		pointTimer += 0.5
		if pointTimer >= POINT_EVERY then
			pointTimer = 0
			owner:SetAttribute("Score", (owner:GetAttribute("Score") or 0) + 1)
		end
	end
end
