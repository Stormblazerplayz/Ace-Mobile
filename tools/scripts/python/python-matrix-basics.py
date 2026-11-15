# @title Matrix Math Basics
# @category Math and school
# @kind Console program
# @where Save as matrices.py and run: python3 matrices.py
# @keywords python matrix, python 2d list, python matrix multiply, python transpose, python determinant
# @about Shows how to add, multiply and flip grids of numbers (matrices) using plain Python lists.

def show(name, m):
    print(f"{name}:")
    for row in m:
        print("  [" + " ".join(f"{x:>4}" for x in row) + " ]")


def add(a, b):
    return [[a[r][c] + b[r][c] for c in range(len(a[0]))] for r in range(len(a))]


def transpose(m):
    return [list(col) for col in zip(*m)]  # rows become columns


def multiply(a, b):
    # Each answer cell = row of a "dotted" with a column of b
    return [[sum(x * y for x, y in zip(row, col)) for col in zip(*b)] for row in a]


def determinant_2x2(m):
    return m[0][0] * m[1][1] - m[0][1] * m[1][0]


A = [[1, 2], [3, 4]]
B = [[5, 6], [7, 8]]
show("A", A)
show("B", B)
show("A + B", add(A, B))
show("A x B", multiply(A, B))
show("B x A (different! order matters)", multiply(B, A))
show("A flipped (transpose)", transpose(A))
print("Determinant of A:", determinant_2x2(A))

# Matrices can move points! This one rotates a point 90 degrees.
rotate = [[0, -1], [1, 0]]
point = [[3], [1]]  # x = 3, y = 1 as a column
print("Point (3, 1) rotated 90 degrees becomes", [row[0] for row in multiply(rotate, point)])
