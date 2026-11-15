// @title Word Scramble Game
// @category Games
// @kind Console program
// @where Save as main.cpp and run: g++ -std=c++17 main.cpp -o scramble && ./scramble
// @keywords word scramble, unscramble letters, anagram game, shuffle a string, spelling game
// @about Unscramble jumbled words to score points, with a hint option that shows the first letter.

#include <algorithm>
#include <iostream>
#include <random>
#include <string>
#include <vector>

int main() {
  std::vector<std::string> words = {"arduino", "sensor", "battery", "circuit", "program", "keyboard",
                                    "rocket", "planet", "dragon", "castle", "jungle", "volcano"};
  std::mt19937 rng(std::random_device{}());
  std::shuffle(words.begin(), words.end(), rng);

  int score = 0;
  for (size_t i = 0; i < 6; i++) {
    std::string word = words[i], mixed = word;
    while (mixed == word) std::shuffle(mixed.begin(), mixed.end(), rng);  // make sure it's actually mixed up

    std::cout << "\nWord " << i + 1 << ": " << mixed << "   (type ? for a hint, ! to skip)\n";
    int points = 3;
    while (true) {
      std::cout << "> ";
      std::string guess;
      if (!(std::cin >> guess)) { std::cout << "\nScore: " << score << "\n"; return 0; }
      if (guess == "!") { std::cout << "It was " << word << ".\n"; break; }
      if (guess == "?") {
        if (points > 1) points--;
        std::cout << "Starts with '" << word[0] << "' and ends with '" << word.back() << "'.\n";
        continue;
      }
      if (guess == word) { score += points; std::cout << "Yes! +" << points << " points\n"; break; }
      std::string a = guess, b = word;
      std::sort(a.begin(), a.end());
      std::sort(b.begin(), b.end());
      std::cout << (a == b ? "Right letters, wrong order. Try again!\n" : "Not quite. Try again!\n");
    }
  }
  std::cout << "\nFinal score: " << score << " out of 18\n";
  return 0;
}
