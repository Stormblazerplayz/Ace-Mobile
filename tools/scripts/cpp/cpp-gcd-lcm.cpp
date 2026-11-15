// @title GCD and LCM Calculator
// @category Math and school
// @kind Console program
// @where Save as main.cpp and run: g++ -std=c++17 main.cpp -o gcd && ./gcd
// @keywords greatest common divisor, least common multiple, euclid algorithm, gcd lcm c++, simplify fraction gcd
// @about Finds the greatest common divisor with Euclid's method (showing each step) and the least common multiple.

#include <iostream>
#include <numeric>

// Euclid's trick: gcd(a, b) = gcd(b, a % b), until the remainder is 0.
long long gcdSteps(long long a, long long b) {
  while (b != 0) {
    std::cout << "  gcd(" << a << ", " << b << ") -> " << a << " % " << b << " = " << a % b << "\n";
    long long r = a % b;
    a = b;
    b = r;
  }
  return a;
}

int main() {
  std::cout << "Type two whole numbers (Ctrl+D to stop): ";
  long long a, b;
  while (std::cin >> a >> b) {
    if (a <= 0 || b <= 0) {
      std::cout << "Please use positive numbers.\nType two whole numbers: ";
      continue;
    }
    long long g = gcdSteps(a, b);
    long long l = a / g * b;  // divide first so the number stays smaller
    std::cout << "GCD = " << g << "   (std::gcd agrees: " << std::gcd(a, b) << ")\n";
    std::cout << "LCM = " << l << "   (std::lcm agrees: " << std::lcm(a, b) << ")\n";
    std::cout << "Fraction " << a << "/" << b << " simplifies to " << a / g << "/" << b / g << "\n";
    std::cout << "\nType two whole numbers: ";
  }
  std::cout << "\n";
  return 0;
}
