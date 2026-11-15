# @title Battleship vs the Computer
# @category Games
# @kind Console program
# @where Save as battleship.py and run: python3 battleship.py
# @keywords python battleship, python sink the ships, python grid guessing game, python hit or miss
# @about Find and sink the computer's hidden ships on a grid before you run out of shots.

import random

SIZE = 6
SHIP_LENGTHS = [3, 2, 2]
SHOTS = 20


def place_ships():
    taken = set()
    for length in SHIP_LENGTHS:
        while True:
            across = random.choice([True, False])
            row = random.randrange(SIZE if across else SIZE - length + 1)
            col = random.randrange(SIZE - length + 1 if across else SIZE)
            cells = {(row, col + i) if across else (row + i, col) for i in range(length)}
            if not cells & taken:  # no overlap with other ships
                taken |= cells
                break
    return taken


def draw(hits, misses):
    print("   " + " ".join("ABCDEF"[:SIZE]))
    for r in range(SIZE):
        row = ["X" if (r, c) in hits else "o" if (r, c) in misses else "." for c in range(SIZE)]
        print(f"{r + 1:>2} " + " ".join(row))


ships = place_ships()
hits, misses = set(), set()
print(f"Sink all {len(ships)} ship squares in {SHOTS} shots! Type a spot like B4.")

shots_left = SHOTS
while shots_left > 0 and hits != ships:
    draw(hits, misses)
    spot = input(f"Shots left {shots_left}. Fire at: ").strip().upper()
    if len(spot) < 2 or spot[0] not in "ABCDEF"[:SIZE] or not spot[1:].isdigit() or not 1 <= int(spot[1:]) <= SIZE:
        print("Type a letter and a number, like C3.")
        continue
    target = (int(spot[1:]) - 1, "ABCDEF".index(spot[0]))
    if target in hits or target in misses:
        print("You already fired there.")
        continue
    shots_left -= 1
    if target in ships:
        hits.add(target)
        print("HIT!")
    else:
        misses.add(target)
        print("Splash. Miss.")

draw(hits, misses)
print("You sank the whole fleet!" if hits == ships else "Out of shots. The fleet escapes!")
