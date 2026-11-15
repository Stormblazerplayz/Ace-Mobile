// @title Star Patterns with for Loops
// @category Basics
// @kind Console program
// @where Save as main.cpp and run: g++ -std=c++17 main.cpp -o patterns && ./patterns
// @keywords c++ star pattern, c++ pyramid, nested for loop pattern, c++ triangle of stars, diamond pattern c++
// @about Draws a triangle, a pyramid, a diamond and a checkerboard out of characters using nested for loops.

#include <iostream>

int main() {
  int size = 5;
  std::cout << "How big (1 to 15)? ";
  if (!(std::cin >> size) || size < 1 || size > 15) size = 5;

  std::cout << "\nRight triangle:\n";
  for (int row = 1; row <= size; row++) {
    for (int star = 0; star < row; star++) std::cout << '*';
    std::cout << '\n';
  }

  std::cout << "\nPyramid:\n";
  for (int row = 1; row <= size; row++) {
    for (int s = 0; s < size - row; s++) std::cout << ' ';   // spaces push it to the middle
    for (int s = 0; s < row * 2 - 1; s++) std::cout << '*';  // 1, 3, 5, 7 stars...
    std::cout << '\n';
  }

  std::cout << "\nDiamond:\n";
  for (int row = -size + 1; row < size; row++) {
    int width = size - (row < 0 ? -row : row);  // grows, then shrinks
    for (int s = 0; s < size - width; s++) std::cout << ' ';
    for (int s = 0; s < width * 2 - 1; s++) std::cout << '#';
    std::cout << '\n';
  }

  std::cout << "\nCheckerboard:\n";
  for (int row = 0; row < size; row++) {
    for (int col = 0; col < size * 2; col++) {
      std::cout << ((row + col) % 2 == 0 ? '#' : '.');
    }
    std::cout << '\n';
  }
  return 0;
}
