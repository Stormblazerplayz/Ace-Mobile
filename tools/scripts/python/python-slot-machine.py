# @title Slot Machine
# @category Games
# @kind Console program
# @where Save as slots.py and run: python3 slots.py
# @keywords python slot machine, python spinning reels, python fake coins game, python jackpot
# @about Spin three reels with pretend coins and win prizes for matching symbols (no real money!).

import random
import time

SYMBOLS = ["CHERRY", "LEMON", "BELL", "STAR", "SEVEN"]
WEIGHTS = [35, 30, 20, 10, 5]          # cherries are common, sevens are rare
PAYOUT = {"CHERRY": 5, "LEMON": 8, "BELL": 15, "STAR": 30, "SEVEN": 100}

coins = 50
print("Each spin costs 5 pretend coins. Three of a kind wins big! Two cherries win 3.")
while coins >= 5:
    if input(f"\nCoins: {coins}. Press Enter to spin (q to quit) ").strip().lower() == "q":
        break
    coins -= 5
    reels = random.choices(SYMBOLS, weights=WEIGHTS, k=3)
    for i in range(3):  # reveal one reel at a time for suspense
        time.sleep(0.5)
        print(f"[ {reels[i]:^6} ]", end=" ", flush=True)
    print()
    if reels[0] == reels[1] == reels[2]:
        win = PAYOUT[reels[0]]
        print(f"THREE {reels[0]}S! You win {win} coins!")
        coins += win
    elif reels.count("CHERRY") == 2:
        print("Two cherries! You win 3 coins.")
        coins += 3
    else:
        print("No luck this time.")

print(f"\nYou finish with {coins} coins.")
