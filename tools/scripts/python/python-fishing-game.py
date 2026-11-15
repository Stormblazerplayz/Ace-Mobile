# @title Fishing Game
# @category Games
# @kind Console program
# @where Save as fishing.py and run: python3 fishing.py
# @keywords python fishing game, python catch fish, python weighted random, python collection game
# @about Cast your line, wait for a bite, and reel in fish of different rarities to fill your collection.

import random
import time

FISH = [("Old Boot", 0, 20), ("Minnow", 2, 30), ("Bass", 10, 20), ("Salmon", 20, 15),
        ("Golden Trout", 60, 8), ("Legendary Kraken", 250, 2)]
# (name, coins, how common)

coins = 0
caught = {}
print("Press Enter to cast. When you see 'BITE!', press Enter quickly to reel it in. Type q to stop.")

while True:
    if input(f"\nCoins: {coins}. Cast? ").strip().lower() == "q":
        break
    print("Waiting...")
    time.sleep(random.uniform(1, 3))
    start = time.perf_counter()
    input("BITE! Press Enter!")
    if time.perf_counter() - start > 1.5:
        print("Too slow, it got away!")
        continue
    name, value, _ = random.choices(FISH, weights=[f[2] for f in FISH])[0]
    caught[name] = caught.get(name, 0) + 1
    coins += value
    print(f"You caught a {name}! (+{value} coins)")

print("\nYour collection:")
for name, count in caught.items():
    print(f"  {name}: {count}")
print(f"Total coins: {coins}. Species found: {len(caught)}/{len(FISH)}")
