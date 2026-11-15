// @title Random Numbers the Modern Way
// @category Basics
// @kind Console program
// @where Save as main.cpp and run: g++ -std=c++17 main.cpp -o random && ./random
// @keywords c++ random numbers, mt19937, uniform_int_distribution, random dice c++, shuffle vector c++
// @about Uses <random> to roll dice, pick random decimals, choose from a list, and shuffle a deck.

#include <algorithm>
#include <iostream>
#include <random>
#include <string>
#include <vector>

int main() {
  // random_device gives a truly random seed. mt19937 is a fast, good random number engine.
  std::random_device seed;
  std::mt19937 rng(seed());

  // A fair six-sided die: every number 1 to 6 is equally likely.
  std::uniform_int_distribution<int> d6(1, 6);
  std::cout << "Five dice rolls:";
  for (int i = 0; i < 5; i++) std::cout << " " << d6(rng);
  std::cout << "\n";

  // Roll 6000 times and count each face. Each should be close to 1000.
  int counts[7] = {0};
  for (int i = 0; i < 6000; i++) counts[d6(rng)]++;
  std::cout << "6000 rolls:\n";
  for (int face = 1; face <= 6; face++) std::cout << "  " << face << ": " << counts[face] << "\n";

  // Random decimal between 0 and 1.
  std::uniform_real_distribution<double> chance(0.0, 1.0);
  double roll = chance(rng);
  std::cout << "Random chance: " << roll << (roll < 0.1 ? " (rare loot!)" : " (normal loot)") << "\n";

  // Pick a random item from a list.
  std::vector<std::string> pets = {"cat", "dog", "lizard", "parrot", "hamster"};
  std::uniform_int_distribution<std::size_t> pick(0, pets.size() - 1);
  std::cout << "Random pet: " << pets[pick(rng)] << "\n";

  // Shuffle a list.
  std::vector<int> deck = {1, 2, 3, 4, 5, 6, 7, 8, 9, 10};
  std::shuffle(deck.begin(), deck.end(), rng);
  std::cout << "Shuffled:";
  for (int card : deck) std::cout << " " << card;
  std::cout << "\n";

  // The same seed always gives the same "random" numbers. Handy for testing!
  std::mt19937 fixed(42);
  std::cout << "Seed 42 always gives: " << d6(fixed) << " " << d6(fixed) << " " << d6(fixed) << "\n";
  return 0;
}
