// @title Sudoku Solver with Backtracking
// @category Math and school
// @kind Console program
// @where Save as main.cpp and run: g++ -std=c++17 main.cpp -o sudoku && ./sudoku
// @keywords sudoku solver, backtracking algorithm, solve puzzle by trying, 9x9 grid, logic puzzle c++
// @about Solves any Sudoku by trying numbers and backing up when stuck, which is called backtracking.

#include <iostream>
#include <string>

int grid[9][9];
long long tries = 0;

bool canPlace(int r, int c, int n) {
  for (int i = 0; i < 9; i++) {
    if (grid[r][i] == n || grid[i][c] == n) return false;  // same row or column
    if (grid[r / 3 * 3 + i / 3][c / 3 * 3 + i % 3] == n) return false;  // same 3x3 box
  }
  return true;
}

bool solve() {
  for (int r = 0; r < 9; r++)
    for (int c = 0; c < 9; c++) {
      if (grid[r][c] != 0) continue;
      for (int n = 1; n <= 9; n++) {
        if (!canPlace(r, c, n)) continue;
        grid[r][c] = n;
        tries++;
        if (solve()) return true;
        grid[r][c] = 0;  // that didn't work out: undo and try the next number
      }
      return false;  // nothing fits here, so an earlier guess was wrong
    }
  return true;  // no empty squares left
}

void print() {
  for (int r = 0; r < 9; r++) {
    if (r % 3 == 0) std::cout << "+-------+-------+-------+\n";
    for (int c = 0; c < 9; c++) std::cout << (c % 3 == 0 ? "| " : "") << (grid[r][c] ? char('0' + grid[r][c]) : '.') << " ";
    std::cout << "|\n";
  }
  std::cout << "+-------+-------+-------+\n";
}

int main() {
  std::string puzzle =
    "530070000600195000098000060800060003400803001700020006060000280000419005000080079";
  std::cout << "Type 81 digits (0 or . for blanks), or press Ctrl+D for a sample puzzle:\n";
  std::string typed, word;
  while (typed.size() < 81 && std::cin >> word) typed += word;
  if (typed.size() == 81) puzzle = typed;

  for (int i = 0; i < 81; i++) {
    char ch = puzzle[i];
    grid[i / 9][i % 9] = (ch >= '1' && ch <= '9') ? ch - '0' : 0;
  }
  // Make sure the starting clues don't already break the rules.
  for (int i = 0; i < 81; i++) {
    int n = grid[i / 9][i % 9];
    if (!n) continue;
    grid[i / 9][i % 9] = 0;
    bool ok = canPlace(i / 9, i % 9, n);
    grid[i / 9][i % 9] = n;
    if (!ok) { std::cout << "The puzzle breaks the rules at row " << i / 9 + 1 << ", column " << i % 9 + 1 << ".\n"; return 0; }
  }
  print();
  if (solve()) {
    std::cout << "\nSolved after placing " << tries << " numbers:\n";
    print();
  } else {
    std::cout << "This puzzle has no solution.\n";
  }
  return 0;
}
