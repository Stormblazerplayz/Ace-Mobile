// @title Pig Dice Game
// @category Games
// @kind Console program
// @where Save as main.cpp and run: g++ -std=c++17 main.cpp -o pig && ./pig
// @keywords pig dice game, push your luck, roll or hold, dice game vs computer, first to 100
// @about Race the computer to 100 points: keep rolling to build your turn score, but roll a 1 and you lose it all.

#include <iostream>
#include <random>

std::mt19937 rng(std::random_device{}());

int rollDie() {
  return std::uniform_int_distribution<int>(1, 6)(rng);
}

int main() {
  int you = 0, cpu = 0;
  const int GOAL = 100;
  std::cout << "PIG! Roll to add points to this turn. Hold to bank them. Roll a 1 and the turn's points are gone!\n";

  while (you < GOAL && cpu < GOAL) {
    // Your turn
    int turn = 0;
    std::cout << "\nYou " << you << "  Computer " << cpu << "\n";
    while (true) {
      std::cout << "Turn points: " << turn << ". (r)oll or (h)old? ";
      char c;
      if (!(std::cin >> c)) { std::cout << "\nBye!\n"; return 0; }
      if (c == 'h') { you += turn; break; }
      if (c != 'r') continue;
      int d = rollDie();
      std::cout << "  You rolled " << d << "\n";
      if (d == 1) { std::cout << "  PIG! You lose this turn's points.\n"; break; }
      turn += d;
      if (you + turn >= GOAL) { you += turn; break; }
    }
    if (you >= GOAL) break;

    // Computer's turn: it keeps rolling until it has 20 points this turn (a good strategy).
    turn = 0;
    std::cout << "Computer's turn:";
    while (turn < 20 && cpu + turn < GOAL) {
      int d = rollDie();
      std::cout << " " << d;
      if (d == 1) { turn = 0; std::cout << " PIG!"; break; }
      turn += d;
    }
    cpu += turn;
    std::cout << "  -> banks " << turn << "\n";
  }
  std::cout << "\nFinal: You " << you << ", Computer " << cpu << ". " << (you >= GOAL ? "You win!" : "The computer wins!") << "\n";
  return 0;
}
