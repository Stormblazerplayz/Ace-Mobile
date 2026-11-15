// @title Rock Paper Scissors
// @category Games
// @kind Console program
// @where Save as main.cpp and run: g++ -std=c++17 main.cpp -o game && ./game
// @keywords c++ rock paper scissors, rock paper scissors in c++, c++ game vs computer, c++ rps game
// @about Play rock, paper, scissors against the computer and keep score.

#include <cctype>
#include <iostream>
#include <random>
#include <string>

const std::string NAMES[3] = {"rock", "paper", "scissors"};

// Turn what you typed into 0, 1 or 2. Returns -1 if it's not a move.
int toMove(const std::string &text) {
  if (text == "r" || text == "rock") return 0;
  if (text == "p" || text == "paper") return 1;
  if (text == "s" || text == "scissors") return 2;
  return -1;
}

int main() {
  std::random_device seed;
  std::mt19937 rng(seed());
  std::uniform_int_distribution<int> pick(0, 2);

  int wins = 0, losses = 0, ties = 0;
  std::cout << "Rock Paper Scissors! Type r, p or s (or q to quit).\n";

  while (true) {
    std::cout << "\nYour move: ";
    std::string input;
    if (!std::getline(std::cin, input)) break;  // input closed
    for (char &c : input) c = static_cast<char>(std::tolower(static_cast<unsigned char>(c)));
    if (input == "q" || input == "quit") break;

    int you = toMove(input);
    if (you < 0) {
      std::cout << "Hmm, type r, p or s.\n";
      continue;
    }

    int computer = pick(rng);
    std::cout << "You: " << NAMES[you] << "  Computer: " << NAMES[computer] << "\n";

    // Each move beats the one just before it: paper > rock, scissors > paper, rock > scissors.
    if (you == computer) {
      std::cout << "Tie!\n";
      ties++;
    } else if ((you + 2) % 3 == computer) {
      std::cout << "You win!\n";
      wins++;
    } else {
      std::cout << "Computer wins!\n";
      losses++;
    }
    std::cout << "Score - You: " << wins << "  Computer: " << losses << "  Ties: " << ties << "\n";
  }

  std::cout << "\nFinal score - You: " << wins << "  Computer: " << losses
            << "  Ties: " << ties << "\nThanks for playing!\n";
  return 0;
}
