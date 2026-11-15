# @title Tic Tac Toe vs Unbeatable AI
# @category Games
# @kind Console program
# @where Save as tictactoe_ai.py and run: python3 tictactoe_ai.py
# @keywords python tic tac toe ai, python minimax, python unbeatable computer, python game ai
# @about Play tic tac toe against a computer that uses the minimax algorithm, so it never loses.

LINES = [(0, 1, 2), (3, 4, 5), (6, 7, 8), (0, 3, 6), (1, 4, 7), (2, 5, 8), (0, 4, 8), (2, 4, 6)]


def winner(b):
    for x, y, z in LINES:
        if b[x] != " " and b[x] == b[y] == b[z]:
            return b[x]
    return "tie" if " " not in b else None


def minimax(b, ai_turn):
    """Score a board: +1 if the AI (O) can force a win, -1 if you can, 0 for a tie."""
    result = winner(b)
    if result == "O":
        return 1
    if result == "X":
        return -1
    if result == "tie":
        return 0
    scores = []
    for i in range(9):
        if b[i] == " ":
            b[i] = "O" if ai_turn else "X"   # try the move
            scores.append(minimax(b, not ai_turn))
            b[i] = " "                        # undo it
    return max(scores) if ai_turn else min(scores)


def best_move(b):
    best_score, move = -2, None
    for i in range(9):
        if b[i] == " ":
            b[i] = "O"
            score = minimax(b, False)
            b[i] = " "
            if score > best_score:
                best_score, move = score, i
    return move


def draw(b):
    for r in range(3):
        cells = [b[r * 3 + c] if b[r * 3 + c] != " " else str(r * 3 + c + 1) for c in range(3)]
        print(" " + " | ".join(cells))
        if r < 2:
            print("---+---+---")


board = [" "] * 9
print("You are X. The computer is O. Good luck beating it!")
while winner(board) is None:
    draw(board)
    pick = input("Your square (1-9): ").strip()
    if not (pick.isdigit() and 1 <= int(pick) <= 9 and board[int(pick) - 1] == " "):
        print("Pick a free square.")
        continue
    board[int(pick) - 1] = "X"
    if winner(board) is None:
        board[best_move(board)] = "O"

draw(board)
result = winner(board)
print({"X": "You win?! Impossible!", "O": "The computer wins!", "tie": "A tie. That's the best anyone can do!"}[result])
