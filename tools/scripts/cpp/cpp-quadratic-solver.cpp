// @title Quadratic Equation Solver
// @category Math and school
// @kind Console program
// @where Save as main.cpp and run: g++ -std=c++17 main.cpp -o quadratic && ./quadratic
// @keywords quadratic equation solver, quadratic formula c++, discriminant, solve ax2 bx c, complex roots
// @about Solves ax squared + bx + c = 0 with the quadratic formula, explaining the discriminant and handling every case.

#include <cmath>
#include <iostream>

int main() {
  std::cout << "Solve a x^2 + b x + c = 0\nType a b c (Ctrl+D to stop): ";
  double a, b, c;
  while (std::cin >> a >> b >> c) {
    if (a == 0) {
      // Not really quadratic: b x + c = 0
      if (b == 0) std::cout << (c == 0 ? "Every x works!\n" : "No x works.\n");
      else std::cout << "It's a straight line: x = " << -c / b << "\n";
    } else {
      double disc = b * b - 4 * a * c;  // the discriminant decides how many answers
      std::cout << "Discriminant b^2 - 4ac = " << disc << "\n";
      if (disc > 0) {
        double root = std::sqrt(disc);
        std::cout << "Two answers: x = " << (-b + root) / (2 * a) << " and x = " << (-b - root) / (2 * a) << "\n";
      } else if (disc == 0) {
        std::cout << "One answer: x = " << -b / (2 * a) << "\n";
      } else {
        double real = -b / (2 * a), imag = std::sqrt(-disc) / (2 * a);
        std::cout << "No real answers (the curve never touches the x axis).\n"
                  << "Complex answers: x = " << real << " + " << std::fabs(imag) << "i and " << real << " - "
                  << std::fabs(imag) << "i\n";
      }
      std::cout << "The curve's turning point is at x = " << -b / (2 * a) << "\n";
    }
    std::cout << "\nType a b c: ";
  }
  std::cout << "\n";
  return 0;
}
