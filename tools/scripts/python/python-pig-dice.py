# @title Pig Dice Game
# @category Games
# @kind Console program
# @where Save as pig.py and run: python3 pig.py
# @keywords python pig dice game, python push your luck, python dice vs computer, python roll or hold
# @about Roll as many times as you dare to build points, but roll a 1 and you lose the whole turn. First to 50 wins.

import random

GOAL = 50
scores = {"You": 0, "Computer": 0}


def take_turn(name):
    turn_total = 0
    while True:
        roll = random.randint(1, 6)
        print(f"  {name} rolled a {roll}")
        if roll == 1:
            print(f"  Oink! {name} loses this turn's points.")
            return 0
        turn_total += roll
        if scores[name] + turn_total >= GOAL:
            return turn_total
        if name == "You":
            choice = input(f"  Turn total {turn_total}. Roll again or hold? (r/h) ").strip().lower()
            if choice == "h":
                return turn_total
        elif turn_total >= 15:  # the computer holds at 15
            print(f"  Computer holds with {turn_total}.")
            return turn_total


while max(scores.values()) < GOAL:
    for name in scores:
        print(f"\n{name}'s turn. Scores: {scores}")
        scores[name] += take_turn(name)
        if scores[name] >= GOAL:
            print(f"\n{name} reached {scores[name]} and WINS!")
            break
