// @title The Computer Guesses Your Number
// @category Games
// @kind Console program
// @where Save as main.cpp and run: g++ -std=c++17 main.cpp -o mindreader && ./mindreader
// @keywords computer guesses your number, binary search game, mind reader game, too high too low answers, guess in 7 tries
// @about You think of a number from 1 to 100 and the computer finds it in 7 guesses or fewer using binary search.

#include <iostream>

int main() {
  std::cout << "Think of a number from 1 to 100. I'll guess it in 7 tries or fewer!\n";
  std::cout << "After each guess type h (too high), l (too low) or y (yes!).\n";
  int low = 1, high = 100;
  for (int tries = 1; tries <= 10; tries++) {
    if (low > high) {
      std::cout << "Hmm, your answers don't add up. Did you change your number?\n";
      return 0;
    }
    int guess = (low + high) / 2;  // always guess the middle: it cuts the choices in half
    std::cout << "Guess " << tries << ": is it " << guess << "? (" << high - low + 1 << " numbers still possible) ";
    char reply;
    if (!(std::cin >> reply)) { std::cout << "\nBye!\n"; return 0; }
    if (reply == 'y') {
      std::cout << "I got it in " << tries << " tries! Halving each time means 100 -> 50 -> 25 -> 13 -> 7 -> 4 -> 2 -> 1.\n";
      return 0;
    }
    if (reply == 'h') high = guess - 1;
    else if (reply == 'l') low = guess + 1;
    else { std::cout << "Type h, l or y.\n"; tries--; }
  }
  std::cout << "I ran out of tries. Are you sure you answered right?\n";
  return 0;
}
