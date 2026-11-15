// @title Factorials Permutations and Combinations
// @category Math and school
// @kind Console program
// @where Save as main.cpp and run: g++ -std=c++17 main.cpp -o choose && ./choose
// @keywords factorial calculator, combinations n choose k, permutations, counting arrangements, lottery odds
// @about Works out factorials, permutations and combinations, and uses them to count pizza toppings and lottery odds.

#include <iostream>

// n! = 1 x 2 x 3 x ... x n. Only fits in 64 bits up to 20!
unsigned long long factorial(int n) {
  unsigned long long f = 1;
  for (int i = 2; i <= n; i++) f *= i;
  return f;
}

// Combinations: ways to CHOOSE k things from n when order doesn't matter.
// Multiply and divide a step at a time so the numbers stay small.
unsigned long long choose(int n, int k) {
  if (k < 0 || k > n) return 0;
  if (k > n - k) k = n - k;
  unsigned long long result = 1;
  for (int i = 1; i <= k; i++) result = result * (n - k + i) / i;  // always divides exactly
  return result;
}

// Permutations: ways to ARRANGE k things from n when order matters.
unsigned long long permute(int n, int k) {
  if (k < 0 || k > n) return 0;
  unsigned long long result = 1;
  for (int i = 0; i < k; i++) result *= n - i;
  return result;
}

int main() {
  for (int i = 0; i <= 20; i += 5) std::cout << i << "! = " << factorial(i) << "\n";
  std::cout << "\nPizza with 3 toppings picked from 10: " << choose(10, 3) << " different pizzas\n";
  std::cout << "Gold, silver, bronze among 8 runners: " << permute(8, 3) << " ways\n";
  std::cout << "Lottery picking 6 numbers from 49: 1 in " << choose(49, 6) << "\n\n";

  std::cout << "Type n and k (both 0 to 60) to see nPk and nCk (Ctrl+D to stop): ";
  int n, k;
  while (std::cin >> n >> k) {
    if (n < 0 || n > 60 || k < 0 || k > n) {
      std::cout << "Need 0 <= k <= n <= 60.\nn and k: ";
      continue;
    }
    std::cout << n << "C" << k << " = " << choose(n, k);
    if (n <= 20) std::cout << "   " << n << "P" << k << " = " << permute(n, k);
    std::cout << "\nn and k: ";
  }
  std::cout << "\n";
  return 0;
}
