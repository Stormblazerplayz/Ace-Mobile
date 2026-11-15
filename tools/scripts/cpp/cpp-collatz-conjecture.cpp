// @title Collatz 3n+1 Explorer
// @category Math and school
// @kind Console program
// @where Save as main.cpp and run: g++ -std=c++17 main.cpp -o collatz && ./collatz
// @keywords collatz conjecture, 3n plus 1, hailstone numbers, unsolved math problem, longest chain
// @about Follows the famous 3n+1 rule (halve if even, triple plus one if odd) and finds which start makes the longest chain.

#include <iostream>

// Count the steps to reach 1 from n.
int steps(unsigned long long n, unsigned long long &highest) {
  int count = 0;
  highest = n;
  while (n != 1) {
    n = (n % 2 == 0) ? n / 2 : 3 * n + 1;
    if (n > highest) highest = n;
    count++;
  }
  return count;
}

int main() {
  // Nobody has ever proved every number reaches 1. It's still an unsolved problem!
  std::cout << "Starting from 27:\n";
  unsigned long long n = 27;
  int col = 0;
  while (true) {
    std::cout << n << (n == 1 ? "\n" : " -> ");
    if (++col % 10 == 0 && n != 1) std::cout << "\n";
    if (n == 1) break;
    n = (n % 2 == 0) ? n / 2 : 3 * n + 1;
  }

  int bestStart = 1, bestSteps = 0;
  unsigned long long peak;
  for (int start = 1; start < 100000; start++) {
    int s = steps(start, peak);
    if (s > bestSteps) { bestSteps = s; bestStart = start; }
  }
  std::cout << "\nUnder 100000, the longest chain starts at " << bestStart << " with " << bestSteps << " steps.\n";

  std::cout << "\nType a starting number (1 to 1000000000, Ctrl+D to stop): ";
  long long start;
  while (std::cin >> start) {
    if (start < 1 || start > 1000000000LL) { std::cout << "Use 1 to 1000000000.\nStart: "; continue; }
    int s = steps(static_cast<unsigned long long>(start), peak);
    std::cout << start << " takes " << s << " steps and climbs as high as " << peak << "\nStart: ";
  }
  std::cout << "\n";
  return 0;
}
