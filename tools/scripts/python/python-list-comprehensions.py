# @title List Comprehensions
# @category Basics
# @kind Console program
# @where Save as comprehensions.py and run: python3 comprehensions.py
# @keywords python list comprehension, python one line loop, python filter list, python dict comprehension
# @about Shows the short one-line way to build lists and dictionaries from loops.

# The long way:
squares = []
for n in range(1, 11):
    squares.append(n * n)
print("Long way:", squares)

# The short way with a list comprehension: [what for item in things]
squares = [n * n for n in range(1, 11)]
print("Short way:", squares)

# Add an if to filter: only keep some items
evens = [n for n in range(20) if n % 2 == 0]
print("Evens:", evens)

words = ["apple", "Banana", "cherry", "Dragonfruit", "fig"]
long_words = [w.upper() for w in words if len(w) > 5]
print("Long words shouted:", long_words)

# Dictionary comprehension: {key: value for item in things}
lengths = {w: len(w) for w in words}
print("Word lengths:", lengths)

# Set comprehension removes duplicates
letters = {ch for ch in "hello world" if ch != " "}
print("Unique letters:", sorted(letters))

# Nested: a small multiplication grid
grid = [[row * col for col in range(1, 5)] for row in range(1, 5)]
for row in grid:
    print(row)
