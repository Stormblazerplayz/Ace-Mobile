// @title Type Conversions and Casting
// @category Basics
// @kind Console program
// @where Save as main.cpp and run: g++ -std=c++17 main.cpp -o casts && ./casts
// @keywords c++ static_cast, type conversion c++, int to double, rounding c++, to_string and stoi
// @about Shows how to turn ints into doubles, round numbers, and convert between numbers, characters and text.

#include <cmath>
#include <iostream>
#include <string>

int main() {
  // int to double: so division keeps the decimal part.
  int correct = 17, questions = 20;
  double percent = static_cast<double>(correct) / questions * 100;
  std::cout << "Score: " << percent << "%\n";

  // double to int CHOPS off the decimals (it does not round!).
  double health = 87.9;
  std::cout << "static_cast<int>(87.9) = " << static_cast<int>(health) << "\n";
  std::cout << "std::round(87.9) = " << std::round(health) << "\n";
  std::cout << "std::floor(87.9) = " << std::floor(health) << ", std::ceil(87.1) = " << std::ceil(87.1) << "\n";

  // char <-> int using ASCII codes.
  char letter = 'C';
  std::cout << "'C' is code " << static_cast<int>(letter) << "\n";
  std::cout << "code 72 is '" << static_cast<char>(72) << "'\n";
  // A digit character to its number value: subtract '0'.
  char digit = '7';
  std::cout << "'7' - '0' = " << digit - '0' << "\n";

  // Numbers <-> text.
  std::string text = std::to_string(2026);
  std::cout << "to_string(2026) has " << text.size() << " characters\n";
  int year = std::stoi("2026");
  double pi = std::stod("3.14159");
  std::cout << "stoi(\"2026\") + 1 = " << year + 1 << ", stod(\"3.14159\") * 2 = " << pi * 2 << "\n";

  // bool <-> int
  bool isOn = true;
  std::cout << "true as a number: " << static_cast<int>(isOn) << ", 0 as bool: " << std::boolalpha
            << static_cast<bool>(0) << "\n";
  return 0;
}
