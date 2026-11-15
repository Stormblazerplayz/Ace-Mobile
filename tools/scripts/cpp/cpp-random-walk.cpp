// @title Random Walk Simulation
// @category Math and school
// @kind Console program
// @where Save as main.cpp and run: g++ -std=c++17 main.cpp -o walk && ./walk
// @keywords random walk, drunkard's walk, coin flip steps, simulation statistics, square root distance
// @about Simulates a walker who steps left or right by coin flip, and shows that the average distance grows like a square root.

#include <cmath>
#include <iostream>
#include <random>
#include <string>

int main() {
  std::mt19937 rng(std::random_device{}());
  std::bernoulli_distribution coin(0.5);

  // One walker on a 41-wide path, starting in the middle.
  std::cout << "One walker, 30 coin flips:\n";
  int pos = 0;
  for (int step = 0; step <= 30; step++) {
    std::string path(41, '.');
    path[20] = '|';
    if (pos >= -20 && pos <= 20) path[pos + 20] = '@';
    std::cout << path << "  " << (pos >= 0 ? "+" : "") << pos << "\n";
    pos += coin(rng) ? 1 : -1;
  }

  // Lots of walkers: how far away do they end up on average?
  std::cout << "\nSteps   Average distance   sqrt(steps)\n";
  for (int steps = 16; steps <= 4096; steps *= 4) {
    const int walkers = 2000;
    double total = 0;
    for (int w = 0; w < walkers; w++) {
      int p = 0;
      for (int s = 0; s < steps; s++) p += coin(rng) ? 1 : -1;
      total += static_cast<double>(p) * p;
    }
    // Root mean square distance: square, average, then square root.
    std::cout << steps << "\t" << std::sqrt(total / walkers) << "\t\t" << std::sqrt(steps) << "\n";
  }
  std::cout << "\nTo get twice as far away, a random walker needs four times as many steps!\n";
  return 0;
}
