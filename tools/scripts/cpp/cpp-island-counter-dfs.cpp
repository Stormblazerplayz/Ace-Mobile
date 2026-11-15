// @title Count Islands with Depth First Search
// @category Data structures
// @kind Console program
// @where Save as main.cpp and run: g++ -std=c++17 main.cpp -o islands && ./islands
// @keywords depth first search, dfs recursion grid, count islands, connected components, flood fill c++
// @about Counts the islands on a map with depth first search, labels each island with a letter, and finds the biggest.

#include <iostream>
#include <string>
#include <vector>

std::vector<std::string> world = {
  "~~##~~~~~~~#~",
  "~###~~~##~~##",
  "~~#~~~~##~~~~",
  "~~~~#~~~~~~~~",
  "~~~###~~~##~~",
  "#~~~#~~~~###~",
  "##~~~~~~~~#~~",
};

// Visit a land square, mark it, then visit its land neighbours. Returns the island's size.
int explore(int r, int c, char label) {
  if (r < 0 || c < 0 || r >= static_cast<int>(world.size()) || c >= static_cast<int>(world[r].size())) return 0;
  if (world[r][c] != '#') return 0;  // water or already labeled
  world[r][c] = label;
  return 1 + explore(r - 1, c, label) + explore(r + 1, c, label) + explore(r, c - 1, label) + explore(r, c + 1, label);
}

int main() {
  std::cout << "Map (# = land, ~ = water):\n";
  for (const auto &row : world) std::cout << row << "\n";

  int islands = 0, biggest = 0;
  char biggestLabel = '?';
  for (int r = 0; r < static_cast<int>(world.size()); r++) {
    for (int c = 0; c < static_cast<int>(world[r].size()); c++) {
      if (world[r][c] == '#') {
        char label = static_cast<char>('A' + islands);
        int size = explore(r, c, label);
        islands++;
        if (size > biggest) { biggest = size; biggestLabel = label; }
      }
    }
  }

  std::cout << "\nLabeled islands:\n";
  for (const auto &row : world) std::cout << row << "\n";
  std::cout << "\nIslands found: " << islands << "\n";
  std::cout << "Biggest is island " << biggestLabel << " with " << biggest << " squares\n";
  return 0;
}
