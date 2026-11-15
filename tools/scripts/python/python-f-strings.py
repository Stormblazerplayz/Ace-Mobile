# @title F-Strings and Formatting
# @category Basics
# @kind Console program
# @where Save as fstrings.py and run: python3 fstrings.py
# @keywords python f-string, python format numbers, python decimal places, python string formatting
# @about Shows how to put variables into text with f-strings and make numbers look neat.

name = "Storm"
coins = 1234567
price = 4.5
ratio = 0.8765

# Put any variable or math inside {} in an f-string.
print(f"{name} has {coins} coins.")
print(f"Next year {name} will be {12 + 1}.")

# Number formatting goes after a colon.
print(f"With commas: {coins:,}")
print(f"Two decimals: ${price:.2f}")
print(f"As a percent: {ratio:.1%}")

# Padding and lining up text in columns
items = [("Sword", 50), ("Potion", 5), ("Dragon Egg", 9999)]
print(f"{'Item':<12}{'Price':>8}")
for item, cost in items:
    print(f"{item:<12}{cost:>8}")

# Zero padding, great for clocks
minutes, seconds = 3, 7
print(f"Timer: {minutes:02d}:{seconds:02d}")

# The = trick shows the name and value (handy for debugging)
level = 9
print(f"{level=}")
