// @title Hangman
// @category Games
// @kind Console program
// @where Save as main.cpp and run: g++ -std=c++17 main.cpp -o game && ./game
// @keywords c++ hangman, hangman game in c++, c++ word guessing game, guess the word c++
// @about Guess the secret word one letter at a time before you run out of lives.

#include <cctype>
#include <iostream>
#include <random>
#include <string>
#include <vector>

int main() {
  const std::vector<std::string> words = {"robot", "planet", "castle", "dragon",
                                          "rocket", "pizza", "jungle", "laptop"};

  std::random_device seed;
  std::mt19937 rng(seed());
  std::uniform_int_distribution<std::size_t> pick(0, words.size() - 1);

  const std::string secret = words[pick(rng)];
  std::string shown(secret.size(), '_');  // what the player sees, like "_ _ _"
  std::string guessed;                     // letters tried so far
  int lives = 6;

  std::cout << "Hangman! Guess the word one letter at a time.\n";

  while (lives > 0 && shown != secret) {
    std::cout << "\nWord: ";
    for (char c : shown) std::cout << c << ' ';
    std::cout << "\nLives: " << lives << "   Tried: " << guessed << "\nLetter: ";

    std::string line;
    if (!std::getline(std::cin, line)) return 0;  // input closed

    // Only accept exactly one letter.
    if (line.size() != 1 || !std::isalpha(static_cast<unsigned char>(line[0]))) {
      std::cout << "Please type one letter.\n";
      continue;
    }
    char letter = static_cast<char>(std::tolower(static_cast<unsigned char>(line[0])));

    if (guessed.find(letter) != std::string::npos) {
      std::cout << "You already tried '" << letter << "'.\n";
      continue;
    }
    guessed += letter;

    // Reveal every spot where the letter appears.
    bool found = false;
    for (std::size_t i = 0; i < secret.size(); i++) {
      if (secret[i] == letter) {
        shown[i] = letter;
        found = true;
      }
    }

    if (found) {
      std::cout << "Nice! '" << letter << "' is in the word.\n";
    } else {
      lives--;
      std::cout << "Nope, no '" << letter << "'.\n";
    }
  }

  if (shown == secret) {
    std::cout << "\nYou won! The word was " << secret << ".\n";
  } else {
    std::cout << "\nOut of lives! The word was " << secret << ".\n";
  }
  return 0;
}
