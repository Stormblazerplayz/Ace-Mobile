// @title Neat Tables with iomanip
// @category Basics
// @kind Console program
// @where Save as main.cpp and run: g++ -std=c++17 main.cpp -o receipt && ./receipt
// @keywords c++ setw setprecision, format output c++, print a table c++, iomanip fixed, money formatting c++
// @about Prints a shop receipt with lined-up columns, two decimal places for money and a filled border.

#include <iomanip>
#include <iostream>
#include <string>
#include <vector>

struct LineItem {
  std::string name;
  int qty;
  double price;
};

int main() {
  std::vector<LineItem> items = {
    {"Arduino Uno", 1, 27.60}, {"Servo motor", 4, 3.95}, {"Jumper wires", 2, 6.49}, {"LEDs (100)", 1, 8.00},
  };
  const double TAX_RATE = 0.08;

  // setfill and setw make a border of = signs.
  std::cout << std::setfill('=') << std::setw(40) << "" << std::setfill(' ') << "\n";
  std::cout << std::left << std::setw(20) << "Item" << std::right << std::setw(5) << "Qty"
            << std::setw(15) << "Cost" << "\n";
  std::cout << std::setfill('-') << std::setw(40) << "" << std::setfill(' ') << "\n";

  // fixed + setprecision(2) = always two digits after the dot, perfect for money.
  std::cout << std::fixed << std::setprecision(2);
  double subtotal = 0;
  for (const auto &item : items) {
    double cost = item.qty * item.price;
    subtotal += cost;
    std::cout << std::left << std::setw(20) << item.name << std::right << std::setw(5) << item.qty
              << std::setw(8) << "$" << std::setw(7) << cost << "\n";
  }

  double tax = subtotal * TAX_RATE;
  std::cout << std::setfill('-') << std::setw(40) << "" << std::setfill(' ') << "\n";
  std::cout << std::left << std::setw(25) << "Subtotal" << std::right << std::setw(8) << "$" << std::setw(7) << subtotal << "\n";
  std::cout << std::left << std::setw(25) << "Tax (8%)" << std::right << std::setw(8) << "$" << std::setw(7) << tax << "\n";
  std::cout << std::left << std::setw(25) << "TOTAL" << std::right << std::setw(8) << "$" << std::setw(7) << subtotal + tax << "\n";
  std::cout << std::setfill('=') << std::setw(40) << "" << "\n";
  return 0;
}
