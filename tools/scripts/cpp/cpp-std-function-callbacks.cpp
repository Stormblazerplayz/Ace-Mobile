// @title Callbacks with std::function
// @category Basics
// @kind Console program
// @where Save as main.cpp and run: g++ -std=c++17 main.cpp -o events && ./events
// @keywords std function, callback c++, event system c++, store functions in vector, function as parameter
// @about Builds a tiny event system where functions are stored in a list and called when something happens, like in game engines.

#include <functional>
#include <iostream>
#include <map>
#include <string>
#include <vector>

// An event bus: you "subscribe" functions to event names, then "emit" an event to call them all.
class EventBus {
public:
  using Handler = std::function<void(int)>;  // any function that takes an int and returns nothing

  void subscribe(const std::string &event, Handler handler) {
    handlers_[event].push_back(handler);
  }

  void emit(const std::string &event, int value) {
    std::cout << "> " << event << "(" << value << ")\n";
    for (Handler &h : handlers_[event]) h(value);
  }

private:
  std::map<std::string, std::vector<Handler>> handlers_;
};

// A normal function can be a handler too.
void playSound(int value) {
  std::cout << "  *ding* (sound for " << value << ")\n";
}

int main() {
  EventBus bus;
  int score = 0;
  int coinsCollected = 0;

  bus.subscribe("coin", playSound);
  bus.subscribe("coin", [&score](int value) { score += value; std::cout << "  score is now " << score << "\n"; });
  bus.subscribe("coin", [&coinsCollected](int) { coinsCollected++; });
  bus.subscribe("damage", [](int amount) { std::cout << "  ouch! lost " << amount << " HP\n"; });

  bus.emit("coin", 10);
  bus.emit("damage", 3);
  bus.emit("coin", 50);
  bus.emit("jump", 1);  // nobody listens to this one, and that's fine

  std::cout << "Coins: " << coinsCollected << ", final score: " << score << "\n";

  // std::function can also hold a choice of math operations.
  std::map<char, std::function<double(double, double)>> ops = {
    {'+', [](double a, double b) { return a + b; }},
    {'*', [](double a, double b) { return a * b; }},
  };
  std::cout << "3 + 4 = " << ops['+'](3, 4) << ", 3 * 4 = " << ops['*'](3, 4) << "\n";
  return 0;
}
