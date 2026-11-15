// @title Walk Through a Maze
// @category Games
// @kind Console program
// @where Save as main.cpp and run: g++ -std=c++17 main.cpp -o maze && ./maze
// @keywords maze game, random maze generator, walk with wasd, recursive backtracker maze, escape the maze
// @about Generates a brand new random maze every game and lets you walk through it with W A S D to reach the exit.

#include <algorithm>
#include <iostream>
#include <random>
#include <string>
#include <vector>

const int W = 21, H = 11;  // odd sizes so walls and paths alternate
std::vector<std::string> maze(H, std::string(W, '#'));
std::mt19937 rng(std::random_device{}());

// Carve paths: from a cell, visit neighbours 2 steps away in random order, knocking down the wall between.
void carve(int x, int y) {
  maze[y][x] = ' ';
  int dirs[4][2] = {{2, 0}, {-2, 0}, {0, 2}, {0, -2}};
  std::shuffle(std::begin(dirs), std::end(dirs), rng);
  for (auto &d : dirs) {
    int nx = x + d[0], ny = y + d[1];
    if (nx > 0 && nx < W - 1 && ny > 0 && ny < H - 1 && maze[ny][nx] == '#') {
      maze[y + d[1] / 2][x + d[0] / 2] = ' ';
      carve(nx, ny);
    }
  }
}

int main() {
  carve(1, 1);
  maze[H - 2][W - 2] = 'E';  // the exit
  int px = 1, py = 1, steps = 0;

  while (true) {
    for (int y = 0; y < H; y++) {
      for (int x = 0; x < W; x++) std::cout << (x == px && y == py ? '@' : maze[y][x]);
      std::cout << "\n";
    }
    std::cout << "Steps: " << steps << ". Move with w a s d (type several like ddss), q to quit: ";
    std::string keys;
    if (!(std::cin >> keys) || keys == "q") { std::cout << "\nBye!\n"; return 0; }
    for (char k : keys) {
      int nx = px + (k == 'd') - (k == 'a');
      int ny = py + (k == 's') - (k == 'w');
      if (maze[ny][nx] == '#') { std::cout << "Bonk! A wall.\n"; break; }
      px = nx;
      py = ny;
      steps++;
      if (maze[py][px] == 'E') {
        std::cout << "\nYou escaped the maze in " << steps << " steps!\n";
        return 0;
      }
    }
  }
}
