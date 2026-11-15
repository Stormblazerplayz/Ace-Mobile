// @title const and constexpr: Values that Never Change
// @category Basics
// @kind Console program
// @where Save as main.cpp and run: g++ -std=c++17 main.cpp -o constexpr && ./constexpr
// @keywords c++ constexpr, const vs constexpr, compile time calculation, static_assert, const member function
// @about Shows const variables, constexpr functions worked out while compiling, static_assert checks, and const methods.

#include <array>
#include <iostream>

// constexpr: the compiler can work this out BEFORE the program even runs.
constexpr int factorial(int n) {
  return n <= 1 ? 1 : n * factorial(n - 1);
}

constexpr int SCREEN_WIDTH = 128;
constexpr int SCREEN_HEIGHT = 64;
constexpr int PIXELS = SCREEN_WIDTH * SCREEN_HEIGHT;  // worked out at compile time

// static_assert checks something at compile time. If it's false, the code won't compile.
static_assert(factorial(5) == 120, "factorial is broken!");
static_assert(PIXELS == 8192, "screen size changed!");

class Thermometer {
public:
  explicit Thermometer(double c) : celsius_(c) {}
  // const after the () promises: this function will not change the object.
  double fahrenheit() const { return celsius_ * 9.0 / 5.0 + 32.0; }
  void heat(double amount) { celsius_ += amount; }  // not const: it changes things
private:
  double celsius_;
};

int main() {
  const int maxLives = 3;  // const: set once, can't change
  // maxLives = 4;  // <- this line would be a compile error. Try it!

  // A constexpr value can be used as an array size.
  std::array<int, factorial(4)> slots{};  // 24 slots
  std::cout << "Lives: " << maxLives << "\n";
  std::cout << "Slots in the array: " << slots.size() << "\n";
  std::cout << "Pixels on the OLED: " << PIXELS << "\n";
  std::cout << "10! = " << factorial(10) << "\n";

  const Thermometer outside(20.0);
  std::cout << "Outside: " << outside.fahrenheit() << " F\n";  // ok: fahrenheit() is const
  // outside.heat(5);  // <- not allowed: outside is const and heat() changes it

  Thermometer oven(150.0);
  oven.heat(30);
  std::cout << "Oven: " << oven.fahrenheit() << " F\n";
  return 0;
}
