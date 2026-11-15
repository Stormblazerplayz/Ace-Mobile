// @title Prime Factor Tree
// @category Math and school
// @kind Console program
// @where Save as main.cpp and run: g++ -std=c++17 main.cpp -o factors && ./factors
// @keywords prime factorization, factor tree, list all divisors, number of divisors, break into primes
// @about Breaks a number into its prime factors, like a factor tree, and lists every divisor it has.

#include <iostream>
#include <map>
#include <vector>

int main() {
  std::cout << "Type a number from 2 to 1000000000000 (Ctrl+D to stop): ";
  long long n;
  while (std::cin >> n) {
    if (n < 2 || n > 1000000000000LL) {
      std::cout << "Pick a number from 2 to 1000000000000.\nNumber: ";
      continue;
    }
    std::map<long long, int> primes;  // prime -> how many times it divides n
    long long rest = n;
    for (long long p = 2; p * p <= rest; p++) {
      while (rest % p == 0) {
        std::cout << "  " << rest << " = " << p << " x " << rest / p << "\n";  // one branch of the tree
        primes[p]++;
        rest /= p;
      }
    }
    if (rest > 1) primes[rest]++;  // whatever is left is a prime too

    std::cout << n << " =";
    bool first = true;
    long long divisorCount = 1;
    for (auto &[p, power] : primes) {
      std::cout << (first ? " " : " x ") << p;
      if (power > 1) std::cout << "^" << power;
      first = false;
      divisorCount *= power + 1;  // a neat trick to count divisors
    }
    std::cout << "\nIt has " << divisorCount << " divisors";
    if (n <= 100000) {
      std::cout << ":";
      for (long long d = 1; d <= n; d++) if (n % d == 0) std::cout << " " << d;
    }
    std::cout << "\n\nNumber: ";
  }
  std::cout << "\n";
  return 0;
}
