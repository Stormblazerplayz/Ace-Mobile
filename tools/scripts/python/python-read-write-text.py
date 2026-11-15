# @title Read and Write Text Files
# @category Files and data
# @kind Console program
# @where Save as files_demo.py and run: python3 files_demo.py. It makes a file called diary.txt next to it.
# @keywords python read file, python write file, python with open, python append text file
# @about Shows how to write, add to and read back a text file using with open.

from pathlib import Path

path = Path(__file__).with_name("diary.txt")

# "w" means write: it makes a new file (or wipes an old one)
with open(path, "w", encoding="utf-8") as f:
    f.write("Day 1: Started learning Python.\n")
    f.write("Day 2: Made a hangman game!\n")

# "a" means append: add to the end without wiping it
with open(path, "a", encoding="utf-8") as f:
    entry = input("Write a new diary line (or press Enter): ").strip() or "Day 3: Learned about files."
    f.write(entry + "\n")

# "r" means read (it's the default)
with open(path, encoding="utf-8") as f:
    whole = f.read()
print("--- Whole file ---")
print(whole)

# Read line by line
with open(path, encoding="utf-8") as f:
    for number, line in enumerate(f, start=1):
        print(f"line {number}: {line.rstrip()}")

print("The file has", len(whole.splitlines()), "lines and is saved at", path)
