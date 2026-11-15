// @title Minesweeper
// @category Games
// @kind Console program
// @where Save as main.cpp and run: g++ -std=c++17 main.cpp -o mines && ./mines
// @keywords minesweeper, find the mines, count neighbours, reveal empty area recursion, flag a mine
// @about Classic Minesweeper on a 9 by 9 grid: numbers tell you how many mines touch each square, and empty areas open up by themselves.

#include <cstdlib>
#include <iostream>
#include <random>
#include <string>

const int N = 9, MINES = 10;
bool mine[N][N];
bool open_[N][N];
bool flag[N][N];

int countAround(int r, int c) {
  int n = 0;
  for (int dr = -1; dr <= 1; dr++)
    for (int dc = -1; dc <= 1; dc++) {
      int rr = r + dr, cc = c + dc;
      if (rr >= 0 && rr < N && cc >= 0 && cc < N && mine[rr][cc]) n++;
    }
  return n;
}

// Open a square. If it has no mines around it, open all its neighbours too (recursion!).
void reveal(int r, int c) {
  if (r < 0 || r >= N || c < 0 || c >= N || open_[r][c] || flag[r][c]) return;
  open_[r][c] = true;
  if (countAround(r, c) == 0)
    for (int dr = -1; dr <= 1; dr++)
      for (int dc = -1; dc <= 1; dc++) reveal(r + dr, c + dc);
}

void draw(bool showMines) {
  std::cout << "\n   1 2 3 4 5 6 7 8 9\n";
  for (int r = 0; r < N; r++) {
    std::cout << ' ' << r + 1 << ' ';
    for (int c = 0; c < N; c++) {
      char ch = '#';
      if (showMines && mine[r][c]) ch = '*';
      else if (flag[r][c]) ch = 'F';
      else if (open_[r][c]) ch = countAround(r, c) ? static_cast<char>('0' + countAround(r, c)) : ' ';
      std::cout << ch << ' ';
    }
    std::cout << "\n";
  }
}

int main() {
  std::mt19937 rng(std::random_device{}());
  std::uniform_int_distribution<int> pos(0, N - 1);
  bool firstMove = true;

  std::cout << "Type row and column to open (like 5 5), or f row column to flag a mine.\n";
  while (true) {
    draw(false);
    std::cout << "Move: ";
    std::string cmd;
    if (!(std::cin >> cmd)) break;
    bool flagging = (cmd == "f");
    int r, c;
    if (flagging) { if (!(std::cin >> r >> c)) break; }
    else { try { r = std::stoi(cmd); } catch (...) { continue; } if (!(std::cin >> c)) break; }
    r--; c--;
    if (r < 0 || r >= N || c < 0 || c >= N) { std::cout << "Use 1 to 9.\n"; continue; }

    if (flagging) { if (!open_[r][c]) flag[r][c] = !flag[r][c]; continue; }
    if (firstMove) {
      // Place the mines after the first click so you never lose on move one.
      for (int placed = 0; placed < MINES;) {
        int mr = pos(rng), mc = pos(rng);
        if (mine[mr][mc] || (std::abs(mr - r) <= 1 && std::abs(mc - c) <= 1)) continue;
        mine[mr][mc] = true;
        placed++;
      }
      firstMove = false;
    }
    if (mine[r][c]) { draw(true); std::cout << "BOOM! You hit a mine.\n"; return 0; }
    reveal(r, c);

    int closed = 0;
    for (int i = 0; i < N; i++) for (int j = 0; j < N; j++) if (!open_[i][j]) closed++;
    if (closed == MINES) { draw(true); std::cout << "You cleared the field. You win!\n"; return 0; }
  }
  std::cout << "\nGame stopped.\n";
  return 0;
}
