// @title 2048 Sliding Tiles
// @category Games
// @kind Console program
// @where Save as main.cpp and run: g++ -std=c++17 main.cpp -o g2048 && ./g2048
// @keywords 2048 game, slide and merge tiles, wasd controls, powers of two puzzle, rotate grid trick
// @about Slide numbered tiles with W A S D so matching tiles merge, and try to build a 2048 tile.

#include <iomanip>
#include <iostream>
#include <random>
#include <string>

int grid[4][4];
int score = 0;
std::mt19937 rng(std::random_device{}());

void addTile() {
  int empty[16][2], n = 0;
  for (int r = 0; r < 4; r++) for (int c = 0; c < 4; c++) if (!grid[r][c]) { empty[n][0] = r; empty[n][1] = c; n++; }
  if (n == 0) return;
  int pick = std::uniform_int_distribution<int>(0, n - 1)(rng);
  grid[empty[pick][0]][empty[pick][1]] = std::uniform_int_distribution<int>(1, 10)(rng) == 1 ? 4 : 2;
}

// Slide every row to the LEFT and merge. Other directions rotate the grid first.
bool slideLeft() {
  bool moved = false;
  for (auto &row : grid) {
    int out[4] = {0, 0, 0, 0}, k = 0, last = 0;
    for (int v : row) {
      if (!v) continue;
      if (last == v) { out[k - 1] *= 2; score += out[k - 1]; last = 0; }  // merge once
      else { out[k++] = v; last = v; }
    }
    for (int c = 0; c < 4; c++) { if (row[c] != out[c]) moved = true; row[c] = out[c]; }
  }
  return moved;
}

void rotate() {  // turn the grid a quarter turn clockwise
  int t[4][4];
  for (int r = 0; r < 4; r++) for (int c = 0; c < 4; c++) t[c][3 - r] = grid[r][c];
  for (int r = 0; r < 4; r++) for (int c = 0; c < 4; c++) grid[r][c] = t[r][c];
}

bool move(char key) {
  int turns = key == 'a' ? 0 : key == 's' ? 1 : key == 'd' ? 2 : key == 'w' ? 3 : -1;
  if (turns < 0) return false;
  for (int i = 0; i < turns; i++) rotate();
  bool moved = slideLeft();
  for (int i = 0; i < (4 - turns) % 4; i++) rotate();  // turn back
  return moved;
}

bool canMove() {
  for (int r = 0; r < 4; r++)
    for (int c = 0; c < 4; c++) {
      if (!grid[r][c]) return true;
      if (c < 3 && grid[r][c] == grid[r][c + 1]) return true;
      if (r < 3 && grid[r][c] == grid[r + 1][c]) return true;
    }
  return false;
}

int main() {
  addTile();
  addTile();
  while (true) {
    std::cout << "\nScore: " << score << "\n";
    for (auto &row : grid) {
      for (int v : row) std::cout << std::setw(6) << (v ? std::to_string(v) : ".");
      std::cout << "\n";
    }
    if (!canMove()) { std::cout << "No moves left. Game over!\n"; break; }
    std::cout << "Move (w a s d, q to quit): ";
    char k;
    if (!(std::cin >> k) || k == 'q') break;
    if (move(k)) addTile();
    for (auto &row : grid) for (int v : row) if (v == 2048) { std::cout << "You made 2048! You win!\n"; return 0; }
  }
  std::cout << "Final score: " << score << "\n";
  return 0;
}
