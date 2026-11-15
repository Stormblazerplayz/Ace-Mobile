// @title auto and Range-Based for Loops
// @category Basics
// @kind Console program
// @where Save as main.cpp and run: g++ -std=c++17 main.cpp -o autoloop && ./autoloop
// @keywords c++ auto keyword, range based for loop, structured bindings, for each loop c++, auto reference
// @about Shows how auto guesses types for you and how range-based for loops walk through vectors and maps.

#include <iostream>
#include <map>
#include <string>
#include <vector>

int main() {
  // auto: the compiler works out the type from the value.
  auto level = 7;           // int
  auto gravity = 9.81;      // double
  auto hero = std::string("Nova");  // std::string
  std::cout << hero << " is on level " << level << " with gravity " << gravity << "\n\n";

  std::vector<std::string> party = {"knight", "archer", "healer"};

  // Read each item (a copy).
  for (auto member : party) std::cout << "Party member: " << member << "\n";

  // auto& lets us CHANGE the real items.
  for (auto &member : party) member = "super " + member;

  // const auto& is the best way to just look: no copy, no changes.
  for (const auto &member : party) std::cout << "Upgraded: " << member << "\n";

  // Range-for over a map. Structured bindings [name, score] split each pair into two names.
  std::map<std::string, int> scores = {{"Ava", 120}, {"Leo", 95}, {"Kai", 150}};
  std::cout << "\nScores (maps keep keys in order):\n";
  for (const auto &[name, score] : scores) {
    std::cout << "  " << name << ": " << score << "\n";
  }

  // Loop over a list written right in the loop.
  std::cout << "\nCountdown:";
  for (int n : {5, 4, 3, 2, 1}) std::cout << " " << n;
  std::cout << " Liftoff!\n";
  return 0;
}
