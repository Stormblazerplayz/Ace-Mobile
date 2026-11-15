# @title Multiplication Chart
# @category Math and school
# @kind Console program
# @where Save as chart.py and run: python3 chart.py
# @keywords python multiplication chart, python times table grid, python formatted table, python square numbers
# @about Prints a neat 12 by 12 multiplication chart and highlights the square numbers.

SIZE = 12

# Header row
print("    |" + "".join(f"{n:>5}" for n in range(1, SIZE + 1)))
print("----+" + "-----" * SIZE)

for row in range(1, SIZE + 1):
    cells = []
    for col in range(1, SIZE + 1):
        product = row * col
        # Put square numbers (like 4 x 4) in [brackets] so they stand out
        cells.append(f"[{product}]".rjust(5) if row == col else f"{product:>5}")
    print(f"{row:>3} |" + "".join(cells))

print("\nThe numbers in [brackets] are square numbers: a number times itself.")
print("Notice the chart is the same on both sides of the diagonal, because 3 x 7 = 7 x 3!")
