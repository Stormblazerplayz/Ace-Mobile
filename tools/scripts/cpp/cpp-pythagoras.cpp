// @title Pythagoras Theorem Helper
// @category Math and school
// @kind Console program
// @where Save as main.cpp and run: g++ -std=c++17 main.cpp -o pythagoras && ./pythagoras
// @keywords pythagoras theorem, find hypotenuse, right triangle sides, pythagorean triples, a2 plus b2
// @about Finds a missing side of a right triangle with a squared + b squared = c squared, and lists Pythagorean triples.

#include <cmath>
#include <iostream>

int main() {
  std::cout << "Whole-number right triangles (Pythagorean triples) with sides up to 30:\n";
  for (int a = 1; a <= 30; a++)
    for (int b = a; b <= 30; b++) {
      int c2 = a * a + b * b;
      int c = static_cast<int>(std::lround(std::sqrt(c2)));
      if (c * c == c2 && c <= 30) std::cout << "  " << a << ", " << b << ", " << c << "\n";
    }

  std::cout << "\n1 = find the long side (hypotenuse), 2 = find a short side, 0 = quit\n";
  int choice;
  while (std::cout << "Choice: " && std::cin >> choice && choice != 0) {
    double x, y;
    if (choice == 1) {
      std::cout << "The two short sides: ";
      if (!(std::cin >> x >> y)) break;
      if (x <= 0 || y <= 0) { std::cout << "Sides must be positive.\n"; continue; }
      std::cout << "c = sqrt(" << x << "^2 + " << y << "^2) = sqrt(" << x * x + y * y << ") = "
                << std::sqrt(x * x + y * y) << "\n";
    } else if (choice == 2) {
      std::cout << "Long side, then the short side you know: ";
      if (!(std::cin >> x >> y)) break;
      if (x <= y || y <= 0) { std::cout << "The long side must be the biggest.\n"; continue; }
      std::cout << "b = sqrt(" << x << "^2 - " << y << "^2) = sqrt(" << x * x - y * y << ") = "
                << std::sqrt(x * x - y * y) << "\n";
    } else {
      std::cout << "Pick 1, 2 or 0.\n";
    }
  }
  return 0;
}
