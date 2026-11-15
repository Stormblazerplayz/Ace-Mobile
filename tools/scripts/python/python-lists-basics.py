# @title Lists
# @category Basics
# @kind Console program
# @where Save as lists.py and run: python3 lists.py
# @keywords python lists, python append, python list index, python remove from list, python list methods
# @about Makes a list of games and shows how to add, remove, sort and find items in it.

games = ["Minecraft", "Roblox", "Rocket League"]
print("Start:", games)

# Index starts at 0. games[0] is the first item, games[-1] is the last.
print("First game:", games[0])
print("Last game:", games[-1])

games.append("Fortnite")          # add to the end
games.insert(1, "Terraria")       # add at position 1
print("After adding:", games)

games.remove("Roblox")            # remove by value
popped = games.pop()              # remove and return the last item
print("Removed", popped, "->", games)

games.sort()                      # A to Z
print("Sorted:", games)

print("How many games?", len(games))
print("Is Minecraft in the list?", "Minecraft" in games)
print("Where is Terraria?", games.index("Terraria"))

# Slicing: [start:stop] gives a smaller list
numbers = [10, 20, 30, 40, 50, 60]
print("First three:", numbers[:3])
print("Middle:", numbers[2:4])
print("Every other one:", numbers[::2])
print("Backwards:", numbers[::-1])
print("Biggest:", max(numbers), "Smallest:", min(numbers), "Sum:", sum(numbers))
