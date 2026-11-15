// @title High Score List with Structs
// @category Basics
// @kind Console program
// @where Save as main.cpp and run: g++ -std=c++17 main.cpp -o scores && ./scores
// @keywords c++ struct, c++ high score list, c++ std sort, sort a leaderboard in c++, c++ leaderboard
// @about Stores players in a struct, lets you add your own score, then sorts the top 5 with std::sort.

#include <algorithm>
#include <iostream>
#include <sstream>
#include <string>
#include <vector>

// A struct groups related data together.
struct Score {
  std::string name;
  int points;
};

void printTop(const std::vector<Score> &scores, std::size_t howMany) {
  std::cout << "\n=== HIGH SCORES ===\n";
  for (std::size_t i = 0; i < scores.size() && i < howMany; i++) {
    std::cout << (i + 1) << ". " << scores[i].name << " - " << scores[i].points << "\n";
  }
}

int main() {
  std::vector<Score> scores = {
      {"Ava", 1200}, {"Leo", 950}, {"Mia", 1500}, {"Sam", 700}, {"Zoe", 1100}};

  // Ask for the player's name.
  std::cout << "Your name: ";
  std::string name;
  if (!std::getline(std::cin, name)) return 0;
  if (name.empty()) name = "Player";

  // Ask for a score until it's a real number.
  int points = 0;
  while (true) {
    std::cout << "Your score: ";
    std::string line;
    if (!std::getline(std::cin, line)) return 0;
    std::istringstream in(line);
    char extra;
    if (in >> points && !(in >> extra) && points >= 0) break;
    std::cout << "Please type a whole number (0 or more).\n";
  }
  scores.push_back({name, points});

  // Sort biggest first. The little function says how to compare two scores.
  std::sort(scores.begin(), scores.end(), [](const Score &a, const Score &b) {
    return a.points > b.points;
  });

  printTop(scores, 5);

  // Find where the player ended up.
  for (std::size_t i = 0; i < scores.size(); i++) {
    if (scores[i].name == name && scores[i].points == points) {
      std::cout << "\nYou placed #" << (i + 1) << "!";
      if (i < 5) std::cout << " You made the top 5!";
      std::cout << "\n";
      break;
    }
  }
  return 0;
}
