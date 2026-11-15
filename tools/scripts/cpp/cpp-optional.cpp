// @title std::optional: Maybe There's an Answer
// @category Basics
// @kind Console program
// @where Save as main.cpp and run: g++ -std=c++17 main.cpp -o optional && ./optional
// @keywords std optional, c++17 optional, return nothing c++, has_value value_or, maybe value
// @about Uses std::optional for functions that might not have an answer, like finding a player or dividing by zero.

#include <iostream>
#include <optional>
#include <string>
#include <vector>

struct Player {
  std::string name;
  int level;
};

// Returns a Player if found, or nothing (std::nullopt) if not.
std::optional<Player> findPlayer(const std::vector<Player> &players, const std::string &name) {
  for (const Player &p : players) {
    if (p.name == name) return p;
  }
  return std::nullopt;
}

// Dividing by zero has no answer, so we say so instead of crashing.
std::optional<double> safeDivide(double a, double b) {
  if (b == 0) return std::nullopt;
  return a / b;
}

int main() {
  std::vector<Player> players = {{"Ava", 12}, {"Leo", 7}, {"Kai", 20}};

  for (const std::string name : {"Leo", "Zed"}) {
    std::optional<Player> found = findPlayer(players, name);
    if (found.has_value()) {
      std::cout << name << " found at level " << found->level << "\n";
    } else {
      std::cout << name << " is not in the game\n";
    }
  }

  auto good = safeDivide(10, 4);
  auto bad = safeDivide(10, 0);
  std::cout << "\n10 / 4 = " << good.value_or(-1) << "\n";
  // value_or gives a backup value when there is no answer.
  std::cout << "10 / 0 = " << (bad ? std::to_string(*bad) : std::string("no answer!")) << "\n";
  return 0;
}
