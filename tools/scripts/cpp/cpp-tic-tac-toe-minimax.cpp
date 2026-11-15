// @title Unbeatable Tic-Tac-Toe AI
// @category Games
// @kind Console program
// @where Save as main.cpp and run: g++ -std=c++17 main.cpp -o tttai && ./tttai
// @keywords minimax algorithm, unbeatable tic tac toe, game tree search, computer plays perfectly, ai opponent c++
// @about Play Tic-Tac-Toe against a computer that uses the minimax algorithm to look at every possible game, so it never loses.

#include <iostream>

char b[9] = {'1', '2', '3', '4', '5', '6', '7', '8', '9'};

char winner() {
  const int lines[8][3] = {{0, 1, 2}, {3, 4, 5}, {6, 7, 8}, {0, 3, 6}, {1, 4, 7}, {2, 5, 8}, {0, 4, 8}, {2, 4, 6}};
  for (auto &l : lines)
    if (b[l[0]] == b[l[1]] && b[l[1]] == b[l[2]]) return b[l[0]];
  for (char c : b) if (c != 'X' && c != 'O') return 0;  // game not over yet
  return 'T';  // tie
}

// Score a position from O's point of view: +10 O wins, -10 X wins, 0 tie.
// O picks the highest score, X (you) is assumed to pick the lowest.
int minimax(bool oTurn, int depth) {
  char w = winner();
  if (w == 'O') return 10 - depth;  // win sooner = better
  if (w == 'X') return depth - 10;
  if (w == 'T') return 0;
  int best = oTurn ? -100 : 100;
  for (int i = 0; i < 9; i++) {
    if (b[i] == 'X' || b[i] == 'O') continue;
    char saved = b[i];
    b[i] = oTurn ? 'O' : 'X';  // try the move
    int s = minimax(!oTurn, depth + 1);
    b[i] = saved;              // undo it
    best = oTurn ? std::max(best, s) : std::min(best, s);
  }
  return best;
}

void draw() {
  for (int r = 0; r < 3; r++) {
    std::cout << " " << b[r * 3] << " | " << b[r * 3 + 1] << " | " << b[r * 3 + 2] << "\n";
    if (r < 2) std::cout << "---+---+---\n";
  }
}

int main() {
  std::cout << "You are X. Try to beat me... you can't!\n";
  while (!winner()) {
    draw();
    std::cout << "Your square (1-9): ";
    int sq;
    if (!(std::cin >> sq)) { std::cout << "\nBye!\n"; return 0; }
    if (sq < 1 || sq > 9 || b[sq - 1] == 'X' || b[sq - 1] == 'O') { std::cout << "Pick an empty square.\n"; continue; }
    b[sq - 1] = 'X';
    if (winner()) break;

    int bestMove = -1, bestScore = -100;
    for (int i = 0; i < 9; i++) {
      if (b[i] == 'X' || b[i] == 'O') continue;
      char saved = b[i];
      b[i] = 'O';
      int s = minimax(false, 1);
      b[i] = saved;
      if (s > bestScore) { bestScore = s; bestMove = i; }
    }
    b[bestMove] = 'O';
    std::cout << "I play " << bestMove + 1 << "\n";
  }
  draw();
  char w = winner();
  std::cout << (w == 'T' ? "A tie! That's the best anyone can do." : w == 'O' ? "I win!" : "You won?! That shouldn't happen!") << "\n";
  return 0;
}
