# @title Maze Walker
# @category Games
# @kind Console program
# @where Save as maze.py and run: python3 maze.py
# @keywords python maze game, python move with wasd, python grid map, python escape the maze
# @about Walk through a text maze with W A S D, grab the key and reach the exit.

MAZE = [
    "##########",
    "#P   #   #",
    "# ## # # #",
    "#  #   # #",
    "## ##### #",
    "#    K#  #",
    "# ###### #",
    "#       E#",
    "##########",
]

grid = [list(row) for row in MAZE]
# Find where the player starts
row, col = next((r, c) for r, line in enumerate(grid) for c, ch in enumerate(line) if ch == "P")
has_key = False
moves = 0
STEPS = {"w": (-1, 0), "s": (1, 0), "a": (0, -1), "d": (0, 1)}

print("Get the key (K), then reach the exit (E). Move with w/a/s/d.")
while True:
    print()
    for line in grid:
        print(" ".join(line))
    key = input(f"Moves: {moves}. Key: {'yes' if has_key else 'no'}. Move: ").strip().lower()
    if key not in STEPS:
        continue
    dr, dc = STEPS[key]
    target = grid[row + dr][col + dc]
    if target == "#":
        print("Bonk! A wall.")
        continue
    if target == "E" and not has_key:
        print("The exit is locked. Find the key first!")
        continue
    if target == "K":
        has_key = True
        print("You found the key!")
    grid[row][col] = " "
    row, col = row + dr, col + dc
    moves += 1
    if target == "E":
        print(f"You escaped in {moves} moves!")
        break
    grid[row][col] = "P"
