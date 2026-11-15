// @title Password with Three Tries (while loop)
// @category Basics
// @kind Console program
// @where Save as main.cpp and run: g++ -std=c++17 main.cpp -o password && ./password
// @keywords while loop with tries, password checker c++, three tries login, c++ loop with counter
// @about Gives you three tries to type the secret password, counting down the tries left.

#include <iostream>
#include <string>

int main() {
  const std::string SECRET = "dragon42";
  const int MAX_TRIES = 3;
  int triesLeft = MAX_TRIES;
  bool unlocked = false;
  std::string guess;

  std::cout << "Enter the password to open the vault.\n";
  // Keep going while we have tries AND haven't unlocked it AND there is input.
  while (triesLeft > 0 && !unlocked) {
    std::cout << "Password (" << triesLeft << " tries left): ";
    if (!(std::cin >> guess)) break;

    if (guess == SECRET) {
      unlocked = true;
    } else {
      triesLeft--;
      if (guess.size() < SECRET.size()) std::cout << "Hint: it's longer than that.\n";
    }
  }

  if (unlocked) {
    std::cout << "Vault open! You found 1,000,000 gold coins.\n";
  } else {
    std::cout << "LOCKED OUT! The alarm is ringing.\n";
  }
  return 0;
}
