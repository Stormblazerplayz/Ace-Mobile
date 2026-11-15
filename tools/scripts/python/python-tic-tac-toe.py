# @title Tic Tac Toe (2 Players)
# @category Games
# @kind Console program
# @where Save as tictactoe.py and run: python3 tictactoe.py
# @keywords python tic tac toe, python noughts and crosses, python two player game, python grid game
# @about Two players take turns placing X and O on a 3 by 3 board until someone gets three in a row.

LINES = [(0, 1, 2), (3, 4, 5), (6, 7, 8), (0, 3, 6), (1, 4, 7), (2, 5, 8), (0, 4, 8), (2, 4, 6)]


def draw(board):
    print()
    for row in range(3):
        print(" " + " | ".join(board[row * 3:row * 3 + 3]))
        if row < 2:
            print("---+---+---")
    print()


def winner(board):
    for a, b, c in LINES:
        if board[a] == board[b] == board[c] and board[a] in "XO":
            return board[a]
    return None


board = [str(n) for n in range(1, 10)]  # squares show their numbers until taken
player = "X"

for turn in range(9):
    draw(board)
    while True:
        pick = input(f"Player {player}, pick a square (1-9): ").strip()
        if pick.isdigit() and 1 <= int(pick) <= 9 and board[int(pick) - 1] not in "XO":
            board[int(pick) - 1] = player
            break
        print("That square isn't free.")
    if winner(board):
        draw(board)
        print(f"Player {player} wins!")
        break
    player = "O" if player == "X" else "X"
else:
    # The else on a for loop runs only if we never hit break
    draw(board)
    print("It's a tie!")
