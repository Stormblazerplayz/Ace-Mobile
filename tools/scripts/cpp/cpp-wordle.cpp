// @title Five Letter Word Guess
// @category Games
// @kind Console program
// @where Save as main.cpp and run: g++ -std=c++17 main.cpp -o wordle && ./wordle
// @keywords wordle clone, five letter word game, green yellow letters, word puzzle six tries, letter clues
// @about A Wordle-style game: guess the secret five-letter word in six tries using clues about each letter.

#include <cctype>
#include <iostream>
#include <random>
#include <string>
#include <vector>

// Clues: [A] right letter in the right spot, (A) in the word but wrong spot, A not in the word.
std::string clues(const std::string &guess, const std::string &secret) {
  std::string mark(5, '-');
  int left[26] = {0};
  for (int i = 0; i < 5; i++) {
    if (guess[i] == secret[i]) mark[i] = 'G';
    else left[secret[i] - 'a']++;  // letters still available for yellow clues
  }
  for (int i = 0; i < 5; i++)
    if (mark[i] != 'G' && left[guess[i] - 'a'] > 0) { mark[i] = 'Y'; left[guess[i] - 'a']--; }

  std::string out;
  for (int i = 0; i < 5; i++) {
    char up = static_cast<char>(std::toupper(static_cast<unsigned char>(guess[i])));
    if (mark[i] == 'G') out += std::string("[") + up + "]";
    else if (mark[i] == 'Y') out += std::string("(") + up + ")";
    else out += std::string(" ") + up + " ";
  }
  return out;
}

int main() {
  const std::vector<std::string> words = {"robot", "servo", "motor", "laser", "pixel", "sound", "light",
                                          "power", "solar", "metal", "gears", "wheel", "chips", "board",
                                          "radar", "track", "spark", "cable", "brick", "space"};
  std::mt19937 rng(std::random_device{}());
  std::string secret = words[std::uniform_int_distribution<size_t>(0, words.size() - 1)(rng)];

  std::cout << "Guess the 5-letter word (it's about robots and tech!). 6 tries.\n";
  std::cout << "[A] = right spot, (A) = in the word somewhere else, A = not in the word\n";
  for (int attempt = 1; attempt <= 6; attempt++) {
    std::cout << "Guess " << attempt << ": ";
    std::string guess;
    if (!(std::cin >> guess)) { std::cout << "\nThe word was " << secret << ".\n"; return 0; }
    for (char &c : guess) c = static_cast<char>(std::tolower(static_cast<unsigned char>(c)));
    bool ok = guess.size() == 5;
    for (char c : guess) if (c < 'a' || c > 'z') ok = false;
    if (!ok) { std::cout << "Five letters please.\n"; attempt--; continue; }

    std::cout << "         " << clues(guess, secret) << "\n";
    if (guess == secret) { std::cout << "You got it in " << attempt << "!\n"; return 0; }
  }
  std::cout << "Out of tries! The word was " << secret << ".\n";
  return 0;
}
