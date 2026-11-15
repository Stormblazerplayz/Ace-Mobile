// @title Fruit Slot Machine
// @category Games
// @kind Console program
// @where Save as main.cpp and run: g++ -std=c++17 main.cpp -o slots && ./slots
// @keywords slot machine, spinning reels, fruit machine game, payout table, why the house always wins
// @about A three-reel fruit slot machine with coins and a payout table, plus a test that shows why the machine always wins in the end.

#include <iostream>
#include <random>
#include <string>

const std::string symbols[] = {"Cherry", "Lemon", "Bell", "Star", "Seven"};
const int weights[] = {40, 30, 15, 10, 5};  // cherries are common, sevens are rare

std::mt19937 rng(std::random_device{}());
std::discrete_distribution<int> reel(std::begin(weights), std::end(weights));

// Payout for a bet of 1 coin.
int payout(int a, int b, int c) {
  if (a == b && b == c) {
    const int jackpot[] = {5, 10, 20, 40, 100};
    return jackpot[a];
  }
  if (a == 0 && b == 0) return 2;  // two cherries on the left
  return 0;
}

int main() {
  // First, a test: spin a million times and see how many coins come back.
  long long paidIn = 0, paidOut = 0;
  for (int i = 0; i < 1000000; i++) {
    paidIn++;
    paidOut += payout(reel(rng), reel(rng), reel(rng));
  }
  std::cout << "Test: for every 100 coins put in, the machine pays back about " << paidOut * 100 / paidIn << ".\n";
  std::cout << "Payouts: 3 Sevens 100, 3 Stars 40, 3 Bells 20, 3 Lemons 10, 3 Cherries 5, Cherry Cherry 2\n\n";

  int coins = 20;
  while (coins > 0) {
    std::cout << "Coins: " << coins << ". Press s to spin, q to quit: ";
    char c;
    if (!(std::cin >> c) || c == 'q') break;
    if (c != 's') continue;
    coins--;
    int a = reel(rng), b = reel(rng), d = reel(rng);
    std::cout << "  [ " << symbols[a] << " | " << symbols[b] << " | " << symbols[d] << " ]";
    int win = payout(a, b, d);
    coins += win;
    std::cout << (win ? "  You win " + std::to_string(win) + "!" : "") << "\n";
  }
  std::cout << "You finish with " << coins << " coins. Remember: the machine is built to win over time!\n";
  return 0;
}
