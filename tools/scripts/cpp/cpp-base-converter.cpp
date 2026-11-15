// @title Number Base Converter
// @category Math and school
// @kind Console program
// @where Save as main.cpp and run: g++ -std=c++17 main.cpp -o bases && ./bases
// @keywords base converter, decimal to binary, hexadecimal converter, octal, convert any base
// @about Converts a whole number into binary, octal, hexadecimal or any base from 2 to 36, showing the division steps.

#include <algorithm>
#include <iostream>
#include <string>

const std::string DIGITS = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ";

// Divide by the base again and again; the remainders are the digits, read backwards.
std::string toBase(unsigned long long n, int base, bool showSteps) {
  if (n == 0) return "0";
  std::string out;
  while (n > 0) {
    if (showSteps) std::cout << "  " << n << " / " << base << " = " << n / base << " remainder " << n % base << "\n";
    out += DIGITS[n % base];
    n /= base;
  }
  std::reverse(out.begin(), out.end());
  return out;
}

int main() {
  std::cout << "Type a number and a base, like 200 2 or 255 16 (Ctrl+D to stop):\n";
  unsigned long long n;
  int base;
  while (std::cout << "> " && std::cin >> n >> base) {
    if (base < 2 || base > 36) {
      std::cout << "Base must be 2 to 36.\n";
      continue;
    }
    std::string answer = toBase(n, base, n < 100000);
    std::cout << n << " in base " << base << " is " << answer << "\n";
    std::cout << "  binary " << toBase(n, 2, false) << ", octal " << toBase(n, 8, false)
              << ", hex " << toBase(n, 16, false) << "\n";
  }
  std::cout << "\n";
  return 0;
}
