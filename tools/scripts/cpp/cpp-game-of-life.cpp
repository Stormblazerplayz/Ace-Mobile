// @title Conway's Game of Life
// @category Games
// @kind Console program
// @where Save as main.cpp and run: g++ -std=c++17 main.cpp -o life && ./life
// @keywords game of life, conway cellular automaton, glider pattern, cells live or die, zero player game
// @about Runs Conway's Game of Life, where simple rules about neighbours make patterns that move, blink and grow.

#include <iostream>
#include <random>
#include <string>
#include <vector>

const int W = 40, H = 20;
using Grid = std::vector<std::string>;

int neighbours(const Grid &g, int r, int c) {
  int n = 0;
  for (int dr = -1; dr <= 1; dr++)
    for (int dc = -1; dc <= 1; dc++) {
      if (dr == 0 && dc == 0) continue;
      int rr = (r + dr + H) % H, cc = (c + dc + W) % W;  // edges wrap around like a donut
      if (g[rr][cc] == '#') n++;
    }
  return n;
}

// The rules: a live cell with 2 or 3 neighbours survives; an empty cell with exactly 3 comes alive.
Grid step(const Grid &g) {
  Grid next = g;
  for (int r = 0; r < H; r++)
    for (int c = 0; c < W; c++) {
      int n = neighbours(g, r, c);
      next[r][c] = (n == 3 || (n == 2 && g[r][c] == '#')) ? '#' : '.';
    }
  return next;
}

int main() {
  Grid g(H, std::string(W, '.'));
  std::cout << "1 Glider  2 Blinkers  3 Random soup\nPick a start: ";
  int pick = 1;
  if (!(std::cin >> pick)) pick = 1;
  if (pick == 2) {
    for (int c = 5; c < 35; c += 8) g[10][c] = g[10][c + 1] = g[10][c + 2] = '#';
  } else if (pick == 3) {
    std::mt19937 rng(std::random_device{}());
    for (auto &row : g) for (char &ch : row) ch = std::uniform_int_distribution<int>(0, 3)(rng) == 0 ? '#' : '.';
  } else {
    g[1][2] = g[2][3] = g[3][1] = g[3][2] = g[3][3] = '#';  // a glider walks diagonally forever
  }

  std::cout << "Press Enter for the next generation, or type a number of generations to skip. q quits.\n";
  std::string line;
  std::getline(std::cin, line);  // finish the line with the menu choice
  for (int gen = 0; gen < 1000;) {
    int alive = 0;
    for (const std::string &row : g) { std::cout << row << "\n"; for (char ch : row) alive += ch == '#'; }
    std::cout << "Generation " << gen << ", alive: " << alive << "  > ";
    if (!std::getline(std::cin, line) || line == "q") break;
    int skip = 1;
    try { if (!line.empty()) skip = std::max(1, std::min(100, std::stoi(line))); } catch (...) {}
    for (int i = 0; i < skip; i++) g = step(g);
    gen += skip;
  }
  std::cout << "\n";
  return 0;
}
