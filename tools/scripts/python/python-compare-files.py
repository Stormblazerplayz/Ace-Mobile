# @title Compare Two Text Files
# @category Files and data
# @kind Console program
# @where Save as compare.py and run: python3 compare.py, then type two file paths (or press Enter for a built-in example).
# @keywords python compare files, python difflib, python find differences, python diff text
# @about Shows exactly which lines changed between two versions of a text file, like a mini git diff.

import difflib
from pathlib import Path

OLD = """def greet(name):
    print("Hello " + name)

greet("Storm")
""".splitlines()

NEW = """def greet(name, excited=False):
    message = f"Hello {name}"
    print(message + ("!" if excited else ""))

greet("Storm", excited=True)
""".splitlines()

first = input("First (old) file (Enter for an example): ").strip()
if first:
    second = input("Second (new) file: ").strip()
    OLD = Path(first).expanduser().read_text(encoding="utf-8").splitlines()
    NEW = Path(second).expanduser().read_text(encoding="utf-8").splitlines()

# Lines starting with - were removed, + were added
for line in difflib.unified_diff(OLD, NEW, fromfile="old", tofile="new", lineterm=""):
    print(line)

similarity = difflib.SequenceMatcher(None, "\n".join(OLD), "\n".join(NEW)).ratio()
print(f"\nThe files are {similarity:.0%} similar.")
