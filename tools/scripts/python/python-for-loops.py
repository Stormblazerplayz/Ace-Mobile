# @title For Loops
# @category Basics
# @kind Console program
# @where Save as for_loops.py and run: python3 for_loops.py
# @keywords python for loop, python range, python loop through list, python repeat code
# @about Shows how a for loop repeats code over numbers, lists and the letters of a word.

# range(5) gives 0, 1, 2, 3, 4 (it stops BEFORE 5).
print("Counting with range(5):")
for i in range(5):
    print(" ", i)

# range(start, stop, step)
print("Even numbers from 2 to 10:")
for n in range(2, 11, 2):
    print(" ", n)

# Loop through a list
snacks = ["pizza", "tacos", "popcorn", "apples"]
print("My snacks:")
for snack in snacks:
    print("  I like", snack)

# Loop through letters in a word
word = "python"
print("Spelling", word + ":")
for letter in word:
    print(" ", letter.upper())

# Add up numbers with a loop
total = 0
for n in range(1, 101):
    total += n
print("1 + 2 + ... + 100 =", total)

# break stops the loop early, continue skips to the next round
for n in range(1, 20):
    if n % 3 == 0:
        continue  # skip numbers divisible by 3
    if n > 10:
        break     # stop after 10
    print("Not a multiple of 3:", n)
