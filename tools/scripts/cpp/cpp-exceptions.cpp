// @title Exceptions: try, throw and catch
// @category Basics
// @kind Console program
// @where Save as main.cpp and run: g++ -std=c++17 main.cpp -o exceptions && ./exceptions
// @keywords c++ exceptions, try catch c++, throw runtime_error, out_of_range exception, error handling c++
// @about Shows how to throw an error when something goes wrong and catch it so the program doesn't crash.

#include <iostream>
#include <stdexcept>
#include <string>
#include <vector>

// Throws an error if you try to withdraw too much.
double withdraw(double balance, double amount) {
  if (amount <= 0) throw std::invalid_argument("amount must be more than zero");
  if (amount > balance) throw std::runtime_error("not enough money");
  return balance - amount;
}

int main() {
  double balance = 50.0;
  std::vector<double> tries = {20.0, -5.0, 100.0, 10.0};

  for (double amount : tries) {
    try {
      balance = withdraw(balance, amount);
      std::cout << "Took out $" << amount << ", left: $" << balance << "\n";
    } catch (const std::invalid_argument &e) {
      // Catches only invalid_argument errors.
      std::cout << "Bad request: " << e.what() << "\n";
    } catch (const std::runtime_error &e) {
      std::cout << "Can't take $" << amount << ": " << e.what() << "\n";
    }
  }

  // Library functions throw too. .at() throws out_of_range if the position is wrong.
  std::vector<int> levels = {1, 2, 3};
  try {
    std::cout << "Level 10 is " << levels.at(10) << "\n";
  } catch (const std::out_of_range &) {
    std::cout << "There is no level 10!\n";
  }

  // stoi throws if the text isn't a number.
  try {
    int n = std::stoi("banana");
    std::cout << n << "\n";
  } catch (const std::exception &e) {  // std::exception catches all standard errors
    std::cout << "\"banana\" is not a number (" << e.what() << ")\n";
  }

  std::cout << "The program kept running. Final balance: $" << balance << "\n";
  return 0;
}
