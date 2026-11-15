// @title Temperature Converter
// @category Math and school
// @kind Console program
// @where Save as main.cpp and run: g++ -std=c++17 main.cpp -o tempconv && ./tempconv
// @keywords temperature converter, celsius to fahrenheit, fahrenheit to celsius, kelvin converter, conversion table c++
// @about Converts temperatures between Celsius, Fahrenheit and Kelvin, and prints a handy conversion table.

#include <cctype>
#include <iomanip>
#include <iostream>

double toCelsius(double value, char unit) {
  if (unit == 'F') return (value - 32) * 5.0 / 9.0;
  if (unit == 'K') return value - 273.15;
  return value;
}

int main() {
  std::cout << std::fixed << std::setprecision(1);
  std::cout << "Celsius  Fahrenheit\n";
  for (int c = -20; c <= 40; c += 10) std::cout << std::setw(6) << c << "  " << std::setw(9) << c * 9.0 / 5.0 + 32 << "\n";

  std::cout << "\nType a temperature and unit, like 100 C, 72 F or 300 K (Ctrl+D to stop):\n";
  double value;
  char unit;
  while (std::cin >> value >> unit) {
    unit = static_cast<char>(std::toupper(static_cast<unsigned char>(unit)));
    if (unit != 'C' && unit != 'F' && unit != 'K') {
      std::cout << "Use C, F or K.\n";
      continue;
    }
    double c = toCelsius(value, unit);
    if (c < -273.15) {
      std::cout << "That's colder than absolute zero, which is impossible!\n";
      continue;
    }
    std::cout << "= " << c << " C = " << c * 9.0 / 5.0 + 32 << " F = " << c + 273.15 << " K";
    if (c <= 0) std::cout << "  (water freezes)";
    else if (c >= 100) std::cout << "  (water boils)";
    std::cout << "\n";
  }
  return 0;
}
