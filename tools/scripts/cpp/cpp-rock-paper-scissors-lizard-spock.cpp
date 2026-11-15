// @title Rock Paper Scissors Lizard Spock
// @category Games
// @kind Console program
// @where Save as main.cpp and run: g++ -std=c++17 main.cpp -o rpsls && ./rpsls
// @keywords rock paper scissors lizard spock, five move game, who beats who table, best of five match, modular arithmetic trick
// @about The five-move version of Rock Paper Scissors, using a neat math trick to decide who wins each round.

#include <iostream>
#include <random>
#include <string>

const std::string moves[] = {"Rock", "Spock", "Paper", "Lizard", "Scissors"};

int main() {
  // With the moves in this circle order, each move beats the two that come 3 and 4 places after it.
  // So (you - them + 5) % 5 being 1 or 2 means you win, 3 or 4 means you lose.
  std::mt19937 rng(std::random_device{}());
  std::cout << "Scissors cuts Paper, Paper covers Rock, Rock crushes Lizard, Lizard poisons Spock,\n"
               "Spock smashes Scissors, Scissors decapitates Lizard, Lizard eats Paper,\n"
               "Paper disproves Spock, Spock vaporizes Rock, Rock crushes Scissors.\n";
  int you = 0, cpu = 0;
  while (you < 3 && cpu < 3) {
    std::cout << "\nYou " << you << " - " << cpu << " Computer. First to 3!\n";
    for (int i = 0; i < 5; i++) std::cout << "  " << i + 1 << " " << moves[i] << "\n";
    std::cout << "Your move: ";
    int m;
    if (!(std::cin >> m)) break;
    if (m < 1 || m > 5) { std::cout << "Pick 1 to 5.\n"; continue; }
    m--;
    int c = std::uniform_int_distribution<int>(0, 4)(rng);
    std::cout << "You: " << moves[m] << "   Computer: " << moves[c] << "\n";
    int diff = (m - c + 5) % 5;
    if (diff == 0) std::cout << "Tie!\n";
    else if (diff == 1 || diff == 2) { you++; std::cout << "You win the round!\n"; }
    else { cpu++; std::cout << "Computer wins the round!\n"; }
  }
  if (you == 3) std::cout << "\nYou win the match!\n";
  else if (cpu == 3) std::cout << "\nThe computer wins the match!\n";
  else std::cout << "\nMatch stopped.\n";
  return 0;
}
