// @title Splitting Text with stringstream
// @category Basics
// @kind Console program
// @where Save as main.cpp and run: g++ -std=c++17 main.cpp -o parse && ./parse
// @keywords c++ stringstream, split string c++, parse numbers from text, istringstream, ostringstream
// @about Uses stringstreams to split sentences into words, read numbers out of text, and build strings.

#include <iostream>
#include <sstream>
#include <string>
#include <vector>

// Split text at every comma.
std::vector<std::string> split(const std::string &text, char separator) {
  std::vector<std::string> parts;
  std::istringstream in(text);
  std::string piece;
  while (std::getline(in, piece, separator)) parts.push_back(piece);
  return parts;
}

int main() {
  // 1. Words: >> skips spaces, so each read gets one word.
  std::istringstream sentence("the quick brown fox jumps");
  std::string word;
  int count = 0;
  while (sentence >> word) {
    std::cout << "word " << ++count << ": " << word << "\n";
  }

  // 2. Numbers mixed in text.
  std::istringstream data("10 20 30 40");
  int n, sum = 0;
  while (data >> n) sum += n;
  std::cout << "\nSum of \"10 20 30 40\" = " << sum << "\n";

  // 3. Comma separated values.
  std::vector<std::string> fields = split("Storm,12,robots,C++", ',');
  std::cout << "\nFields:\n";
  for (const auto &f : fields) std::cout << "  [" << f << "]\n";

  // 4. Read a command like "move 3 4".
  std::istringstream command("move 3 4");
  std::string action;
  int x = 0, y = 0;
  command >> action >> x >> y;
  std::cout << "\nAction: " << action << " to (" << x << ", " << y << ")\n";

  // 5. ostringstream builds a string the same way cout prints.
  std::ostringstream out;
  out << "Player at (" << x << "," << y << ") with " << sum << " points";
  std::string message = out.str();
  std::cout << "Built string: " << message << " (" << message.size() << " chars)\n";
  return 0;
}
