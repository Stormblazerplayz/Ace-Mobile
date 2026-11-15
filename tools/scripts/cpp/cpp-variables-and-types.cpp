// @title Variables and Data Types
// @category Basics
// @kind Console program
// @where Save as main.cpp and run: g++ -std=c++17 main.cpp -o types && ./types
// @keywords c++ variables, c++ data types, int double char bool, sizeof in c++, c++ beginner types
// @about Shows the main C++ variable types, how big they are, and what happens when you mix them.

#include <iostream>
#include <limits>
#include <string>

int main() {
  // A variable is a labeled box that holds one value of one type.
  int lives = 3;                 // whole numbers
  double speed = 12.5;           // numbers with a decimal point
  char grade = 'A';              // one letter, in single quotes
  bool hasKey = true;            // true or false
  std::string name = "Storm";    // text, in double quotes
  long long bigNumber = 9000000000LL;  // really big whole numbers

  std::cout << "lives = " << lives << "\n";
  std::cout << "speed = " << speed << "\n";
  std::cout << "grade = " << grade << "\n";
  std::cout << "hasKey = " << std::boolalpha << hasKey << "\n";
  std::cout << "name = " << name << "\n";
  std::cout << "bigNumber = " << bigNumber << "\n\n";

  // sizeof tells you how many bytes a type uses on this computer.
  std::cout << "int uses " << sizeof(int) << " bytes, biggest int: "
            << std::numeric_limits<int>::max() << "\n";
  std::cout << "double uses " << sizeof(double) << " bytes\n";
  std::cout << "char uses " << sizeof(char) << " byte\n\n";

  // Watch out: int divided by int throws away the remainder!
  int cookies = 7, friends = 2;
  std::cout << "7 / 2 with ints = " << cookies / friends << "\n";
  std::cout << "7 % 2 (the remainder) = " << cookies % friends << "\n";
  std::cout << "7.0 / 2 with a double = " << static_cast<double>(cookies) / friends << "\n";

  // A char is secretly a number (its ASCII code).
  std::cout << "'A' as a number is " << static_cast<int>(grade) << "\n";

  // const means the value can never change.
  const double PI = 3.14159;
  std::cout << "Area of a circle with radius 2: " << PI * 2 * 2 << "\n";
  return 0;
}
