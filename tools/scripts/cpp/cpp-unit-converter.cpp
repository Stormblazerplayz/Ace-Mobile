// @title Length and Weight Unit Converter
// @category Math and school
// @kind Console program
// @where Save as main.cpp and run: g++ -std=c++17 main.cpp -o units && ./units
// @keywords unit converter, metric to imperial, cm to inches, kg to pounds, miles to km
// @about Converts lengths and weights between metric and imperial units using a table of conversion factors.

#include <iostream>
#include <map>
#include <string>

int main() {
  // Every length unit in meters, every weight unit in grams.
  const std::map<std::string, double> length = {
    {"mm", 0.001}, {"cm", 0.01}, {"m", 1.0}, {"km", 1000.0},
    {"in", 0.0254}, {"ft", 0.3048}, {"yd", 0.9144}, {"mi", 1609.344},
  };
  const std::map<std::string, double> weight = {
    {"g", 1.0}, {"kg", 1000.0}, {"oz", 28.349523125}, {"lb", 453.59237},
  };

  std::cout << "Lengths: mm cm m km in ft yd mi    Weights: g kg oz lb\n";
  std::cout << "Type like: 5 ft cm   or   2.5 kg lb   (Ctrl+D to stop)\n";
  double amount;
  std::string from, to;
  while (std::cout << "> " && std::cin >> amount >> from >> to) {
    const std::map<std::string, double> *table = nullptr;
    if (length.count(from) && length.count(to)) table = &length;
    else if (weight.count(from) && weight.count(to)) table = &weight;

    if (!table) {
      std::cout << "Can't convert " << from << " to " << to << " (both must be lengths or both weights)\n";
      continue;
    }
    // Change to the base unit, then to the target unit.
    double result = amount * table->at(from) / table->at(to);
    std::cout << amount << " " << from << " = " << result << " " << to << "\n";
  }
  std::cout << "\n";
  return 0;
}
