# @title Enumerate and Zip
# @category Basics
# @kind Console program
# @where Save as enumerate_zip.py and run: python3 enumerate_zip.py
# @keywords python enumerate, python zip, python loop with index, python pair lists
# @about Shows two handy loop helpers: enumerate for counting and zip for walking through lists side by side.

fruits = ["apple", "banana", "cherry"]

# enumerate gives you the position AND the item
for index, fruit in enumerate(fruits):
    print(index, fruit)

# start=1 makes a nicer numbered list
for number, fruit in enumerate(fruits, start=1):
    print(f"{number}. {fruit}")

# zip pairs up items from two (or more) lists
names = ["Storm", "Doodle", "Nova"]
scores = [88, 95, 72]
for name, score in zip(names, scores):
    print(f"{name} scored {score}")

# zip can build a dictionary
score_book = dict(zip(names, scores))
print("Score book:", score_book)

# zip three lists at once
emojis = ["lightning", "pencil", "star"]
for name, score, emoji in zip(names, scores, emojis):
    print(f"{name:<8}{score:>4}  ({emoji})")

# Both together: find which position has the top score
best_index = 0
for i, score in enumerate(scores):
    if score > scores[best_index]:
        best_index = i
print("Winner:", names[best_index])
