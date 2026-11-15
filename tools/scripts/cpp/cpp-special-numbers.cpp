// @title Perfect Armstrong and Happy Numbers
// @category Math and school
// @kind Console program
// @where Save as main.cpp and run: g++ -std=c++17 main.cpp -o special && ./special
// @keywords perfect numbers, armstrong numbers, happy numbers, digit sum, number puzzles
// @about Hunts for perfect numbers, Armstrong numbers and happy numbers, and checks any number you type.

#include <iostream>
#include <set>

// Perfect: its divisors (not counting itself) add up to it. 6 = 1 + 2 + 3
bool isPerfect(long n) {
  if (n < 2) return false;
  long sum = 1;
  for (long d = 2; d * d <= n; d++)
    if (n % d == 0) sum += d + (d * d != n ? n / d : 0);
  return sum == n;
}

// Armstrong: each digit raised to the number of digits adds up to it. 153 = 1^3 + 5^3 + 3^3
bool isArmstrong(long n) {
  int digits = 0;
  for (long t = n; t > 0; t /= 10) digits++;
  long sum = 0;
  for (long t = n; t > 0; t /= 10) {
    long p = 1;
    for (int i = 0; i < digits; i++) p *= t % 10;
    sum += p;
  }
  return n > 0 && sum == n;
}

// Happy: keep adding the squares of the digits. Happy numbers reach 1, others loop forever.
bool isHappy(long n) {
  std::set<long> seen;
  while (n != 1 && !seen.count(n)) {
    seen.insert(n);
    long next = 0;
    for (; n > 0; n /= 10) next += (n % 10) * (n % 10);
    n = next;
  }
  return n == 1;
}

int main() {
  std::cout << "Perfect numbers up to 10000:";
  for (long n = 1; n <= 10000; n++) if (isPerfect(n)) std::cout << " " << n;
  std::cout << "\nArmstrong numbers up to 100000:";
  for (long n = 1; n <= 100000; n++) if (isArmstrong(n)) std::cout << " " << n;
  std::cout << "\nHappy numbers up to 50:";
  for (long n = 1; n <= 50; n++) if (isHappy(n)) std::cout << " " << n;

  std::cout << "\n\nType a number to test (Ctrl+D to stop): ";
  long n;
  while (std::cin >> n) {
    if (n < 1 || n > 1000000000L) { std::cout << "Use 1 to 1000000000.\nNumber: "; continue; }
    std::cout << n << (isPerfect(n) ? " is" : " is not") << " perfect, " << (isArmstrong(n) ? "is" : "is not")
              << " Armstrong, " << (isHappy(n) ? "is" : "is not") << " happy.\nNumber: ";
  }
  std::cout << "\n";
  return 0;
}
