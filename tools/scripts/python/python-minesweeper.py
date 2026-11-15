# @title Minesweeper
# @category Games
# @kind Console program
# @where Save as minesweeper.py and run: python3 minesweeper.py
# @keywords python minesweeper, python mines grid, python flood fill reveal, python puzzle game
# @about Reveal every safe square without stepping on a mine, using the number clues.

import random

SIZE, MINES = 8, 10
mines = set(random.sample([(r, c) for r in range(SIZE) for c in range(SIZE)], MINES))
opened = set()
flags = set()


def neighbors(r, c):
    for dr in (-1, 0, 1):
        for dc in (-1, 0, 1):
            nr, nc = r + dr, c + dc
            if (dr or dc) and 0 <= nr < SIZE and 0 <= nc < SIZE:
                yield nr, nc


def count(r, c):
    return sum((n in mines) for n in neighbors(r, c))


def reveal(r, c):
    """Open a square. If it has 0 mines around it, open its neighbors too (flood fill)."""
    stack = [(r, c)]
    while stack:
        cell = stack.pop()
        if cell in opened:
            continue
        opened.add(cell)
        if count(*cell) == 0:
            stack.extend(n for n in neighbors(*cell) if n not in opened)


def draw(show_mines=False):
    print("   " + " ".join(str(c + 1) for c in range(SIZE)))
    for r in range(SIZE):
        row = []
        for c in range(SIZE):
            if show_mines and (r, c) in mines:
                row.append("*")
            elif (r, c) in opened:
                row.append(str(count(r, c)) if count(r, c) else " ")
            elif (r, c) in flags:
                row.append("F")
            else:
                row.append("#")
        print(f"{r + 1:>2} " + " ".join(row))


print("Type 'row col' to open (like 3 5), or 'f row col' to flag a mine.")
while True:
    draw()
    parts = input("> ").strip().lower().split()
    flag = parts[:1] == ["f"]
    nums = parts[1:] if flag else parts
    if len(nums) != 2 or not all(p.isdigit() and 1 <= int(p) <= SIZE for p in nums):
        print("Type two numbers from 1 to", SIZE)
        continue
    cell = (int(nums[0]) - 1, int(nums[1]) - 1)
    if flag:
        flags ^= {cell}  # toggle the flag on or off
    elif cell in mines:
        draw(show_mines=True)
        print("BOOM! You hit a mine.")
        break
    else:
        reveal(*cell)
        if len(opened) == SIZE * SIZE - MINES:
            draw(show_mines=True)
            print("You cleared the field! You win!")
            break
