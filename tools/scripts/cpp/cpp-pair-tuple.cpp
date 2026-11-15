// @title Pairs and Tuples: Returning Several Values
// @category Basics
// @kind Console program
// @where Save as main.cpp and run: g++ -std=c++17 main.cpp -o tuples && ./tuples
// @keywords std pair, std tuple, return multiple values c++, structured binding tuple, make_pair
// @about Returns two or three values from one function using std::pair and std::tuple, then unpacks them.

#include <iostream>
#include <string>
#include <tuple>
#include <utility>
#include <vector>

// A pair holds exactly two values.
std::pair<int, int> minAndMax(const std::vector<int> &nums) {
  int lo = nums[0], hi = nums[0];
  for (int n : nums) {
    if (n < lo) lo = n;
    if (n > hi) hi = n;
  }
  return {lo, hi};
}

// A tuple can hold any number of values of different types.
std::tuple<std::string, int, double> bestStudent() {
  return {"Mia", 7, 98.5};
}

int main() {
  std::vector<int> temps = {12, -3, 25, 8, 31, 0};
  std::pair<int, int> range = minAndMax(temps);
  std::cout << "Coldest: " << range.first << ", hottest: " << range.second << "\n";

  // C++17 structured bindings: name both parts in one go.
  auto [coldest, hottest] = minAndMax(temps);
  std::cout << "Range: " << hottest - coldest << " degrees\n\n";

  auto [name, grade, score] = bestStudent();
  std::cout << "Best student: " << name << " in grade " << grade << " with " << score << "%\n";

  // std::get<number> also works on tuples.
  auto student = bestStudent();
  std::cout << "Name via std::get<0>: " << std::get<0>(student) << "\n\n";

  // A vector of pairs is a handy mini table.
  std::vector<std::pair<std::string, int>> inventory = {{"arrows", 30}, {"potions", 2}, {"keys", 1}};
  for (const auto &[item, count] : inventory) std::cout << item << " x" << count << "\n";
  return 0;
}
