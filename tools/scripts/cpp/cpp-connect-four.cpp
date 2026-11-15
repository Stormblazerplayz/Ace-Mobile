// @title Connect Four vs the Computer
// @category Games
// @kind Console program
// @where Save as main.cpp and run: g++ -std=c++17 main.cpp -o connect4 && ./connect4
// @keywords connect four, four in a row, drop discs grid game, check winning lines, simple game ai
// @about Drop discs into a 7 by 6 board and get four in a row before the computer, which blocks and wins when it can.

#include <iostream>
#include <random>

const int ROWS = 6, COLS = 7;
char board[ROWS][COLS];

void draw() {
  std::cout << "\n";
  for (auto &row : board) {
    std::cout << "|";
    for (char c : row) std::cout << c << "|";
    std::cout << "\n";
  }
  std::cout << " 1 2 3 4 5 6 7\n";
}

// Drop a disc; returns the row it landed in, or -1 if the column is full.
int drop(int col, char who) {
  for (int r = ROWS - 1; r >= 0; r--)
    if (board[r][col] == ' ') { board[r][col] = who; return r; }
  return -1;
}

bool wins(char who) {
  const int dirs[4][2] = {{0, 1}, {1, 0}, {1, 1}, {1, -1}};  // across, down, two diagonals
  for (int r = 0; r < ROWS; r++)
    for (int c = 0; c < COLS; c++)
      for (auto &d : dirs) {
        int k = 0;
        while (k < 4) {
          int rr = r + d[0] * k, cc = c + d[1] * k;
          if (rr < 0 || rr >= ROWS || cc < 0 || cc >= COLS || board[rr][cc] != who) break;
          k++;
        }
        if (k == 4) return true;
      }
  return false;
}

// Would dropping in this column make 'who' win? Try it, check, then undo.
bool winningMove(int col, char who) {
  int r = drop(col, who);
  if (r < 0) return false;
  bool w = wins(who);
  board[r][col] = ' ';
  return w;
}

int main() {
  for (auto &row : board) for (char &c : row) c = ' ';
  std::mt19937 rng(std::random_device{}());
  std::cout << "You are X, the computer is O.\n";

  for (int turn = 0; turn < ROWS * COLS; turn += 2) {
    draw();
    std::cout << "Your column (1-7): ";
    int col;
    if (!(std::cin >> col)) { std::cout << "\nBye!\n"; return 0; }
    if (col < 1 || col > COLS || drop(col - 1, 'X') < 0) { std::cout << "Can't go there.\n"; turn -= 2; continue; }
    if (wins('X')) { draw(); std::cout << "You win!\n"; return 0; }

    // Computer: 1) win if it can, 2) block you, 3) otherwise prefer the middle.
    int pick = -1;
    for (int c = 0; c < COLS && pick < 0; c++) if (winningMove(c, 'O')) pick = c;
    for (int c = 0; c < COLS && pick < 0; c++) if (winningMove(c, 'X')) pick = c;
    std::normal_distribution<double> nearMiddle(3.0, 1.5);
    for (int tries = 0; pick < 0 && tries < 100; tries++) {
      int c = static_cast<int>(nearMiddle(rng) + 0.5);
      if (c >= 0 && c < COLS && board[0][c] == ' ') pick = c;
    }
    for (int c = 0; c < COLS && pick < 0; c++) if (board[0][c] == ' ') pick = c;
    if (pick < 0) break;  // board is full
    drop(pick, 'O');
    std::cout << "Computer drops in column " << pick + 1 << "\n";
    if (wins('O')) { draw(); std::cout << "The computer wins!\n"; return 0; }
  }
  draw();
  std::cout << "The board is full. It's a draw!\n";
  return 0;
}
