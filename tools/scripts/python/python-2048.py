# @title 2048
# @category Games
# @kind Console program
# @where Save as game2048.py and run: python3 game2048.py
# @keywords python 2048, python sliding tiles, python merge numbers game, python 2048 console
# @about Slide the tiles with W A S D so matching numbers merge, and try to reach 2048.

import random

SIZE = 4
grid = [[0] * SIZE for _ in range(SIZE)]


def add_tile():
    empty = [(r, c) for r in range(SIZE) for c in range(SIZE) if grid[r][c] == 0]
    if empty:
        r, c = random.choice(empty)
        grid[r][c] = 4 if random.random() < 0.1 else 2


def slide_row_left(row):
    """Slide one row to the left and merge pairs. Returns the new row and points scored."""
    tiles = [n for n in row if n]
    merged, points, i = [], 0, 0
    while i < len(tiles):
        if i + 1 < len(tiles) and tiles[i] == tiles[i + 1]:
            merged.append(tiles[i] * 2)
            points += tiles[i] * 2
            i += 2
        else:
            merged.append(tiles[i])
            i += 1
    return merged + [0] * (SIZE - len(merged)), points


def move(direction):
    """Every direction is 'left' after flipping or turning the grid."""
    global grid
    rotated = grid
    turns = {"a": 0, "w": 1, "d": 2, "s": 3}[direction]
    for _ in range(turns):  # turn the grid counter-clockwise
        rotated = [list(row) for row in zip(*rotated)][::-1]
    results = [slide_row_left(row) for row in rotated]
    new = [row for row, _ in results]
    for _ in range((4 - turns) % 4):  # turn it back
        new = [list(row) for row in zip(*new)][::-1]
    changed = new != grid
    grid = new
    return changed, sum(p for _, p in results)


def can_move():
    for r in range(SIZE):
        for c in range(SIZE):
            if grid[r][c] == 0:
                return True
            if c + 1 < SIZE and grid[r][c] == grid[r][c + 1]:
                return True
            if r + 1 < SIZE and grid[r][c] == grid[r + 1][c]:
                return True
    return False


score = 0
add_tile()
add_tile()
while True:
    print(f"\nScore: {score}")
    for row in grid:
        print("".join(f"{n or '.':>6}" for n in row))
    if any(2048 in row for row in grid):
        print("You made 2048! You win!")
        break
    if not can_move():
        print("No moves left. Game over!")
        break
    key = input("Move with w/a/s/d (q to quit): ").strip().lower()
    if key == "q":
        break
    if key in ("w", "a", "s", "d"):
        changed, points = move(key)
        if changed:
            score += points
            add_tile()
