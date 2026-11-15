// @title Blackjack Card Game
// @category Games
// @kind Console program
// @where Save as main.cpp and run: g++ -std=c++17 main.cpp -o blackjack && ./blackjack
// @keywords blackjack, twenty one card game, hit or stand, card deck shuffle c++, casino card game
// @about Play Blackjack against the dealer: get closer to 21 than the dealer without going over, with chips to bet.

#include <algorithm>
#include <iostream>
#include <random>
#include <string>
#include <vector>

struct Card {
  int rank;  // 1 = Ace, 11 = Jack, 12 = Queen, 13 = King
  char suit;
};

std::string name(const Card &c) {
  const char *ranks[] = {"", "A", "2", "3", "4", "5", "6", "7", "8", "9", "10", "J", "Q", "K"};
  return std::string(ranks[c.rank]) + c.suit;
}

// Aces count 11 unless that would bust you, then they count 1.
int score(const std::vector<Card> &hand) {
  int total = 0, aces = 0;
  for (const Card &c : hand) {
    total += std::min(c.rank, 10);
    if (c.rank == 1) aces++;
  }
  if (aces > 0 && total + 10 <= 21) total += 10;
  return total;
}

void show(const std::string &who, const std::vector<Card> &hand) {
  std::cout << who << ":";
  for (const Card &c : hand) std::cout << " " << name(c);
  std::cout << "  (" << score(hand) << ")\n";
}

int main() {
  std::mt19937 rng(std::random_device{}());
  std::vector<Card> deck;
  int chips = 100;

  while (chips > 0) {
    if (deck.size() < 15) {  // build and shuffle a fresh deck when running low
      deck.clear();
      for (char s : {'H', 'D', 'C', 'S'}) for (int r = 1; r <= 13; r++) deck.push_back({r, s});
      std::shuffle(deck.begin(), deck.end(), rng);
    }
    std::cout << "\nYou have " << chips << " chips. Bet (0 to quit): ";
    int bet;
    if (!(std::cin >> bet) || bet <= 0) break;
    bet = std::min(bet, chips);

    auto draw = [&]() { Card c = deck.back(); deck.pop_back(); return c; };
    std::vector<Card> you = {draw(), draw()}, dealer = {draw(), draw()};
    std::cout << "Dealer shows: " << name(dealer[0]) << " ??\n";
    show("You", you);

    // Your turn
    bool quit = false;
    while (score(you) < 21) {
      std::cout << "(h)it or (s)tand? ";
      char c;
      if (!(std::cin >> c)) { quit = true; break; }
      if (c == 's') break;
      if (c == 'h') { you.push_back(draw()); show("You", you); }
    }
    if (quit) break;

    int mine = score(you);
    if (mine > 21) {
      std::cout << "Bust! You lose " << bet << ".\n";
      chips -= bet;
      continue;
    }
    // Dealer's turn: the rule is hit until 17 or more.
    show("Dealer", dealer);
    while (score(dealer) < 17) { dealer.push_back(draw()); show("Dealer", dealer); }
    int theirs = score(dealer);

    if (theirs > 21 || mine > theirs) { std::cout << "You win " << bet << "!\n"; chips += bet; }
    else if (mine < theirs) { std::cout << "Dealer wins. You lose " << bet << ".\n"; chips -= bet; }
    else std::cout << "Push (a tie). Nobody wins.\n";
  }
  std::cout << "\nYou leave with " << chips << " chips. Thanks for playing!\n";
  return 0;
}
