// @title Balanced Brackets Checker
// @category Data structures
// @kind Console program
// @where Save as main.cpp and run: g++ -std=c++17 main.cpp -o brackets && ./brackets
// @keywords balanced parentheses, bracket matching stack, std stack, check brackets code, valid parentheses
// @about Uses std::stack to check whether all the ( ), [ ] and { } in a line match up correctly, like a compiler does.

#include <iostream>
#include <stack>
#include <string>

// Returns -1 if balanced, otherwise the position of the problem.
int findProblem(const std::string &text) {
  std::stack<std::pair<char, int>> open;  // the bracket and where it was
  for (int i = 0; i < static_cast<int>(text.size()); i++) {
    char c = text[i];
    if (c == '(' || c == '[' || c == '{') {
      open.push({c, i});
    } else if (c == ')' || c == ']' || c == '}') {
      if (open.empty()) return i;  // closing with nothing open
      char want = c == ')' ? '(' : (c == ']' ? '[' : '{');
      if (open.top().first != want) return i;  // wrong kind, like ( ]
      open.pop();
    }
  }
  if (!open.empty()) return open.top().second;  // something never got closed
  return -1;
}

int main() {
  std::string tests[] = {"if (x[0] == y) { go(); }", "((2 + 3) * 4", "{ [ ( ] ) }", "print(\"hi\"))"};
  for (const auto &t : tests) {
    int bad = findProblem(t);
    std::cout << t << "\n";
    if (bad < 0) std::cout << "  balanced!\n";
    else std::cout << "  " << std::string(bad, ' ') << "^ problem here\n";
  }

  std::cout << "\nNow type your own lines (Ctrl+D to stop):\n";
  std::string line;
  while (std::getline(std::cin, line)) {
    int bad = findProblem(line);
    if (bad < 0) std::cout << "  balanced!\n";
    else std::cout << line << "\n" << std::string(bad, ' ') << "^ problem here\n";
  }
  return 0;
}
