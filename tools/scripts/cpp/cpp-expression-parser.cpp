// @title Math Expression Calculator (Shunting Yard)
// @category Data structures
// @kind Console program
// @where Save as main.cpp and run: g++ -std=c++17 main.cpp -o expr && ./expr
// @keywords shunting yard, infix to postfix, expression parser c++, operator precedence, calculator with brackets
// @about Reads normal math like 2 + 3 * (4 - 1), turns it into postfix with the shunting yard method, then works it out.

#include <cctype>
#include <iostream>
#include <stack>
#include <string>
#include <vector>

int precedence(char op) { return (op == '+' || op == '-') ? 1 : (op == '*' || op == '/') ? 2 : 0; }

// Step 1: turn "2+3*4" into the postfix list "2 3 4 * +". Returns false on a mistake.
bool toPostfix(const std::string &s, std::vector<std::string> &out) {
  std::stack<char> ops;
  for (std::size_t i = 0; i < s.size(); i++) {
    char c = s[i];
    if (std::isspace(static_cast<unsigned char>(c))) continue;
    if (std::isdigit(static_cast<unsigned char>(c)) || c == '.') {
      std::size_t j = i;
      while (j < s.size() && (std::isdigit(static_cast<unsigned char>(s[j])) || s[j] == '.')) j++;
      out.push_back(s.substr(i, j - i));
      i = j - 1;
    } else if (c == '(') {
      ops.push(c);
    } else if (c == ')') {
      while (!ops.empty() && ops.top() != '(') { out.push_back(std::string(1, ops.top())); ops.pop(); }
      if (ops.empty()) return false;  // a ) with no (
      ops.pop();
    } else if (precedence(c) > 0) {
      // Signs that bind tighter (or equal, left to right) leave the stack first.
      while (!ops.empty() && precedence(ops.top()) >= precedence(c)) { out.push_back(std::string(1, ops.top())); ops.pop(); }
      ops.push(c);
    } else {
      return false;  // unknown character
    }
  }
  while (!ops.empty()) {
    if (ops.top() == '(') return false;
    out.push_back(std::string(1, ops.top()));
    ops.pop();
  }
  return true;
}

// Step 2: work out the postfix list with a stack of numbers.
bool evaluate(const std::vector<std::string> &postfix, double &result) {
  std::stack<double> st;
  for (const auto &t : postfix) {
    if (precedence(t[0]) > 0 && t.size() == 1) {
      if (st.size() < 2) return false;
      double b = st.top(); st.pop();
      double a = st.top(); st.pop();
      if (t == "/" && b == 0) return false;
      st.push(t == "+" ? a + b : t == "-" ? a - b : t == "*" ? a * b : a / b);
    } else {
      try { st.push(std::stod(t)); } catch (const std::exception &) { return false; }
    }
  }
  if (st.size() != 1) return false;
  result = st.top();
  return true;
}

int main() {
  std::cout << "Type math like 2 + 3 * (4 - 1)  (Ctrl+D to quit)\n";
  std::string line;
  while (std::cout << "> " && std::getline(std::cin, line)) {
    if (line.empty()) continue;
    std::vector<std::string> postfix;
    double result;
    if (!toPostfix(line, postfix) || !evaluate(postfix, result)) {
      std::cout << "Sorry, I can't work that out.\n";
      continue;
    }
    std::cout << "postfix:";
    for (const auto &t : postfix) std::cout << " " << t;
    std::cout << "\n= " << result << "\n";
  }
  std::cout << "\n";
  return 0;
}
