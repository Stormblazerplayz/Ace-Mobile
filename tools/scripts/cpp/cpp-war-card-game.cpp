// @title War Card Game Simulator
// @category Games
// @kind Console program
// @where Save as main.cpp and run: g++ -std=c++17 main.cpp -o war && ./war
// @keywords war card game, deque card piles, card battle simulation, i declare war, two player cards
// @about Plays the card game War between two players using deques as card piles, and shows every battle and war.

#include <algorithm>
#include <deque>
#include <iostream>
#include <random>
#include <vector>

int main() {
  std::mt19937 rng(std::random_device{}());
  std::vector<int> deck;
  for (int s = 0; s < 4; s++) for (int v = 2; v <= 14; v++) deck.push_back(v);
  std::shuffle(deck.begin(), deck.end(), rng);

  // A deque lets us take cards off the top and put won cards on the bottom.
  std::deque<int> p1(deck.begin(), deck.begin() + 26), p2(deck.begin() + 26, deck.end());
  std::cout << "Press Enter to watch each round, or type 'a' to auto-play the whole game.\n";
  bool autoPlay = false;
  int round = 0;

  while (!p1.empty() && !p2.empty() && round < 2000) {
    round++;
    if (!autoPlay) {
      std::string line;
      if (!std::getline(std::cin, line) || line == "a") autoPlay = true;
    }
    std::vector<int> pot;  // cards being fought over
    while (true) {
      if (p1.empty() || p2.empty()) break;
      int a = p1.front(), b = p2.front();
      p1.pop_front();
      p2.pop_front();
      pot.push_back(a);
      pot.push_back(b);
      if (!autoPlay || round % 100 == 0) std::cout << "Round " << round << ": " << a << " vs " << b;
      if (a != b) {
        std::shuffle(pot.begin(), pot.end(), rng);  // shuffle winnings so games don't loop forever
        auto &winner = (a > b) ? p1 : p2;
        for (int c : pot) winner.push_back(c);
        if (!autoPlay || round % 100 == 0)
          std::cout << " -> Player " << (a > b ? 1 : 2) << " takes " << pot.size() << " cards (" << p1.size() << " vs " << p2.size() << ")\n";
        break;
      }
      // Same card: WAR! Each player puts down 3 face-down cards, then flips again.
      if (!autoPlay) std::cout << " -> WAR!\n";
      for (int i = 0; i < 3 && p1.size() > 1 && p2.size() > 1; i++) {
        pot.push_back(p1.front()); p1.pop_front();
        pot.push_back(p2.front()); p2.pop_front();
      }
    }
  }
  std::cout << "\nAfter " << round << " rounds: ";
  if (p1.size() == p2.size()) std::cout << "it's a draw!\n";
  else std::cout << "Player " << (p1.size() > p2.size() ? 1 : 2) << " wins with " << std::max(p1.size(), p2.size()) << " cards!\n";
  return 0;
}
