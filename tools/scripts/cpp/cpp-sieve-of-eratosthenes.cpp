// @title Sieve of Eratosthenes
// @category Math and school
// @kind Console program
// @where Save as main.cpp and run: g++ -std=c++17 main.cpp -o sieve && ./sieve
// @keywords sieve of eratosthenes, find all primes fast, cross out multiples, prime sieve c++, twin primes
// @about Finds every prime up to a limit by crossing out multiples, the way the Greek mathematician Eratosthenes did.

#include <iostream>
#include <vector>

int main() {
  int limit = 200;
  std::cout << "Find primes up to (2 to 10000000)? ";
  if (!(std::cin >> limit) || limit < 2 || limit > 10000000) limit = 200;

  // Start by assuming every number is prime, then cross out the ones that aren't.
  std::vector<bool> prime(limit + 1, true);
  prime[0] = prime[1] = false;
  for (long long p = 2; p * p <= limit; p++) {
    if (!prime[p]) continue;
    // Cross out p*p, p*p+p, p*p+2p... (smaller multiples were crossed out already).
    for (long long m = p * p; m <= limit; m += p) prime[m] = false;
  }

  int count = 0, twins = 0;
  for (int n = 2; n <= limit; n++) {
    if (!prime[n]) continue;
    count++;
    if (n + 2 <= limit && prime[n + 2]) twins++;  // primes 2 apart, like 11 and 13
  }

  if (limit <= 1000) {
    std::cout << "Primes:";
    for (int n = 2; n <= limit; n++) if (prime[n]) std::cout << " " << n;
    std::cout << "\n";
  }
  std::cout << "There are " << count << " primes up to " << limit << ".\n";
  std::cout << "Twin prime pairs: " << twins << "\n";
  for (int n = limit; n >= 2; n--) {
    if (prime[n]) { std::cout << "The biggest is " << n << ".\n"; break; }
  }
  return 0;
}
