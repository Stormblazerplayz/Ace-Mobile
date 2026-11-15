// @title Function Overloading and Default Arguments
// @category Basics
// @kind Console program
// @where Save as main.cpp and run: g++ -std=c++17 main.cpp -o overload && ./overload
// @keywords c++ function overloading, default arguments c++, same function name different types, optional parameters c++
// @about Shows how several functions can share one name with different inputs, and how default arguments fill in missing values.

#include <iostream>
#include <string>

// Three functions called "describe". C++ picks one by looking at what you pass in.
void describe(int n) {
  std::cout << n << " is a whole number\n";
}

void describe(double d) {
  std::cout << d << " is a decimal number\n";
}

void describe(const std::string &s) {
  std::cout << "\"" << s << "\" is text with " << s.size() << " letters\n";
}

// Overloads can also differ by how many inputs they take.
int area(int side) { return side * side; }               // square
int area(int width, int height) { return width * height; }  // rectangle

// Default arguments: if you leave them out, these values are used.
void greet(const std::string &name, const std::string &greeting = "Hello", int times = 1) {
  for (int i = 0; i < times; i++) std::cout << greeting << ", " << name << "!\n";
}

int main() {
  describe(42);
  describe(3.75);
  describe(std::string("robot"));

  std::cout << "Square 5x5 area: " << area(5) << "\n";
  std::cout << "Rectangle 4x7 area: " << area(4, 7) << "\n\n";

  greet("Storm");                 // uses "Hello" and 1
  greet("Pixel", "Howdy");        // uses 1
  greet("Bolt", "Beep boop", 3);  // gives everything
  return 0;
}
