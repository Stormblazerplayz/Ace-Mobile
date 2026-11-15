# @title Stopwatch with Laps
# @category Tools
# @kind Console program
# @where Save as stopwatch.py and run: python3 stopwatch.py
# @keywords python stopwatch, python lap timer, python time perf_counter, python split times
# @about A stopwatch where pressing Enter records a lap, and typing q stops it and shows all your laps.

import time


def fmt(seconds):
    minutes, secs = divmod(seconds, 60)
    return f"{int(minutes):02d}:{secs:06.3f}"


input("Press Enter to start the stopwatch...")
start = time.perf_counter()
last = start
laps = []
print("Running! Press Enter for a lap, or type q and Enter to stop.")

while True:
    command = input().strip().lower()
    now = time.perf_counter()
    laps.append(now - last)
    print(f"Lap {len(laps)}: {fmt(laps[-1])}   total {fmt(now - start)}")
    last = now
    if command == "q":
        break

print("\n=== Results ===")
print("Total time:", fmt(time.perf_counter() - start))
if len(laps) > 1:
    best = min(range(len(laps)), key=lambda i: laps[i])
    print(f"Fastest lap: lap {best + 1} ({fmt(laps[best])})")
    print(f"Average lap: {fmt(sum(laps) / len(laps))}")
