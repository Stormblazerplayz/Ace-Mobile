-- @title Send players to arena or lobby (module)
-- @category Game rounds
-- @kind ModuleScript
-- @where Put this ModuleScript in ServerScriptService and name it Teleports. Put Parts in a Folder named ArenaSpawns, and one Part named LobbySpawn, in Workspace.
-- @keywords lobby teleport, send to arena, round teleport, spread spawns, teleport module
-- @about Helpers that move a list of players onto different arena spawn spots, and back to the lobby when the round ends.

local Teleports = {}

local function moveTo(player, cframe)
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if root then
		root.AssemblyLinearVelocity = Vector3.zero -- stop falling speed from carrying over
		character:PivotTo(cframe + Vector3.new(0, 4, 0))
		return true
	end
	return false
end

-- ToArena(players) gives each player their own spawn spot (it loops if there are more players than spots)
function Teleports.ToArena(players)
	local folder = workspace:FindFirstChild("ArenaSpawns")
	local spots = folder and folder:GetChildren() or {}
	if #spots == 0 then
		warn("Add Parts to a Folder named ArenaSpawns")
		return {}
	end
	-- Shuffle the spots so nobody always gets the same one
	for i = #spots, 2, -1 do
		local j = math.random(1, i)
		spots[i], spots[j] = spots[j], spots[i]
	end
	local moved = {}
	for i, player in ipairs(players) do
		local spot = spots[(i - 1) % #spots + 1]
		if moveTo(player, spot.CFrame) then
			table.insert(moved, player)
		end
	end
	return moved -- only the players who really got moved
end

-- ToLobby(players) brings them back
function Teleports.ToLobby(players)
	local lobby = workspace:FindFirstChild("LobbySpawn")
	for _, player in ipairs(players) do
		if lobby then
			moveTo(player, lobby.CFrame + Vector3.new(math.random(-5, 5), 0, math.random(-5, 5)))
		else
			player:LoadCharacter()
		end
	end
end

return Teleports
