// @title Lemonade Stand Business
// @category Games
// @kind Console program
// @where Save as main.cpp and run: g++ -std=c++17 main.cpp -o lemonade && ./lemonade
// @keywords lemonade stand, business simulation game, supply and demand, set a price, profit and loss
// @about Run a lemonade stand for a week: buy cups, set your price, watch the weather, and try to make a profit.

#include <algorithm>
#include <iomanip>
#include <iostream>
#include <random>

int main() {
  std::mt19937 rng(std::random_device{}());
  double money = 10.00;
  const double cupCost = 0.20;
  const char *weather[] = {"Rainy", "Cloudy", "Sunny", "Hot!"};
  const int baseCustomers[] = {8, 20, 40, 70};

  std::cout << std::fixed << std::setprecision(2);
  std::cout << "You start with $10. Each cup of lemonade costs you $0.20 to make.\n";
  for (int day = 1; day <= 7; day++) {
    int w = std::uniform_int_distribution<int>(0, 3)(rng);
    std::cout << "\n=== Day " << day << " ===  Money: $" << money << "   Weather: " << weather[w] << "\n";
    std::cout << "How many cups will you make? ";
    int cups;
    if (!(std::cin >> cups)) break;
    cups = std::max(0, std::min(cups, static_cast<int>(money / cupCost)));
    std::cout << "Price per cup in dollars (like 0.50)? ";
    double price;
    if (!(std::cin >> price)) break;
    price = std::max(0.05, std::min(price, 5.0));

    // Higher prices scare customers away. Good weather brings more people.
    double interest = std::max(0.0, 1.5 - price * 1.5);
    int customers = static_cast<int>(baseCustomers[w] * interest);
    int sold = std::min(cups, customers);
    double cost = cups * cupCost, income = sold * price;
    money += income - cost;

    std::cout << customers << " people wanted lemonade. You sold " << sold << " of " << cups << " cups.\n";
    std::cout << "Income $" << income << " - cost $" << cost << " = " << (income >= cost ? "profit $" : "loss $")
              << std::abs(income - cost) << "\n";
  }
  std::cout << "\nYou end the week with $" << money << ". " << (money > 10 ? "Nice business!" : "Try a different price next time.") << "\n";
  return 0;
}
