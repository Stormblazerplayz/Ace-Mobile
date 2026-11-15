// @title Percentage Calculator
// @category Math and school
// @kind Console program
// @where Save as main.cpp and run: g++ -std=c++17 main.cpp -o percent && ./percent
// @keywords percentage calculator, percent of a number, percent change, sale discount price, tip calculator
// @about Solves the common percent questions: percent of a number, what percent, percent change, discounts and tips.

#include <iomanip>
#include <iostream>

int main() {
  std::cout << std::fixed << std::setprecision(2);
  int choice;
  while (std::cout << "\n1 What is X% of Y?\n2 X is what % of Y?\n3 Percent change from X to Y\n"
                      "4 Sale price (price, % off)\n5 Tip (bill, tip %, people)\n0 Quit\nChoice: " &&
         std::cin >> choice && choice != 0) {
    double x, y, z;
    switch (choice) {
      case 1:
        std::cout << "X and Y: ";
        if (!(std::cin >> x >> y)) return 0;
        std::cout << x << "% of " << y << " = " << y * x / 100 << "  (percent means 'out of 100')\n";
        break;
      case 2:
        std::cout << "X and Y: ";
        if (!(std::cin >> x >> y)) return 0;
        if (y == 0) std::cout << "Y can't be 0.\n";
        else std::cout << x << " is " << x / y * 100 << "% of " << y << "\n";
        break;
      case 3:
        std::cout << "Old value and new value: ";
        if (!(std::cin >> x >> y)) return 0;
        if (x == 0) std::cout << "Can't work out a change from 0.\n";
        else std::cout << (y >= x ? "Up " : "Down ") << (y - x) / x * 100 * (y >= x ? 1 : -1) << "%\n";
        break;
      case 4:
        std::cout << "Price and percent off: ";
        if (!(std::cin >> x >> y)) return 0;
        std::cout << "You save $" << x * y / 100 << ", you pay $" << x * (100 - y) / 100 << "\n";
        break;
      case 5:
        std::cout << "Bill, tip percent, number of people: ";
        if (!(std::cin >> x >> y >> z)) return 0;
        if (z < 1) z = 1;
        std::cout << "Tip $" << x * y / 100 << ", total $" << x * (100 + y) / 100 << ", each person pays $"
                  << x * (100 + y) / 100 / z << "\n";
        break;
      default:
        std::cout << "Pick 0 to 5.\n";
    }
  }
  return 0;
}
