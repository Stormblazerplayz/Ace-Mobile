// @title Multiplication Table Grid
// @category Basics
// @kind Console program
// @where Save as main.cpp and run: g++ -std=c++17 main.cpp -o table && ./table
// @keywords c++ multiplication table, nested loops grid, times table chart, c++ setw table
// @about Prints a neat multiplication table grid using nested loops and setw to line up the columns.

#include <iomanip>
#include <iostream>

int main() {
  int size = 12;
  std::cout << "Table size (2 to 20): ";
  if (!(std::cin >> size) || size < 2 || size > 20) size = 12;
  std::cout << "\n";

  // Header row
  std::cout << "    |";
  for (int col = 1; col <= size; col++) std::cout << std::setw(4) << col;
  std::cout << "\n----+" << std::string(size * 4, '-') << "\n";

  // The outer loop picks the row, the inner loop fills the columns.
  for (int row = 1; row <= size; row++) {
    std::cout << std::setw(3) << row << " |";
    for (int col = 1; col <= size; col++) {
      std::cout << std::setw(4) << row * col;  // setw(4) = always use 4 spaces
    }
    std::cout << "\n";
  }
  return 0;
}
