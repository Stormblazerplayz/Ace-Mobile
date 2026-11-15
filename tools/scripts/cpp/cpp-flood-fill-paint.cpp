// @title Paint Bucket Flood Fill
// @category Data structures
// @kind Console program
// @where Save as main.cpp and run: g++ -std=c++17 main.cpp -o floodfill && ./floodfill
// @keywords flood fill, paint bucket tool, fill area grid, stack based fill, ascii art fill
// @about Works like the paint bucket in a drawing app: type a row and column and it fills that whole area with a new symbol.

#include <iostream>
#include <stack>
#include <string>
#include <utility>
#include <vector>

void draw(const std::vector<std::string> &pic) {
  std::cout << "   0123456789012345\n";
  for (std::size_t r = 0; r < pic.size(); r++) std::cout << (r < 10 ? " " : "") << r << " " << pic[r] << "\n";
}

// Uses our own stack instead of recursion, so huge areas can't overflow the call stack.
int fill(std::vector<std::string> &pic, int row, int col, char paint) {
  char old = pic[row][col];
  if (old == paint) return 0;
  int painted = 0;
  std::stack<std::pair<int, int>> todo;
  todo.push({row, col});
  while (!todo.empty()) {
    auto [r, c] = todo.top();
    todo.pop();
    if (r < 0 || c < 0 || r >= static_cast<int>(pic.size()) || c >= static_cast<int>(pic[r].size())) continue;
    if (pic[r][c] != old) continue;
    pic[r][c] = paint;
    painted++;
    todo.push({r + 1, c});
    todo.push({r - 1, c});
    todo.push({r, c + 1});
    todo.push({r, c - 1});
  }
  return painted;
}

int main() {
  std::vector<std::string> pic = {
    "................",
    "...######.......",
    "...#....#..###..",
    "...#....#..#.#..",
    "...######..###..",
    "................",
    "..#########.....",
    "..#.......#.....",
    "..#########.....",
  };
  const std::string paints = "*o+@%";
  int nextPaint = 0;

  draw(pic);
  std::cout << "Type: row column (Ctrl+D to stop)\n";
  int r, c;
  while (std::cin >> r >> c) {
    if (r < 0 || c < 0 || r >= static_cast<int>(pic.size()) || c >= static_cast<int>(pic[0].size())) {
      std::cout << "That's off the picture.\n";
      continue;
    }
    char paint = paints[nextPaint++ % paints.size()];
    int n = fill(pic, r, c, paint);
    std::cout << "Painted " << n << " squares with '" << paint << "'\n";
    draw(pic);
  }
  return 0;
}
