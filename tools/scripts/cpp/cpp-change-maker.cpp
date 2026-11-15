// @title Coin Change Maker
// @category Math and school
// @kind Console program
// @where Save as main.cpp and run: g++ -std=c++17 main.cpp -o change && ./change
// @keywords change maker, fewest coins, greedy algorithm coins, dynamic programming coins, cashier change
// @about Works out the change to give back with the fewest bills and coins, and shows when greedy fails using dynamic programming.

#include <cmath>
#include <iostream>
#include <vector>

int main() {
  // Work in cents so there are no rounding problems with decimals.
  const int money[] = {2000, 1000, 500, 100, 25, 10, 5, 1};
  const char *names[] = {"$20 bill", "$10 bill", "$5 bill", "$1 bill", "quarter", "dime", "nickel", "penny"};

  double price, paid;
  while (std::cout << "Price and money paid, like 3.47 10 (Ctrl+D to stop): " && std::cin >> price >> paid) {
    long cents = std::lround((paid - price) * 100);
    if (cents < 0) { std::cout << "Not enough money!\n"; continue; }
    if (cents > 10000000) { std::cout << "That's a lot of change. Try a smaller amount.\n"; continue; }
    std::cout << "Change: $" << cents / 100 << "." << (cents % 100 < 10 ? "0" : "") << cents % 100 << "\n";
    // Greedy: always give the biggest coin that fits.
    for (int i = 0; i < 8; i++) {
      long count = cents / money[i];
      if (count) std::cout << "  " << count << " x " << names[i] << "\n";
      cents %= money[i];
    }
  }

  // Greedy works for US coins, but not for every coin set! Coins 1, 3, 4 and 6 cents:
  std::cout << "\n\nWeird coins 1, 3, 4: greedy gives 6 = 4+1+1 (3 coins), best is 3+3 (2 coins).\n";
  std::vector<int> weird = {1, 3, 4};
  int target = 6;
  // Dynamic programming: best[x] = fewest coins to make x, built up from small amounts.
  std::vector<int> best(target + 1, 1000);
  best[0] = 0;
  for (int x = 1; x <= target; x++)
    for (int c : weird)
      if (c <= x && best[x - c] + 1 < best[x]) best[x] = best[x - c] + 1;
  std::cout << "Dynamic programming finds " << best[target] << " coins.\n";
  return 0;
}
