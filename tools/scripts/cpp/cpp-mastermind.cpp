// @title Mastermind Code Breaker
// @category Games
// @kind Console program
// @where Save as main.cpp and run: g++ -std=c++17 main.cpp -o mastermind && ./mastermind
// @keywords mastermind, crack the code, color code breaker, black and white pegs, deduction game
// @about Crack the computer's secret code of four colors in ten tries using hints about right and almost-right guesses.

#include <algorithm>
#include <cctype>
#include <iostream>
#include <random>
#include <string>

int main() {
  const std::string COLORS = "RGBYOP";  // Red Green Blue Yellow Orange Purple
  std::mt19937 rng(std::random_device{}());
  std::string secret;
  for (int i = 0; i < 4; i++) secret += COLORS[std::uniform_int_distribution<int>(0, 5)(rng)];

  std::cout << "I picked a code of 4 colors from R G B Y O P (colors can repeat).\n";
  std::cout << "After each guess: HIT = right color in the right spot, NEAR = right color, wrong spot.\n";
  for (int turn = 1; turn <= 10; turn++) {
    std::cout << "Guess " << turn << "/10 (like RGBY): ";
    std::string guess;
    if (!(std::cin >> guess)) break;
    std::transform(guess.begin(), guess.end(), guess.begin(), [](unsigned char c) { return static_cast<char>(std::toupper(c)); });
    if (guess.size() != 4 || guess.find_first_not_of(COLORS) != std::string::npos) {
      std::cout << "Use exactly 4 letters from RGBYOP.\n";
      turn--;
      continue;
    }

    int hits = 0, near = 0;
    int secretLeft[26] = {0}, guessLeft[26] = {0};
    for (int i = 0; i < 4; i++) {
      if (guess[i] == secret[i]) hits++;
      else { secretLeft[secret[i] - 'A']++; guessLeft[guess[i] - 'A']++; }
    }
    // For each color, the "near" count is how many unmatched pegs both codes share.
    for (int c = 0; c < 26; c++) near += std::min(secretLeft[c], guessLeft[c]);

    std::cout << "   HIT " << hits << "   NEAR " << near << "\n";
    if (hits == 4) { std::cout << "You cracked the code in " << turn << " guesses!\n"; return 0; }
  }
  std::cout << "The code was " << secret << ". Better luck next time!\n";
  return 0;
}
