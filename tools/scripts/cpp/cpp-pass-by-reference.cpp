// @title Pass by Value vs Pass by Reference
// @category Basics
// @kind Console program
// @where Save as main.cpp and run: g++ -std=c++17 main.cpp -o refs && ./refs
// @keywords pass by reference, pass by value, c++ ampersand parameter, swap function c++, const reference
// @about Shows why a function can't change your variable unless you pass it by reference with an &.

#include <iostream>
#include <string>
#include <vector>

// Gets a COPY. Changing it does nothing to the original.
void addBonusCopy(int score) {
  score += 100;
  std::cout << "  inside addBonusCopy: " << score << "\n";
}

// Gets the REAL variable (a reference). Changes stick!
void addBonusRef(int &score) {
  score += 100;
  std::cout << "  inside addBonusRef: " << score << "\n";
}

// The classic: swap two variables.
void swapValues(int &a, int &b) {
  int temp = a;
  a = b;
  b = temp;
}

// const & = "look but don't touch". Fast (no copy) and safe (can't change it).
int totalLength(const std::vector<std::string> &words) {
  int total = 0;
  for (const std::string &w : words) total += static_cast<int>(w.size());
  return total;
}

int main() {
  int score = 50;
  std::cout << "Start: " << score << "\n";

  addBonusCopy(score);
  std::cout << "After addBonusCopy: " << score << "  (unchanged!)\n";

  addBonusRef(score);
  std::cout << "After addBonusRef: " << score << "  (changed!)\n\n";

  int x = 1, y = 2;
  swapValues(x, y);
  std::cout << "After swap: x = " << x << ", y = " << y << "\n";

  std::vector<std::string> words = {"sword", "shield", "potion"};
  std::cout << "Total letters: " << totalLength(words) << "\n";
  return 0;
}
