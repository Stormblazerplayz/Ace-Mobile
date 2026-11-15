# @title Connect Four
# @category Games
# @kind Console program
# @where Save as connect4.py and run: python3 connect4.py
# @keywords python connect four, python connect 4, python drop discs game, python four in a row
# @about Two players drop X and O discs into columns, first to line up four in a row wins.

ROWS, COLS = 6, 7
board = [["." for _ in range(COLS)] for _ in range(ROWS)]


def draw():
    print()
    for row in board:
        print(" ".join(row))
    print(" ".join(str(c + 1) for c in range(COLS)))


def drop(col, disc):
    """Put the disc in the lowest empty spot of the column. Returns the row, or None if full."""
    for row in range(ROWS - 1, -1, -1):
        if board[row][col] == ".":
            board[row][col] = disc
            return row
    return None


def wins(row, col, disc):
    # Check 4 directions: across, down, and both diagonals.
    for dr, dc in [(0, 1), (1, 0), (1, 1), (1, -1)]:
        count = 1
        for sign in (1, -1):  # look both ways from the new disc
            r, c = row + dr * sign, col + dc * sign
            while 0 <= r < ROWS and 0 <= c < COLS and board[r][c] == disc:
                count += 1
                r += dr * sign
                c += dc * sign
        if count >= 4:
            return True
    return False


disc = "X"
for turn in range(ROWS * COLS):
    draw()
    text = input(f"Player {disc}, pick a column (1-{COLS}): ").strip()
    while not (text.isdigit() and 1 <= int(text) <= COLS and board[0][int(text) - 1] == "."):
        text = input("That column can't be used. Pick another: ").strip()
    col = int(text) - 1
    row = drop(col, disc)
    if wins(row, col, disc):
        draw()
        print(f"Player {disc} connects four and wins!")
        break
    disc = "O" if disc == "X" else "X"
else:
    draw()
    print("The board is full. It's a draw!")
