// @title Points and Lines on a Grid
// @category Math and school
// @kind Console program
// @where Save as main.cpp and run: g++ -std=c++17 main.cpp -o coords && ./coords
// @keywords coordinate geometry, distance between points, midpoint formula, slope of a line, y equals mx plus b
// @about Takes two points and works out the distance, midpoint, slope and the line's equation, then draws them on a grid.

#include <cmath>
#include <iostream>

struct Point {
  double x, y;
};

int main() {
  Point p, q;
  std::cout << "Type two points as x1 y1 x2 y2 (Ctrl+D to stop): ";
  while (std::cin >> p.x >> p.y >> q.x >> q.y) {
    double dx = q.x - p.x, dy = q.y - p.y;
    std::cout << "Distance = sqrt(" << dx << "^2 + " << dy << "^2) = " << std::sqrt(dx * dx + dy * dy) << "\n";
    std::cout << "Midpoint = (" << (p.x + q.x) / 2 << ", " << (p.y + q.y) / 2 << ")\n";
    if (dx == 0 && dy == 0) {
      std::cout << "That's the same point twice.\n";
    } else if (dx == 0) {
      std::cout << "Vertical line: x = " << p.x << " (slope is undefined)\n";
    } else {
      double m = dy / dx, b = p.y - m * p.x;  // slope = rise / run
      std::cout << "Slope m = rise / run = " << dy << " / " << dx << " = " << m << "\n";
      std::cout << "Line: y = " << m << "x + " << b << "\n";
    }

    // Draw a small grid from -10 to 10 if both points fit.
    if (std::fabs(p.x) <= 10 && std::fabs(p.y) <= 10 && std::fabs(q.x) <= 10 && std::fabs(q.y) <= 10) {
      for (int y = 10; y >= -10; y--) {
        for (int x = -10; x <= 10; x++) {
          if (x == std::lround(p.x) && y == std::lround(p.y)) std::cout << 'A';
          else if (x == std::lround(q.x) && y == std::lround(q.y)) std::cout << 'B';
          else if (x == 0 && y == 0) std::cout << '+';
          else if (x == 0) std::cout << '|';
          else if (y == 0) std::cout << '-';
          else std::cout << '.';
        }
        std::cout << "\n";
      }
    }
    std::cout << "\nTwo more points: ";
  }
  std::cout << "\n";
  return 0;
}
