# @title Simon Says Memory
# @category Games
# @kind Console program
# @where Save as simon.py and run: python3 simon.py
# @keywords python simon says, python memory sequence game, python remember colors, python clear screen
# @about Remember a growing list of colors, type it back, and see how long a sequence you can handle.

import os
import random
import time

COLORS = {"r": "RED", "g": "GREEN", "b": "BLUE", "y": "YELLOW"}


def clear():
    # Clear the screen so the player can't just read the old sequence
    os.system("cls" if os.name == "nt" else "clear")


sequence = []
print("Watch the colors, then type their first letters (like rgby).")
input("Press Enter to start...")

while True:
    sequence.append(random.choice(list(COLORS)))
    clear()
    print(f"Round {len(sequence)}. Watch!")
    time.sleep(1)
    for letter in sequence:
        print("   ", COLORS[letter])
        time.sleep(0.8)
        clear()
        time.sleep(0.2)
    answer = input("Your turn: ").strip().lower().replace(" ", "")
    if answer != "".join(sequence):
        print("Wrong! The sequence was:", " ".join(COLORS[c] for c in sequence))
        print(f"You remembered {len(sequence) - 1} colors.")
        break
    print("Correct!")
    time.sleep(0.8)
