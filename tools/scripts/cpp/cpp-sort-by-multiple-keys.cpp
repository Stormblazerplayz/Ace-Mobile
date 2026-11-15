// @title Sort a Leaderboard by Several Rules
// @category Data structures
// @kind Console program
// @where Save as main.cpp and run: g++ -std=c++17 main.cpp -o rankings && ./rankings
// @keywords sort by two fields, tie breaker sort, stable_sort, comparator function, std tie compare
// @about Ranks players by points, then by fewer deaths, then by name, and shows how stable_sort keeps ties in order.

#include <algorithm>
#include <iomanip>
#include <iostream>
#include <string>
#include <tuple>
#include <vector>

struct Player {
  std::string name;
  int points;
  int deaths;
};

void print(const std::vector<Player> &players) {
  int rank = 1;
  for (const auto &p : players) {
    std::cout << "  " << rank++ << ". " << std::left << std::setw(8) << p.name << std::right << std::setw(5)
              << p.points << " pts " << std::setw(3) << p.deaths << " deaths\n";
  }
}

int main() {
  std::vector<Player> players = {
    {"Nova", 1500, 4}, {"Ace", 1800, 7}, {"Zed", 1500, 2}, {"Blaze", 1800, 7}, {"Kit", 900, 0}, {"Moss", 1500, 4},
  };

  // Rule: more points first. Tie? Fewer deaths first. Still tied? Alphabetical.
  std::sort(players.begin(), players.end(), [](const Player &a, const Player &b) {
    if (a.points != b.points) return a.points > b.points;
    if (a.deaths != b.deaths) return a.deaths < b.deaths;
    return a.name < b.name;
  });
  std::cout << "Leaderboard:\n";
  print(players);

  // std::tie compares several fields at once, in order: deaths first, then name.
  std::sort(players.begin(), players.end(), [](const Player &a, const Player &b) {
    return std::tie(a.deaths, a.name) < std::tie(b.deaths, b.name);
  });
  std::cout << "\nSafest players (fewest deaths):\n";
  print(players);

  // stable_sort keeps players with equal points in their current order.
  std::stable_sort(players.begin(), players.end(), [](const Player &a, const Player &b) { return a.points > b.points; });
  std::cout << "\nBy points, ties stay in 'safest' order (stable_sort):\n";
  print(players);
  return 0;
}
