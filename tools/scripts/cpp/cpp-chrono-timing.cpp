// @title Timing Your Code with chrono
// @category Basics
// @kind Console program
// @where Save as main.cpp and run: g++ -std=c++17 -O2 main.cpp -o timing && ./timing
// @keywords c++ chrono, measure time c++, steady_clock, how fast is my code, benchmark c++
// @about Measures how long two ways of adding up numbers take, using std::chrono's steady clock.

#include <chrono>
#include <iostream>
#include <vector>

int main() {
  using Clock = std::chrono::steady_clock;  // a clock that never jumps backwards

  const int N = 5000000;
  std::vector<int> numbers(N, 1);

  // Way 1: a normal loop.
  auto start = Clock::now();
  long long total1 = 0;
  for (int i = 0; i < N; i++) total1 += numbers[i];
  auto end = Clock::now();
  auto loopUs = std::chrono::duration_cast<std::chrono::microseconds>(end - start).count();

  // Way 2: the formula 1 + 2 + ... + N = N * (N + 1) / 2 (no loop at all!).
  start = Clock::now();
  long long total2 = static_cast<long long>(N) * (N + 1) / 2;
  end = Clock::now();
  auto formulaNs = std::chrono::duration_cast<std::chrono::nanoseconds>(end - start).count();

  std::cout << "Adding " << N << " ones with a loop: " << total1 << " in " << loopUs << " microseconds\n";
  std::cout << "1 + 2 + ... + " << N << " with a formula: " << total2 << " in " << formulaNs << " nanoseconds\n";
  std::cout << "(1 second = 1,000,000 microseconds = 1,000,000,000 nanoseconds)\n\n";

  // Time how fast YOU are.
  std::cout << "Type anything and press Enter as fast as you can: ";
  start = Clock::now();
  std::string line;
  std::getline(std::cin, line);
  std::chrono::duration<double> seconds = Clock::now() - start;
  std::cout << "You took " << seconds.count() << " seconds.\n";
  return 0;
}
