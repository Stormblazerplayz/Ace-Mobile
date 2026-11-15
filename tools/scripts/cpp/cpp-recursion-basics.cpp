// @title Recursion: Functions that Call Themselves
// @category Basics
// @kind Console program
// @where Save as main.cpp and run: g++ -std=c++17 main.cpp -o recursion && ./recursion
// @keywords c++ recursion, recursive function, base case, recursive factorial, recursion countdown
// @about Shows recursion with a countdown, factorial, adding digits, power and a ruler pattern, always with a base case to stop.

#include <iostream>
#include <string>

// Every recursive function needs a BASE CASE (when to stop) and a step that gets closer to it.
void countdown(int n) {
  if (n == 0) {  // base case
    std::cout << "Liftoff!\n";
    return;
  }
  std::cout << n << "... ";
  countdown(n - 1);  // smaller problem
}

unsigned long long factorial(int n) {
  if (n <= 1) return 1;
  return n * factorial(n - 1);  // 5! = 5 * 4!
}

int digitSum(int n) {
  if (n < 10) return n;
  return n % 10 + digitSum(n / 10);  // last digit + the sum of the rest
}

double power(double base, int exponent) {
  if (exponent == 0) return 1;
  return base * power(base, exponent - 1);
}

// Draws a ruler: each mark is a small ruler, a big line, then another small ruler.
void ruler(int size) {
  if (size == 0) return;
  ruler(size - 1);
  std::cout << std::string(size, '-') << "\n";
  ruler(size - 1);
}

int main() {
  countdown(5);
  for (int i = 0; i <= 10; i += 5) std::cout << i << "! = " << factorial(i) << "\n";
  std::cout << "Digit sum of 98765 = " << digitSum(98765) << "\n";
  std::cout << "2 to the power 10 = " << power(2, 10) << "\n";
  std::cout << "Ruler:\n";
  ruler(4);
  return 0;
}
