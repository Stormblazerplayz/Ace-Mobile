# @title Sudoku Solver
# @category Math and school
# @kind Console program
# @where Save as sudoku.py and run: python3 sudoku.py. Change PUZZLE to solve your own (0 means empty).
# @keywords python sudoku solver, python backtracking, python puzzle solver, python recursion puzzle
# @about Solves any Sudoku puzzle using backtracking: try a number, and back up if it leads to a dead end.

PUZZLE = [
    [5, 3, 0, 0, 7, 0, 0, 0, 0],
    [6, 0, 0, 1, 9, 5, 0, 0, 0],
    [0, 9, 8, 0, 0, 0, 0, 6, 0],
    [8, 0, 0, 0, 6, 0, 0, 0, 3],
    [4, 0, 0, 8, 0, 3, 0, 0, 1],
    [7, 0, 0, 0, 2, 0, 0, 0, 6],
    [0, 6, 0, 0, 0, 0, 2, 8, 0],
    [0, 0, 0, 4, 1, 9, 0, 0, 5],
    [0, 0, 0, 0, 8, 0, 0, 7, 9],
]


def allowed(grid, r, c, n):
    if n in grid[r] or any(grid[i][c] == n for i in range(9)):
        return False
    br, bc = r // 3 * 3, c // 3 * 3  # top-left corner of the 3x3 box
    return all(grid[br + i][bc + j] != n for i in range(3) for j in range(3))


def solve(grid):
    for r in range(9):
        for c in range(9):
            if grid[r][c] == 0:
                for n in range(1, 10):
                    if allowed(grid, r, c, n):
                        grid[r][c] = n
                        if solve(grid):
                            return True
                        grid[r][c] = 0  # dead end: undo and try the next number
                return False  # nothing fits here, so an earlier guess was wrong
    return True  # no empty squares left


def show(grid):
    for r, row in enumerate(grid):
        if r % 3 == 0 and r:
            print("------+-------+------")
        print(" | ".join(" ".join(str(n or ".") for n in row[i:i + 3]) for i in (0, 3, 6)))


print("Puzzle:")
show(PUZZLE)
grid = [row[:] for row in PUZZLE]
if solve(grid):
    print("\nSolved:")
    show(grid)
else:
    print("This puzzle has no solution.")
