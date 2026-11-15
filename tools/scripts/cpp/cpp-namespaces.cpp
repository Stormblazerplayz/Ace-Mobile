// @title Namespaces: Keeping Names Apart
// @category Basics
// @kind Console program
// @where Save as main.cpp and run: g++ -std=c++17 main.cpp -o namespaces && ./namespaces
// @keywords c++ namespace, what is std::, using namespace std, name clash c++, nested namespace
// @about Puts same-named functions into different namespaces so they don't clash, and explains what std:: means.

#include <iostream>
#include <string>

// Two teams both want a function called "speed".
namespace cars {
  double speed(double distanceKm, double hours) { return distanceKm / hours; }
  const std::string UNIT = "km/h";
}

namespace robots {
  double speed(double distanceCm, double seconds) { return distanceCm / seconds; }
  const std::string UNIT = "cm/s";

  // Namespaces can go inside other namespaces.
  namespace sensors {
    int range() { return 400; }
  }
}

int main() {
  // The :: says which namespace to look in.
  std::cout << "Car: " << cars::speed(150, 2) << " " << cars::UNIT << "\n";
  std::cout << "Robot: " << robots::speed(90, 3) << " " << robots::UNIT << "\n";
  std::cout << "Sensor range: " << robots::sensors::range() << " cm\n";

  // "std" is the namespace of the C++ standard library. That's why we write std::cout.
  // "using" lets you skip the prefix for one name inside this function:
  using robots::UNIT;
  std::cout << "Using robots::UNIT directly: " << UNIT << "\n";

  // You may see "using namespace std;" in examples. It's ok in tiny programs,
  // but in big projects it can cause name clashes, so many people avoid it.
  return 0;
}
