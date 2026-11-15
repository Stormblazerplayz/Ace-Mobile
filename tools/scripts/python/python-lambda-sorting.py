# @title Lambda and Sorting by Key
# @category Basics
# @kind Console program
# @where Save as lambda_sort.py and run: python3 lambda_sort.py
# @keywords python lambda, python sort by key, python sorted function, python sort list of dicts
# @about Uses tiny lambda functions to sort players by score, name length and more.

players = [
    {"name": "Storm", "score": 980, "level": 12},
    {"name": "Doodle", "score": 1200, "level": 10},
    {"name": "Ace", "score": 750, "level": 15},
    {"name": "Nova", "score": 1200, "level": 8},
]

# A lambda is a tiny function with no name: lambda input: answer
double = lambda n: n * 2  # noqa: E731 (just for showing how it works)
print("double(21) =", double(21))

# sorted() can take key= to decide what to sort by
by_score = sorted(players, key=lambda p: p["score"], reverse=True)
print("Leaderboard:")
for rank, p in enumerate(by_score, start=1):
    print(f"  {rank}. {p['name']} - {p['score']}")

# Sort by two things: score high to low, then name A to Z for ties
tie_break = sorted(players, key=lambda p: (-p["score"], p["name"]))
print("With tie break:", [p["name"] for p in tie_break])

words = ["banana", "kiwi", "apple", "watermelon", "fig"]
print("By length:", sorted(words, key=len))
print("By last letter:", sorted(words, key=lambda w: w[-1]))

# max and min take key= too
best = max(players, key=lambda p: p["level"])
print("Highest level:", best["name"])

# filter and map with lambdas
high = list(filter(lambda p: p["score"] >= 1000, players))
names = list(map(lambda p: p["name"].upper(), high))
print("1000+ club:", names)
