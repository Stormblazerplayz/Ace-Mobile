// @title Reverse Polish Notation Calculator
// @category Data structures
// @kind Console program
// @where Save as main.cpp and run: g++ -std=c++17 main.cpp -o rpn && ./rpn
// @keywords rpn calculator, postfix notation, stack calculator, evaluate expression stack, reverse polish
// @about A calculator where you write the numbers first and the sign after (like 3 4 +), solved with a stack.

#include <cmath>
#include <iostream>
#include <sstream>
#include <stack>
#include <string>

// Returns true and sets result if the line is a valid RPN expression.
bool evaluate(const std::string &line, double &result, std::string &error) {
  std::stack<double> st;
  std::istringstream in(line);
  std::string token;
  while (in >> token) {
    if (token == "+" || token == "-" || token == "*" || token == "/" || token == "^") {
      if (st.size() < 2) { error = "not enough numbers for " + token; return false; }
      double b = st.top(); st.pop();  // careful: the top is the SECOND number
      double a = st.top(); st.pop();
      if (token == "+") st.push(a + b);
      else if (token == "-") st.push(a - b);
      else if (token == "*") st.push(a * b);
      else if (token == "^") st.push(std::pow(a, b));
      else {
        if (b == 0) { error = "can't divide by zero"; return false; }
        st.push(a / b);
      }
    } else {
      try {
        std::size_t used = 0;
        double v = std::stod(token, &used);
        if (used != token.size()) throw std::invalid_argument("junk");
        st.push(v);
      } catch (const std::exception &) {
        error = "\"" + token + "\" is not a number or a sign";
        return false;
      }
    }
  }
  if (st.size() != 1) { error = "should end with exactly one number"; return false; }
  result = st.top();
  return true;
}

int main() {
  std::cout << "RPN calculator. Examples:\n  3 4 +        (means 3 + 4)\n  5 1 2 + 4 * + 3 -   (means 5 + (1 + 2) * 4 - 3)\n"
            << "Type an expression (Ctrl+D to quit):\n";
  std::string line;
  while (std::cout << "> " && std::getline(std::cin, line)) {
    if (line.empty()) continue;
    double result;
    std::string error;
    if (evaluate(line, result, error)) std::cout << "= " << result << "\n";
    else std::cout << "Error: " << error << "\n";
  }
  std::cout << "\n";
  return 0;
}
