// @title Savings and Compound Interest
// @category Math and school
// @kind Console program
// @where Save as main.cpp and run: g++ -std=c++17 main.cpp -o savings && ./savings
// @keywords compound interest, savings calculator, interest per year table, money grows, simple vs compound interest
// @about Shows year by year how savings grow with compound interest compared to simple interest.

#include <iomanip>
#include <iostream>

int main() {
  double start, rate, monthly;
  int years;
  std::cout << "Starting money ($): ";
  if (!(std::cin >> start)) start = 100;
  std::cout << "Interest rate per year (%): ";
  if (!(std::cin >> rate)) rate = 5;
  std::cout << "Money added each month ($): ";
  if (!(std::cin >> monthly)) monthly = 10;
  std::cout << "How many years (1-50): ";
  if (!(std::cin >> years) || years < 1 || years > 50) years = 10;
  if (start < 0) start = 0;
  if (monthly < 0) monthly = 0;

  double compound = start, simple = start, added = start;
  double monthRate = rate / 100 / 12;
  std::cout << std::fixed << std::setprecision(2) << "\nYear   Put in   Simple   Compound\n";
  for (int y = 1; y <= years; y++) {
    for (int m = 0; m < 12; m++) {
      compound += compound * monthRate;  // interest on everything, including old interest
      compound += monthly;
      simple += monthly;
      added += monthly;
    }
    // Simple interest only pays on the money you put in, never on interest.
    simple += added * rate / 100;
    std::cout << std::setw(4) << y << std::setw(9) << added << std::setw(9) << simple << std::setw(11) << compound << "\n";
  }
  std::cout << "\nCompound interest earned $" << compound - added << " for you. That's interest on interest!\n";
  if (rate > 0) std::cout << "Rule of 72: money doubles in about " << 72 / rate << " years at " << rate << "%.\n";
  return 0;
}
