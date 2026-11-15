// @title Find Pi with Random Darts
// @category Math and school
// @kind Console program
// @where Save as main.cpp and run: g++ -std=c++17 main.cpp -o darts && ./darts
// @keywords monte carlo pi, estimate pi randomly, throw darts simulation, probability experiment, random points circle
// @about Throws millions of random "darts" at a square with a circle inside, and uses the hits to estimate pi.

#include <cmath>
#include <iomanip>
#include <iostream>
#include <random>

int main() {
  // A circle of radius 1 inside a 2 x 2 square. Circle area = pi, square area = 4.
  // So the fraction of darts landing inside the circle should be about pi / 4.
  std::mt19937 rng(2024);  // fixed seed so you get the same answer each time
  std::uniform_real_distribution<double> coord(-1.0, 1.0);

  const double REAL_PI = 3.14159265358979;
  long long inside = 0, thrown = 0;
  std::cout << std::setprecision(8);
  for (long long target = 10; target <= 10000000; target *= 10) {
    while (thrown < target) {
      double x = coord(rng), y = coord(rng);
      if (x * x + y * y <= 1.0) inside++;  // inside the circle?
      thrown++;
    }
    double estimate = 4.0 * inside / thrown;
    std::cout << std::setw(9) << thrown << " darts: pi is about " << std::setw(10) << estimate
              << "  (off by " << std::fabs(estimate - REAL_PI) << ")\n";
  }
  std::cout << "\nMore darts = a better guess, but it improves slowly.\n";

  // Small picture: 60 darts, * inside the circle, . outside
  char grid[11][21];
  for (auto &row : grid) for (char &c : row) c = ' ';
  for (int i = 0; i < 60; i++) {
    double x = coord(rng), y = coord(rng);
    grid[static_cast<int>((y + 1) * 5)][static_cast<int>((x + 1) * 10)] = (x * x + y * y <= 1) ? '*' : '.';
  }
  for (auto &row : grid) {
    for (char c : row) std::cout << c;
    std::cout << "\n";
  }
  return 0;
}
