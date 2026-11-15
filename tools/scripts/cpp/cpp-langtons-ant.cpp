// @title Langton's Ant
// @category Games
// @kind Console program
// @where Save as main.cpp and run: g++ -std=c++17 main.cpp -o ant && ./ant
// @keywords langton's ant, simple rules complex patterns, turn left turn right ant, emergent behavior, highway pattern
// @about An ant follows two tiny rules on a grid, makes a mess for 10000 steps, and then mysteriously builds a straight highway.

#include <iostream>
#include <vector>

int main() {
  const int W = 80, H = 52;
  std::vector<std::vector<bool>> black(H, std::vector<bool>(W, false));
  int x = 49, y = 25, dir = 0;  // 0 up, 1 right, 2 down, 3 left
  const int dx[] = {0, 1, 0, -1}, dy[] = {-1, 0, 1, 0};

  long steps = 11500;
  std::cout << "How many steps (try 500, 5000 or 11500)? ";
  long typed;
  if (std::cin >> typed && typed >= 0 && typed <= 100000) steps = typed;

  long done = 0;
  for (; done < steps; done++) {
    // Rule 1: on a white square, turn right. Rule 2: on a black square, turn left.
    dir = black[y][x] ? (dir + 3) % 4 : (dir + 1) % 4;
    black[y][x] = !black[y][x];  // flip the color of the square
    x += dx[dir];
    y += dy[dir];
    if (x < 0 || x >= W || y < 0 || y >= H) { std::cout << "The ant walked off the edge!\n"; break; }
  }

  for (int r = 0; r < H; r++) {
    for (int c = 0; c < W; c++) std::cout << (r == y && c == x ? 'A' : black[r][c] ? '#' : ' ');
    std::cout << "\n";
  }
  std::cout << "After " << done << " steps. Around step 10000 the ant starts building a diagonal 'highway'.\n";
  return 0;
}
