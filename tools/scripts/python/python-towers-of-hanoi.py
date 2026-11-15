# @title Towers of Hanoi
# @category Basics
# @kind Console program
# @where Save as hanoi.py and run: python3 hanoi.py
# @keywords python towers of hanoi, python recursion puzzle, python hanoi solver, python recursive moves
# @about Solves the Towers of Hanoi puzzle with recursion and prints every move.

moves = []


def hanoi(disks, start, helper, goal):
    """Move a pile of disks from start to goal, using helper as the spare peg."""
    if disks == 0:
        return
    hanoi(disks - 1, start, goal, helper)   # 1. move the smaller pile out of the way
    moves.append((disks, start, goal))      # 2. move the biggest disk
    hanoi(disks - 1, helper, start, goal)   # 3. put the smaller pile back on top


text = input("How many disks (1 to 10)? ").strip()
count = int(text) if text.isdigit() and 1 <= int(text) <= 10 else 3

hanoi(count, "A", "B", "C")
for number, (disk, start, goal) in enumerate(moves, start=1):
    print(f"Move {number}: disk {disk} from {start} to {goal}")

print(f"\nSolved {count} disks in {len(moves)} moves. The fewest possible is 2^{count} - 1 = {2 ** count - 1}.")
