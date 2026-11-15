# @title Collatz Conjecture
# @category Math and school
# @kind Console program
# @where Save as collatz.py and run: python3 collatz.py
# @keywords python collatz, python 3n plus 1, python unsolved math problem, python number sequence
# @about Explores the famous unsolved 3n + 1 puzzle: does every number eventually fall to 1?

def collatz(n):
    steps = [n]
    while n != 1:
        n = n // 2 if n % 2 == 0 else 3 * n + 1  # even: halve it, odd: times 3 plus 1
        steps.append(n)
    return steps


text = input("Pick a starting number (Enter for 27): ").strip()
start = int(text) if text.isdigit() and int(text) > 0 else 27
path = collatz(start)
print(f"{start} reaches 1 in {len(path) - 1} steps, climbing as high as {max(path)}.")
print(" -> ".join(map(str, path[:40])) + (" -> ..." if len(path) > 40 else ""))

# Which number under 10,000 takes the most steps?
best = max(range(1, 10000), key=lambda n: len(collatz(n)))
print(f"\nUnder 10,000 the longest journey starts at {best} ({len(collatz(best)) - 1} steps).")
print("Nobody has ever proved that EVERY number gets to 1. Maybe you will!")
