// @title Lambdas: Tiny Functions on the Spot
// @category Basics
// @kind Console program
// @where Save as main.cpp and run: g++ -std=c++17 main.cpp -o lambdas && ./lambdas
// @keywords c++ lambda, lambda capture, anonymous function c++, sort with lambda, count_if lambda
// @about Shows how to write lambdas, capture variables, and pass them to sort, count_if and for_each.

#include <algorithm>
#include <iostream>
#include <string>
#include <vector>

int main() {
  // A lambda is a function without a name: [capture](inputs) { body }
  auto square = [](int n) { return n * n; };
  std::cout << "square(7) = " << square(7) << "\n";

  std::vector<int> nums = {5, 12, 3, 18, 7, 9, 21, 4};

  // Pass a lambda to count_if: how many are even?
  int evens = static_cast<int>(std::count_if(nums.begin(), nums.end(), [](int n) { return n % 2 == 0; }));
  std::cout << "Even numbers: " << evens << "\n";

  // Capture by value [limit]: the lambda gets its own copy of limit.
  int limit = 10;
  auto isBig = [limit](int n) { return n > limit; };
  std::cout << "Numbers bigger than " << limit << ":";
  for (int n : nums) {
    if (isBig(n)) std::cout << " " << n;
  }
  std::cout << "\n";

  // Capture by reference [&total]: the lambda can change total.
  int total = 0;
  std::for_each(nums.begin(), nums.end(), [&total](int n) { total += n; });
  std::cout << "Total: " << total << "\n";

  // Sort biggest first with a custom rule.
  std::sort(nums.begin(), nums.end(), [](int a, int b) { return a > b; });
  std::cout << "Biggest first:";
  for (int n : nums) std::cout << " " << n;
  std::cout << "\n";

  // Sort words by length.
  std::vector<std::string> words = {"robot", "AI", "arduino", "cpp", "lambda"};
  std::sort(words.begin(), words.end(),
            [](const std::string &a, const std::string &b) { return a.size() < b.size(); });
  std::cout << "Shortest word first:";
  for (const auto &w : words) std::cout << " " << w;
  std::cout << "\n";

  // A counter that remembers its value between calls (mutable lets it change its own copy).
  auto nextId = [id = 100]() mutable { return id++; };
  std::cout << "IDs: " << nextId() << ", " << nextId() << ", " << nextId() << "\n";
  return 0;
}
