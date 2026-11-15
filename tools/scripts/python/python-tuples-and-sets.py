# @title Tuples and Sets
# @category Basics
# @kind Console program
# @where Save as tuples_sets.py and run: python3 tuples_sets.py
# @keywords python tuple, python set, python unpacking, python union intersection, python remove duplicates
# @about Explains tuples (lists you can't change) and sets (collections with no duplicates).

# A tuple uses () and can't be changed after it's made. Great for coordinates.
point = (3, 7)
x, y = point  # "unpacking" puts each value in its own variable
print("x is", x, "and y is", y)

# Functions can return several values as a tuple
def min_and_max(numbers):
    return min(numbers), max(numbers)

low, high = min_and_max([4, 9, 1, 7])
print("Lowest:", low, "Highest:", high)

# Swap two variables in one line using tuples
a, b = 1, 2
a, b = b, a
print("After swap: a =", a, "b =", b)

# A set uses {} and never has duplicates.
colors = {"red", "blue", "red", "green", "blue"}
print("Set of colors:", sorted(colors))

numbers = [1, 2, 2, 3, 3, 3, 4]
print("Without duplicates:", sorted(set(numbers)))

my_games = {"Minecraft", "Roblox", "Terraria"}
friend_games = {"Roblox", "Fortnite", "Minecraft"}
print("Both of us play:", my_games & friend_games)          # intersection
print("All games:", my_games | friend_games)                # union
print("Only I play:", my_games - friend_games)               # difference
print("Is Roblox in my games?", "Roblox" in my_games)
