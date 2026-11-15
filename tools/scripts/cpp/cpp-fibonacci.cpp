// @title Fibonacci Numbers Three Ways
// @category Math and school
// @kind Console program
// @where Save as main.cpp and run: g++ -std=c++17 main.cpp -o fib && ./fib
// @keywords fibonacci sequence, fibonacci recursion vs loop, memoization c++, golden ratio, fibonacci c++
// @about Works out Fibonacci numbers with slow recursion, fast memoization and a loop, and shows the golden ratio appearing.

#include <iostream>
#include <vector>

long long calls = 0;

// Simple but SLOW: it works out the same numbers again and again.
long long fibSlow(int n) {
  calls++;
  if (n < 2) return n;
  return fibSlow(n - 1) + fibSlow(n - 2);
}

// Memoization: remember answers in a "memo" so each one is worked out only once.
long long fibMemo(int n, std::vector<long long> &memo) {
  if (n < 2) return n;
  if (memo[n] != -1) return memo[n];
  return memo[n] = fibMemo(n - 1, memo) + fibMemo(n - 2, memo);
}

// A loop: just keep the last two numbers.
unsigned long long fibLoop(int n) {
  unsigned long long a = 0, b = 1;
  for (int i = 0; i < n; i++) {
    unsigned long long next = a + b;
    a = b;
    b = next;
  }
  return a;
}

int main() {
  std::cout << "First 20 Fibonacci numbers:";
  for (int i = 0; i < 20; i++) std::cout << " " << fibLoop(i);
  std::cout << "\n\n";

  calls = 0;
  std::cout << "fibSlow(30) = " << fibSlow(30) << " using " << calls << " function calls!\n";
  std::vector<long long> memo(91, -1);
  std::cout << "fibMemo(90) = " << fibMemo(90, memo) << " (each number worked out just once)\n";
  std::cout << "fibLoop(93) = " << fibLoop(93) << " (the biggest that fits in 64 bits)\n\n";

  // Divide each Fibonacci number by the one before: it gets closer and closer to 1.6180339...
  std::cout << "Golden ratio appears:\n";
  for (int i = 2; i <= 20; i += 3) {
    std::cout << "  F(" << i + 1 << ")/F(" << i << ") = " << static_cast<double>(fibLoop(i + 1)) / fibLoop(i) << "\n";
  }
  return 0;
}
