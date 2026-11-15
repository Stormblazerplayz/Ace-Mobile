// @title Number Guessing Game
// @category Games
// @kind Console program
// @where Save as main.cpp and run: g++ -std=c++17 main.cpp -o game && ./game
// @keywords c++ number guessing game, guess the number c++, c++ higher or lower game, c++ guessing game
// @about The computer picks a secret number from 1 to 100 and tells you "higher" or "lower" until you guess it.

#include <iostream>
#include <random>
#include <sstream>
#include <string>

// Ask for a whole number. Keeps asking if you type letters.
// Returns false if the input is closed (so we never loop forever).
bool readNumber(const std::string &prompt, int &number) {
  std::string line;
  while (true) {
    std::cout << prompt;
    if (!std::getline(std::cin, line)) return false;
    std::istringstream in(line);
    char extra;
    if (in >> number && !(in >> extra)) return true;
    std::cout << "That's not a number. Try again!\n";
  }
}

int main() {
  // Set up a good random number maker.
  std::random_device seed;
  std::mt19937 rng(seed());
  std::uniform_int_distribution<int> pick(1, 100);

  bool playAgain = true;
  while (playAgain) {
    int secret = pick(rng);
    int tries = 0;
    int guess = 0;

    std::cout << "\nI'm thinking of a number from 1 to 100...\n";
    while (guess != secret) {
      if (!readNumber("Your guess: ", guess)) return 0;
      if (guess < 1 || guess > 100) {
        std::cout << "Pick between 1 and 100.\n";
        continue;
      }
      tries++;
      if (guess < secret) std::cout << "Higher!\n";
      else if (guess > secret) std::cout << "Lower!\n";
    }
    std::cout << "You got it in " << tries << " tries!\n";

    // Ask to play again.
    std::cout << "Play again? (y/n): ";
    std::string answer;
    if (!std::getline(std::cin, answer)) return 0;
    playAgain = !answer.empty() && (answer[0] == 'y' || answer[0] == 'Y');
  }

  std::cout << "Thanks for playing!\n";
  return 0;
}
