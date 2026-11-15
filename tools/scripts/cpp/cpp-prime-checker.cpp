// @title Prime Number Checker
// @category Math and school
// @kind Console program
// @where Save as main.cpp and run: g++ -std=c++17 main.cpp -o prime && ./prime
// @keywords prime number checker, is it prime c++, check divisors square root, prime numbers list, primes up to 100
// @about Checks if numbers you type are prime, shows a factor if they aren't, and lists the primes up to 100.

#include <iostream>

// Only need to test divisors up to the square root: if n = a x b, one of them is small.
bool isPrime(long long n, long long &factor) {
  if (n < 2) { factor = 0; return false; }
  if (n % 2 == 0) { factor = 2; return n == 2; }
  for (long long d = 3; d * d <= n; d += 2) {  // skip even numbers
    if (n % d == 0) { factor = d; return false; }
  }
  return true;
}

int main() {
  std::cout << "Primes up to 100:";
  int count = 0;
  for (int n = 2; n <= 100; n++) {
    long long f;
    if (isPrime(n, f)) { std::cout << " " << n; count++; }
  }
  std::cout << "\n(" << count << " of them)\n\n";

  std::cout << "Type numbers to check (Ctrl+D to stop):\n";
  long long n;
  while (std::cin >> n) {
    long long factor = 0;
    if (isPrime(n, factor)) std::cout << n << " is PRIME!\n";
    else if (n < 2) std::cout << n << " is not prime (primes start at 2)\n";
    else std::cout << n << " is not prime: " << factor << " x " << n / factor << " = " << n << "\n";
  }
  return 0;
}
