// @title Solve Two Equations Together
// @category Math and school
// @kind Console program
// @where Save as main.cpp and run: g++ -std=c++17 main.cpp -o system && ./system
// @keywords simultaneous equations, system of linear equations, cramer's rule, solve for x and y, two lines intersect
// @about Solves two equations with x and y at the same time using Cramer's rule, and spots parallel lines.

#include <cmath>
#include <iostream>

int main() {
  std::cout << "Equations look like:  a x + b y = c\n";
  std::cout << "Type a b c for the first, then a b c for the second (Ctrl+D to stop):\n";
  double a1, b1, c1, a2, b2, c2;
  while (std::cin >> a1 >> b1 >> c1 >> a2 >> b2 >> c2) {
    std::cout << a1 << "x + " << b1 << "y = " << c1 << "\n" << a2 << "x + " << b2 << "y = " << c2 << "\n";
    // The determinant tells us if the two lines cross at exactly one point.
    double det = a1 * b2 - a2 * b1;
    if (std::fabs(det) < 1e-12) {
      // Same slope: either the same line or parallel lines that never meet.
      bool same = std::fabs(a1 * c2 - a2 * c1) < 1e-12 && std::fabs(b1 * c2 - b2 * c1) < 1e-12;
      std::cout << (same ? "Same line: infinitely many answers!\n" : "Parallel lines: no answer.\n");
    } else {
      double x = (c1 * b2 - c2 * b1) / det;
      double y = (a1 * c2 - a2 * c1) / det;
      std::cout << "x = " << x << ", y = " << y << "\n";
      std::cout << "Check: " << a1 * x + b1 * y << " = " << c1 << " and " << a2 * x + b2 * y << " = " << c2 << "\n";
    }
    std::cout << "\nNext pair of equations:\n";
  }
  return 0;
}
