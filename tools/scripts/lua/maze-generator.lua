-- @title Random maze generator
-- @category Obstacles
-- @kind Script
-- @where Put this Script in ServerScriptService and add an Anchored Part named MazeCorner in Workspace where the maze should start (its corner).
-- @keywords maze generator, random maze, labyrinth, new maze every time, procedural maze
-- @about Builds a brand new random maze out of wall parts every time the server starts.

-- Settings: change these numbers!
local WIDTH = 12 -- cells across
local HEIGHT = 12 -- cells deep
local CELL = 12 -- studs per cell
local WALL_HEIGHT = 10
local WALL_COLOR = Color3.fromRGB(70, 120, 70)

local corner = workspace:WaitForChild("MazeCorner")
local origin = corner.Position

-- walls[x][y] = {N=true, E=true, S=true, W=true} means that wall is still standing
local walls, visited = {}, {}
for x = 1, WIDTH do
	walls[x], visited[x] = {}, {}
	for y = 1, HEIGHT do
		walls[x][y] = { N = true, E = true, S = true, W = true }
	end
end

local moves = { { 0, -1, "N", "S" }, { 1, 0, "E", "W" }, { 0, 1, "S", "N" }, { -1, 0, "W", "E" } }

-- "Recursive backtracker": walk randomly, knocking down walls, and back up at dead ends
local stack = { { 1, 1 } }
visited[1][1] = true
while #stack > 0 do
	local x, y = stack[#stack][1], stack[#stack][2]
	local options = {}
	for _, m in ipairs(moves) do
		local nx, ny = x + m[1], y + m[2]
		if nx >= 1 and nx <= WIDTH and ny >= 1 and ny <= HEIGHT and not visited[nx][ny] then
			table.insert(options, m)
		end
	end
	if #options == 0 then
		table.remove(stack)
	else
		local m = options[math.random(#options)]
		local nx, ny = x + m[1], y + m[2]
		walls[x][y][m[3]] = false
		walls[nx][ny][m[4]] = false
		visited[nx][ny] = true
		table.insert(stack, { nx, ny })
	end
end

-- Open an entrance and an exit
walls[1][1].W = false
walls[WIDTH][HEIGHT].E = false

-- Build the walls as parts
local model = Instance.new("Model")
model.Name = "Maze"
local function wall(position, size)
	local part = Instance.new("Part")
	part.Anchored = true
	part.Size = size
	part.Position = origin + position + Vector3.new(0, WALL_HEIGHT / 2, 0)
	part.Color = WALL_COLOR
	part.Parent = model
end
for x = 1, WIDTH do
	for y = 1, HEIGHT do
		local cx, cz = (x - 0.5) * CELL, (y - 0.5) * CELL
		local w = walls[x][y]
		if w.N then wall(Vector3.new(cx, 0, cz - CELL / 2), Vector3.new(CELL + 1, WALL_HEIGHT, 1)) end
		if w.W then wall(Vector3.new(cx - CELL / 2, 0, cz), Vector3.new(1, WALL_HEIGHT, CELL + 1)) end
		if y == HEIGHT and w.S then wall(Vector3.new(cx, 0, cz + CELL / 2), Vector3.new(CELL + 1, WALL_HEIGHT, 1)) end
		if x == WIDTH and w.E then wall(Vector3.new(cx + CELL / 2, 0, cz), Vector3.new(1, WALL_HEIGHT, CELL + 1)) end
	end
end
model.Parent = workspace
