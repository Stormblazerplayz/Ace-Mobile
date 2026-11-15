# @title Pascal's Triangle
# @category Math and school
# @kind Console program
# @where Save as pascal.py and run: python3 pascal.py
# @keywords python pascals triangle, python binomial, python combinations, python math patterns
# @about Builds Pascal's triangle row by row and shows the hidden patterns inside it.

import math

text = input("How many rows? (Enter for 12): ").strip()
rows = int(text) if text.isdigit() and 1 <= int(text) <= 20 else 12

triangle = [[1]]
for _ in range(rows - 1):
    last = triangle[-1]
    # Each number is the sum of the two numbers above it
    middle = [last[i] + last[i + 1] for i in range(len(last) - 1)]
    triangle.append([1] + middle + [1])

width = len("   ".join(map(str, triangle[-1])))
for row in triangle:
    print("   ".join(map(str, row)).center(width))

print("\nPatterns to notice:")
print("Row sums are powers of 2:", [sum(row) for row in triangle[:8]])
print("Row 5 matches math.comb(4, k):", [math.comb(4, k) for k in range(5)])
print("Odd numbers make a Sierpinski triangle:")
for row in triangle[:16]:
    print(" ".join("*" if n % 2 else " " for n in row).center(31))
