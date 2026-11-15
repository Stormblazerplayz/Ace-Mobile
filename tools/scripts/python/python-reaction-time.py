# @title Reaction Time Test
# @category Games
# @kind Console program
# @where Save as reaction.py and run: python3 reaction.py
# @keywords python reaction time, python reflex test, python perf_counter, python press enter fast
# @about Waits a random time then says GO; press Enter as fast as you can to measure your reflexes.

import random
import time

results = []
print("When you see GO!, press Enter as fast as you can. 5 rounds.")
for round_number in range(1, 6):
    input(f"\nRound {round_number}: press Enter to get ready...")
    print("Wait for it...")
    time.sleep(random.uniform(1.5, 4.0))
    start = time.perf_counter()
    input("GO!")
    seconds = time.perf_counter() - start
    if seconds < 0.08:
        print("Too fast! Did you press early? That round doesn't count.")
        continue
    results.append(seconds)
    print(f"{seconds * 1000:.0f} milliseconds")

if results:
    average = sum(results) / len(results)
    print(f"\nBest: {min(results) * 1000:.0f} ms   Average: {average * 1000:.0f} ms")
    if average < 0.25:
        print("Lightning reflexes!")
    elif average < 0.35:
        print("Nice and quick.")
    else:
        print("Keep practicing!")
