# @title Nim: Last Stick Loses
# @category Games
# @kind Console program
# @where Save as nim.py and run: python3 nim.py
# @keywords python nim game, python take away sticks, python strategy game, python smart computer player
# @about Take 1 to 3 sticks each turn against a sneaky computer; whoever takes the last stick loses.

import random

sticks = random.randint(15, 25)
print(f"There are {sticks} sticks. Take 1, 2 or 3 each turn. Whoever takes the LAST stick loses!")

player_turn = True
while sticks > 0:
    print("\n" + "| " * sticks + f"({sticks} left)")
    if player_turn:
        text = input("How many do you take? ").strip()
        if not text.isdigit() or not 1 <= int(text) <= min(3, sticks):
            print("You can take 1, 2 or 3 (and not more than are left).")
            continue
        take = int(text)
    else:
        # The trick: leave a number that is 1 more than a multiple of 4.
        take = (sticks - 1) % 4
        if take == 0:
            take = random.randint(1, min(3, sticks))  # no winning move, so just pick something
        print(f"The computer takes {take}.")
    sticks -= take
    if sticks == 0:
        print("You took the last stick. You lose!" if player_turn else "The computer took the last stick. You win!")
    player_turn = not player_turn
