# @title War Card Game
# @category Games
# @kind Console program
# @where Save as war.py and run: python3 war.py
# @keywords python war card game, python card battle, python deck split, python automatic card game
# @about Plays the card game War between you and the computer; higher card wins both cards.

import random
from collections import deque

deck = [value for value in range(2, 15) for _ in range(4)]
random.shuffle(deck)
you = deque(deck[:26])
cpu = deque(deck[26:])
NAMES = {11: "J", 12: "Q", 13: "K", 14: "A"}


def name(v):
    return NAMES.get(v, str(v))


rounds = 0
while you and cpu and rounds < 300:
    rounds += 1
    pile = [you.popleft(), cpu.popleft()]
    a, b = pile
    line = f"Round {rounds}: you {name(a):>2} vs {name(b):>2}"
    # WAR! On a tie, each puts down 3 more cards and the next ones fight
    while a == b:
        line += "  WAR!"
        if len(you) < 4 or len(cpu) < 4:
            break
        pile += [you.popleft() for _ in range(3)] + [cpu.popleft() for _ in range(3)]
        a, b = you.popleft(), cpu.popleft()
        pile += [a, b]
    random.shuffle(pile)
    if a > b:
        you.extend(pile)
        line += "  you win the pile"
    elif b > a:
        cpu.extend(pile)
        line += "  computer wins the pile"
    else:
        # Someone ran out of cards during a war, so share the pile back out
        you.extend(pile[::2])
        cpu.extend(pile[1::2])
    print(line + f"   (you {len(you)}, cpu {len(cpu)})")

print()
if len(you) > len(cpu):
    print(f"You win with {len(you)} cards!")
elif len(cpu) > len(you):
    print(f"The computer wins with {len(cpu)} cards.")
else:
    print("It's a tie!")
