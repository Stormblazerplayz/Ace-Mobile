// @title Asking the User for Input
// @category Basics
// @kind Console program
// @where Save as main.cpp and run: g++ -std=c++17 main.cpp -o input && ./input
// @keywords c++ cin, c++ getline, read user input c++, cin and getline together, c++ input validation
// @about Asks for your full name, age and favorite number, checks the answers are valid, and talks back.

#include <iostream>
#include <limits>
#include <string>

int main() {
  std::string fullName;
  std::cout << "What is your full name? ";
  // getline reads the whole line, spaces and all. cin >> would stop at the first space.
  if (!std::getline(std::cin, fullName) || fullName.empty()) fullName = "Mystery Person";

  int age = 0;
  std::cout << "How old are you? ";
  // Keep asking until we get a real number.
  while (!(std::cin >> age) || age < 0 || age > 150) {
    if (std::cin.eof()) {  // no more input at all: stop asking
      age = 12;
      break;
    }
    std::cout << "Please type a number from 0 to 150: ";
    std::cin.clear();  // clear the error
    std::cin.ignore(std::numeric_limits<std::streamsize>::max(), '\n');  // throw away the bad line
  }

  double favorite = 7;
  std::cout << "What is your favorite number? ";
  if (!(std::cin >> favorite)) favorite = 7;

  std::cout << "\nNice to meet you, " << fullName << "!\n";
  std::cout << "In 10 years you will be " << age + 10 << ".\n";
  std::cout << "Your favorite number doubled is " << favorite * 2 << ".\n";
  if (age >= 13) {
    std::cout << "You're a teenager or older.\n";
  } else {
    std::cout << "You'll be a teenager in " << 13 - age << " year(s).\n";
  }
  return 0;
}
