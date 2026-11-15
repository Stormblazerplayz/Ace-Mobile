// @title Higher or Lower Cards
// @category Games
// @kind Console program
// @where Save as main.cpp and run: g++ -std=c++17 main.cpp -o hilo && ./hilo
// @keywords higher lower card game, guess next card, card streak game, playing card prediction, hi lo cards
// @about Guess whether the next card from the deck will be higher or lower and build the longest streak you can.

#include <algorithm>
#include <iostream>
#include <random>
#include <string>
#include <vector>

std::string cardName(int value) {
  const char *names[] = {"", "", "2", "3", "4", "5", "6", "7", "8", "9", "10", "Jack", "Queen", "King", "Ace"};
  return names[value];
}

int main() {
  std::mt19937 rng(std::random_device{}());
  std::vector<int> deck;
  for (int suit = 0; suit < 4; suit++) for (int v = 2; v <= 14; v++) deck.push_back(v);  // Ace is high (14)
  std::shuffle(deck.begin(), deck.end(), rng);

  int streak = 0, best = 0;
  int current = deck.back();
  deck.pop_back();
  std::cout << "Higher or Lower! Aces are high. Ties count as a loss.\n";

  while (!deck.empty()) {
    // Count how many higher and lower cards are left, so you can play smart.
    int higher = 0, lower = 0;
    for (int v : deck) { if (v > current) higher++; else if (v < current) lower++; }
    std::cout << "\nCard: " << cardName(current) << "   (cards left: " << higher << " higher, " << lower << " lower)\n";
    std::cout << "Streak " << streak << ". (h)igher or (l)ower? ";
    char guess;
    if (!(std::cin >> guess)) break;
    if (guess != 'h' && guess != 'l') { std::cout << "Type h or l.\n"; continue; }

    int next = deck.back();
    deck.pop_back();
    bool right = (guess == 'h' && next > current) || (guess == 'l' && next < current);
    std::cout << "Next card: " << cardName(next) << " ... " << (right ? "Correct!" : "Wrong!") << "\n";
    if (right) {
      streak++;
      best = std::max(best, streak);
    } else {
      streak = 0;
    }
    current = next;
  }
  std::cout << "\nBest streak: " << best << ". " << (deck.empty() ? "You went through the whole deck!" : "Thanks for playing!") << "\n";
  return 0;
}
