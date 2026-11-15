// @title Maze Solver with Breadth First Search
// @category Data structures
// @kind Console program
// @where Save as main.cpp and run: g++ -std=c++17 main.cpp -o maze && ./maze
// @keywords breadth first search, bfs maze solver, shortest path grid, pathfinding c++, queue bfs
// @about Finds the shortest path through a maze with breadth first search and draws the path with dots.

#include <iostream>
#include <queue>
#include <string>
#include <utility>
#include <vector>

int main() {
  std::vector<std::string> maze = {
    "##########",
    "#S   #   #",
    "# ## # # #",
    "#  #   # #",
    "## ##### #",
    "#      # #",
    "# #### #E#",
    "##########",
  };
  const int rows = static_cast<int>(maze.size()), cols = static_cast<int>(maze[0].size());

  std::pair<int, int> start{}, end{};
  for (int r = 0; r < rows; r++)
    for (int c = 0; c < cols; c++) {
      if (maze[r][c] == 'S') start = {r, c};
      if (maze[r][c] == 'E') end = {r, c};
    }

  // came[r][c] remembers which square we came from, so we can trace the path back.
  std::vector<std::vector<std::pair<int, int>>> came(rows, std::vector<std::pair<int, int>>(cols, {-1, -1}));
  std::queue<std::pair<int, int>> frontier;
  frontier.push(start);
  came[start.first][start.second] = start;

  const int dr[4] = {-1, 1, 0, 0}, dc[4] = {0, 0, -1, 1};
  // BFS explores in rings: all squares 1 step away, then 2 steps, then 3...
  while (!frontier.empty()) {
    auto [r, c] = frontier.front();
    frontier.pop();
    if (std::make_pair(r, c) == end) break;
    for (int d = 0; d < 4; d++) {
      int nr = r + dr[d], nc = c + dc[d];
      if (maze[nr][nc] == '#' || came[nr][nc].first != -1) continue;  // wall or already seen
      came[nr][nc] = {r, c};
      frontier.push({nr, nc});
    }
  }

  if (came[end.first][end.second].first == -1) {
    std::cout << "No way out!\n";
    return 0;
  }

  // Walk back from the end to the start, marking the path.
  int steps = 0;
  for (auto p = came[end.first][end.second]; p != start; p = came[p.first][p.second]) {
    maze[p.first][p.second] = '.';
    steps++;
  }
  for (const auto &row : maze) std::cout << row << "\n";
  std::cout << "Shortest path: " << steps + 1 << " steps\n";
  return 0;
}
