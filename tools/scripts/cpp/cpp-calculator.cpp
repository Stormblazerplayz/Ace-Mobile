// @title Simple Calculator
// @category Basics
// @kind Console program
// @where Save as main.cpp and run: g++ -std=c++17 main.cpp -o calc && ./calc
// @keywords c++ calculator, simple calculator in c++, c++ add subtract multiply divide, c++ math program
// @about Type something like 12 * 3 and it gives you the answer, until you type q.

#include <cmath>
#include <iostream>
#include <sstream>
#include <string>

int main() {
  std::cout << "Calculator! Type things like 7 + 5 or 9 / 2. Use + - * / % ^\n"
            << "Type q to quit.\n";

  std::string line;
  while (true) {
    std::cout << "\n> ";
    if (!std::getline(std::cin, line)) break;  // input closed
    if (line == "q" || line == "quit") break;

    // Split the line into: number, operator, number.
    std::istringstream in(line);
    double a = 0, b = 0;
    char op = 0, extra = 0;
    if (!(in >> a >> op >> b) || (in >> extra)) {
      std::cout << "I didn't get that. Try: 3 + 4\n";
      continue;
    }

    double answer = 0;
    bool ok = true;
    switch (op) {
      case '+': answer = a + b; break;
      case '-': answer = a - b; break;
      case '*': case 'x': answer = a * b; break;
      case '/':
        if (b == 0) { std::cout << "You can't divide by zero!\n"; ok = false; }
        else answer = a / b;
        break;
      case '%':
        if (b == 0) { std::cout << "You can't divide by zero!\n"; ok = false; }
        else answer = std::fmod(a, b);
        break;
      case '^': answer = std::pow(a, b); break;
      default:
        std::cout << "I don't know the '" << op << "' sign. Use + - * / % ^\n";
        ok = false;
    }

    if (ok) std::cout << "= " << answer << "\n";
  }

  std::cout << "Bye!\n";
  return 0;
}
