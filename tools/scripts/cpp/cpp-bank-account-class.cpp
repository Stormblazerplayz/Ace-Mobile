// @title Bank Account Class (Encapsulation)
// @category Basics
// @kind Console program
// @where Save as main.cpp and run: g++ -std=c++17 main.cpp -o bank && ./bank
// @keywords bank account class, encapsulation c++, private data getters, deposit withdraw c++, class with history
// @about A BankAccount class keeps its balance private so it can only change through safe deposit and withdraw methods.

#include <iomanip>
#include <iostream>
#include <sstream>
#include <string>
#include <vector>

class BankAccount {
public:
  explicit BankAccount(const std::string &owner) : owner_(owner) {}

  bool deposit(double amount) {
    if (amount <= 0) return false;  // the class protects itself from bad values
    balance_ += amount;
    history_.push_back("deposit  +" + money(amount));
    return true;
  }

  bool withdraw(double amount) {
    if (amount <= 0 || amount > balance_) return false;
    balance_ -= amount;
    history_.push_back("withdraw -" + money(amount));
    return true;
  }

  // A "getter": lets others READ the balance, but not change it.
  double balance() const { return balance_; }
  const std::string &owner() const { return owner_; }

  void printStatement() const {
    std::cout << "Statement for " << owner_ << ":\n";
    for (const auto &line : history_) std::cout << "  " << line << "\n";
    std::cout << "  Balance: " << money(balance_) << "\n";
  }

private:
  std::string owner_;
  double balance_ = 0.0;  // private: nobody outside can do account.balance_ = 1000000
  std::vector<std::string> history_;

  static std::string money(double amount) {
    std::ostringstream out;
    out << "$" << std::fixed << std::setprecision(2) << amount;
    return out.str();
  }
};

int main() {
  BankAccount account("Storm");
  std::cout << "Commands: d AMOUNT (deposit), w AMOUNT (withdraw), b (balance), q (quit)\n";
  char cmd;
  while (std::cout << "> " && std::cin >> cmd && cmd != 'q') {
    if (cmd == 'b') {
      std::cout << "Balance: $" << std::fixed << std::setprecision(2) << account.balance() << "\n";
      continue;
    }
    if (cmd != 'd' && cmd != 'w') {
      std::cout << "Unknown command. Use d, w, b or q.\n";
      continue;
    }
    double amount;
    if (!(std::cin >> amount)) {
      std::cin.clear();
      std::cin.ignore(1000, '\n');
      std::cout << "Please give an amount, like: d 20\n";
      continue;
    }
    bool ok = (cmd == 'd') ? account.deposit(amount) : account.withdraw(amount);
    std::cout << (ok ? "Done.\n" : "Not allowed.\n");
  }
  std::cout << "\n";
  account.printStatement();
  return 0;
}
