// @title Tower of Hanoi Solver
// @category Math and school
// @kind Console program
// @where Save as main.cpp and run: g++ -std=c++17 main.cpp -o hanoi && ./hanoi
// @keywords tower of hanoi, recursive puzzle, move disks pegs, 2 to the n minus 1, recursion solves puzzle
// @about Solves the Tower of Hanoi puzzle with recursion, drawing the three pegs after every move.

#include <iostream>
#include <string>
#include <vector>

std::vector<int> pegs[3];
int disks = 4;
long long moves = 0;

void draw() {
  for (int level = disks - 1; level >= 0; level--) {
    for (const auto &peg : pegs) {
      if (level < static_cast<int>(peg.size())) {
        int size = peg[level];
        std::cout << std::string(disks - size, ' ') << std::string(size * 2 + 1, '=') << std::string(disks - size, ' ');
      } else {
        std::cout << std::string(disks, ' ') << "|" << std::string(disks, ' ');
      }
      std::cout << "  ";
    }
    std::cout << "\n";
  }
  std::cout << std::string((disks * 2 + 3) * 3, '-') << "\n";
}

// To move n disks from A to C: move n-1 out of the way to B, move the biggest to C, then n-1 from B onto it.
void solve(int n, int from, int to, int spare, bool show) {
  if (n == 0) return;
  solve(n - 1, from, spare, to, show);
  pegs[to].push_back(pegs[from].back());
  pegs[from].pop_back();
  moves++;
  if (show) {
    std::cout << "Move " << moves << ": disk " << pegs[to].back() << " from peg " << "ABC"[from] << " to " << "ABC"[to] << "\n";
    draw();
  }
  solve(n - 1, spare, to, from, show);
}

int main() {
  std::cout << "How many disks (1-8)? ";
  if (!(std::cin >> disks) || disks < 1 || disks > 8) disks = 4;
  for (int d = disks; d >= 1; d--) pegs[0].push_back(d);
  draw();
  solve(disks, 0, 2, 1, disks <= 5);  // drawing every move gets long for big towers
  if (disks > 5) draw();
  std::cout << "Solved in " << moves << " moves. The fewest possible is 2^n - 1 = " << (1LL << disks) - 1 << ".\n";
  std::cout << "With 64 disks at one move per second, it would take about 585 billion years!\n";
  return 0;
}
