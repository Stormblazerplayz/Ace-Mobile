# @title Nested Loops: Star Patterns
# @category Basics
# @kind Console program
# @where Save as stars.py and run: python3 stars.py
# @keywords python nested loops, python star pattern, python pyramid, python diamond shape
# @about Uses loops inside loops to print triangles, a pyramid and a diamond out of stars.

size = 5

print("Right triangle:")
for row in range(1, size + 1):
    print("*" * row)

print("\nPyramid:")
for row in range(1, size + 1):
    spaces = " " * (size - row)
    stars = "*" * (2 * row - 1)
    print(spaces + stars)

print("\nDiamond:")
for row in list(range(1, size + 1)) + list(range(size - 1, 0, -1)):
    print(" " * (size - row) + "*" * (2 * row - 1))

print("\nNumber square (a loop inside a loop):")
for row in range(1, 5):
    line = ""
    for col in range(1, 5):
        line += f"{row * col:4}"
    print(line)

print("\nCheckerboard:")
for row in range(6):
    print("".join("#" if (row + col) % 2 == 0 else "." for col in range(12)))
