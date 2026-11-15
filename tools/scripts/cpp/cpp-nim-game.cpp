// @title Nim Matchstick Game
// @category Games
// @kind Console program
// @where Save as main.cpp and run: g++ -std=c++17 main.cpp -o nim && ./nim
// @keywords nim game, matchstick game, xor winning strategy, take the last stick, math strategy game
// @about Take turns removing sticks from three piles; whoever takes the last stick wins, and the computer uses a secret XOR strategy.

#include <iostream>
#include <random>
#include <string>

int main() {
  int piles[3] = {3, 5, 7};
  std::mt19937 rng(std::random_device{}());
  std::cout << "NIM: take any number of sticks from ONE pile. Take the last stick to win!\n";

  bool yourTurn = true;
  while (piles[0] + piles[1] + piles[2] > 0) {
    std::cout << "\n";
    for (int i = 0; i < 3; i++) std::cout << "Pile " << i + 1 << ": " << std::string(piles[i], '|') << " (" << piles[i] << ")\n";

    if (yourTurn) {
      std::cout << "Pile and how many (like 2 3): ";
      int p, n;
      if (!(std::cin >> p >> n)) { std::cout << "\nBye!\n"; return 0; }
      if (p < 1 || p > 3 || n < 1 || n > piles[p - 1]) { std::cout << "Can't do that.\n"; continue; }
      piles[p - 1] -= n;
    } else {
      // The secret: XOR the pile sizes together. If the result isn't 0, there is a move that makes it 0,
      // and a player who always leaves XOR = 0 can never lose.
      int x = piles[0] ^ piles[1] ^ piles[2];
      int pile = -1, take = 0;
      for (int i = 0; i < 3 && x != 0; i++) {
        int target = piles[i] ^ x;
        if (target < piles[i]) { pile = i; take = piles[i] - target; break; }
      }
      if (pile < 0) {  // losing position: take one stick from a random pile and hope you slip up
        do pile = std::uniform_int_distribution<int>(0, 2)(rng); while (piles[pile] == 0);
        take = 1;
      }
      piles[pile] -= take;
      std::cout << "Computer takes " << take << " from pile " << pile + 1 << "\n";
    }
    if (piles[0] + piles[1] + piles[2] == 0) {
      std::cout << (yourTurn ? "You took the last stick. You win!\n" : "Computer took the last stick. It wins!\n");
    }
    yourTurn = !yourTurn;
  }
  return 0;
}
