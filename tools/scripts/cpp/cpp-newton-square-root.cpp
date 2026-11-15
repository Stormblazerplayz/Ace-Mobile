// @title Square Roots by Newton's Method
// @category Math and school
// @kind Console program
// @where Save as main.cpp and run: g++ -std=c++17 main.cpp -o newton && ./newton
// @keywords newton's method, square root by hand, guess and improve, babylonian method, convergence
// @about Finds square roots by guessing and improving the guess, showing how fast Newton's method zooms in on the answer.

#include <cmath>
#include <iomanip>
#include <iostream>

int main() {
  std::cout << std::setprecision(15);
  std::cout << "Type a positive number to find its square root (Ctrl+D to stop): ";
  double n;
  while (std::cin >> n) {
    if (n < 0) {
      std::cout << "Negative numbers have no real square root.\n";
    } else if (n == 0) {
      std::cout << "sqrt(0) = 0\n";
    } else {
      double guess = n / 2 + 0.5;  // any positive start works
      // If guess is too big, n / guess is too small, so their average is better.
      for (int step = 1; step <= 60; step++) {
        double better = (guess + n / guess) / 2;
        std::cout << "  step " << step << ": " << better << "\n";
        if (better == guess) break;  // stopped changing, so we're done
        guess = better;
      }
      std::cout << "My answer:      " << guess << "\nstd::sqrt says: " << std::sqrt(n) << "\n";
      std::cout << "Check: " << guess << " x " << guess << " = " << guess * guess << "\n";
    }
    std::cout << "\nAnother number: ";
  }
  std::cout << "\n";
  return 0;
}
