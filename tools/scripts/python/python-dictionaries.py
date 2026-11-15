# @title Dictionaries
# @category Basics
# @kind Console program
# @where Save as dicts.py and run: python3 dicts.py
# @keywords python dictionary, python dict, python key value, python dict loop, python get method
# @about Stores a player's stats in a dictionary and shows how to read, change and loop over keys and values.

# A dictionary maps keys to values, like a word to its meaning.
player = {
    "name": "Storm",
    "level": 7,
    "coins": 150,
    "items": ["sword", "shield"],
}

print("Name:", player["name"])
print("Coins:", player["coins"])

# Change and add values
player["coins"] += 50
player["health"] = 100
print("After the quest:", player)

# get() is safe: it gives a default instead of crashing when a key is missing
print("Mana:", player.get("mana", 0))

# Loop over keys and values
for key, value in player.items():
    print(f"  {key}: {value}")

# Remove a key
del player["health"]
print("Keys left:", list(player.keys()))

# Count letters with a dictionary
word = "mississippi"
counts = {}
for letter in word:
    counts[letter] = counts.get(letter, 0) + 1
print("Letter counts in", word, "->", counts)
