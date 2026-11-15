// @title Loops and If Statements
// @category Basics
// @kind Console program
// @where Save as main.cpp and run: g++ -std=c++17 main.cpp -o loops && ./loops
// @keywords c++ for loop, c++ while loop, c++ if else, c++ fizzbuzz, c++ hello world
// @about Says hello, then shows a for loop, a while loop and if/else with the FizzBuzz game.

#include <iostream>

int main() {
  // The classic first program.
  std::cout << "Hello, world!\n\n";

  // A for loop: start at 1, keep going while i <= 5, add 1 each time.
  std::cout << "Counting up: ";
  for (int i = 1; i <= 5; i++) {
    std::cout << i << " ";
  }
  std::cout << "\n";

  // A while loop: keep going while the condition is true.
  std::cout << "Doubling: ";
  int number = 1;
  while (number < 200) {
    std::cout << number << " ";
    number *= 2;
  }
  std::cout << "\n\n";

  // If / else if / else with FizzBuzz:
  // multiples of 3 say Fizz, of 5 say Buzz, of both say FizzBuzz.
  for (int i = 1; i <= 20; i++) {
    if (i % 15 == 0) {
      std::cout << "FizzBuzz\n";
    } else if (i % 3 == 0) {
      std::cout << "Fizz\n";
    } else if (i % 5 == 0) {
      std::cout << "Buzz\n";
    } else {
      std::cout << i << "\n";
    }
  }

  // A loop inside a loop makes a times table.
  std::cout << "\nTimes table:\n";
  for (int row = 1; row <= 5; row++) {
    for (int col = 1; col <= 5; col++) {
      int value = row * col;
      if (value < 10) std::cout << " ";  // line up the columns
      std::cout << value << " ";
    }
    std::cout << "\n";
  }
  return 0;
}
