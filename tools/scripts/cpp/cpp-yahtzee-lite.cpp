// @title Yahtzee Lite Dice Game
// @category Games
// @kind Console program
// @where Save as main.cpp and run: g++ -std=c++17 main.cpp -o yahtzee && ./yahtzee
// @keywords yahtzee, five dice reroll, full house straight, dice scoring game, keep and reroll dice
// @about Roll five dice up to three times, keep the ones you like, and score the best pattern over five rounds.

#include <algorithm>
#include <iostream>
#include <random>
#include <string>

std::mt19937 rng(std::random_device{}());

int bestScore(int dice[5], std::string &what) {
  int counts[7] = {0};
  int sum = 0;
  for (int i = 0; i < 5; i++) { counts[dice[i]]++; sum += dice[i]; }
  int most = *std::max_element(counts + 1, counts + 7);
  bool pair = std::count(counts + 1, counts + 7, 2) == 1;
  int run = 0, longest = 0;
  for (int v = 1; v <= 6; v++) { run = counts[v] ? run + 1 : 0; longest = std::max(longest, run); }

  if (most == 5) { what = "YAHTZEE!"; return 50; }
  if (longest == 5) { what = "Large straight"; return 40; }
  if (most == 3 && pair) { what = "Full house"; return 25; }
  if (longest == 4) { what = "Small straight"; return 30; }
  if (most == 4) { what = "Four of a kind"; return sum; }
  if (most == 3) { what = "Three of a kind"; return sum; }
  what = "Chance (just the total)";
  return sum / 2;  // half points for nothing special
}

int main() {
  std::uniform_int_distribution<int> die(1, 6);
  int total = 0;
  for (int round = 1; round <= 5; round++) {
    int dice[5];
    for (int &d : dice) d = die(rng);
    std::cout << "\n=== Round " << round << " ===\n";
    for (int roll = 1; roll <= 3; roll++) {
      std::cout << "Roll " << roll << ":";
      for (int i = 0; i < 5; i++) std::cout << "  [" << i + 1 << "]=" << dice[i];
      std::cout << "\n";
      if (roll == 3) break;
      std::cout << "Type the dice positions to REROLL (like 135), or 0 to keep all: ";
      std::string pick;
      if (!(std::cin >> pick)) { std::cout << "\nBye! Score: " << total << "\n"; return 0; }
      if (pick == "0") break;
      for (char c : pick)
        if (c >= '1' && c <= '5') dice[c - '1'] = die(rng);
    }
    std::string what;
    int points = bestScore(dice, what);
    total += points;
    std::cout << what << ": " << points << " points. Total: " << total << "\n";
  }
  std::cout << "\nFinal score: " << total << (total >= 150 ? "  Amazing!" : "") << "\n";
  return 0;
}
