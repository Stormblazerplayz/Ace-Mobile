# @title Higher or Lower Cards
# @category Games
# @kind Console program
# @where Save as higher_lower.py and run: python3 higher_lower.py
# @keywords python higher or lower, python card guessing, python streak game, python hi lo
# @about Guess if the next card will be higher or lower than the one showing, and build the longest streak.

import random

NAMES = {11: "Jack", 12: "Queen", 13: "King", 14: "Ace"}


def card_name(value):
    return NAMES.get(value, str(value))


deck = [value for value in range(2, 15) for _ in range(4)]  # 4 of each value
random.shuffle(deck)

streak = 0
current = deck.pop()
print("Guess if the next card is higher (h) or lower (l). A tie counts as a free pass!")

while deck:
    print(f"\nCard: {card_name(current)}   Streak: {streak}   Cards left: {len(deck)}")
    guess = input("Higher or lower? (h/l) ").strip().lower()
    if guess not in ("h", "l"):
        print("Type h or l.")
        continue
    nxt = deck.pop()
    print("Next card is", card_name(nxt))
    if nxt == current:
        print("Same card! Free pass.")
    elif (nxt > current) == (guess == "h"):
        streak += 1
        print("Correct!")
    else:
        print(f"Wrong! Your streak was {streak}.")
        break
    current = nxt
else:
    print("You went through the whole deck! Legendary!")
