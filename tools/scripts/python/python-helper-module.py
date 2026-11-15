# @title Your Own Helper Module
# @category Basics
# @kind Module
# @where Save as helpers.py next to your other programs, then write: import helpers  and use helpers.clamp(5, 0, 3). Run it by itself to see a demo.
# @keywords python module, python import my own file, python if __name__ == __main__, python reusable code
# @about A small module of handy functions you can import into any of your programs.

"""helpers.py: little tools to reuse in other programs."""

import random


def clamp(value, low, high):
    """Keep value between low and high."""
    return max(low, min(high, value))


def ask_number(question, low, high):
    """Keep asking until the user types a whole number in range."""
    while True:
        text = input(question)
        if text.strip().lstrip("-").isdigit():
            number = int(text)
            if low <= number <= high:
                return number
        print(f"Please type a whole number from {low} to {high}.")


def roll(dice=1, sides=6):
    """Roll some dice and return the total."""
    return sum(random.randint(1, sides) for _ in range(dice))


def banner(text):
    """Print text inside a box."""
    line = "+" + "-" * (len(text) + 2) + "+"
    print(line)
    print(f"| {text} |")
    print(line)


# This part only runs when you run helpers.py directly,
# NOT when another file does "import helpers".
if __name__ == "__main__":
    banner("helpers demo")
    print("clamp(15, 0, 10) =", clamp(15, 0, 10))
    print("Rolling 2 dice:", roll(2))
