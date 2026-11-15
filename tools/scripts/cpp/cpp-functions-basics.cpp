// @title Writing Your Own Functions
// @category Basics
// @kind Console program
// @where Save as main.cpp and run: g++ -std=c++17 main.cpp -o functions && ./functions
// @keywords c++ functions, return value c++, function parameters, void function c++, function prototype
// @about Shows functions that take inputs, return answers, return nothing (void), and call other functions.

#include <iostream>
#include <string>

// A prototype tells the compiler a function exists before we write it.
int square(int n);

// void = this function does a job but gives nothing back.
void sayHello(const std::string &name) {
  std::cout << "Hello, " << name << "!\n";
}

// Takes two numbers in, gives one number back.
int add(int a, int b) {
  return a + b;
}

// Returns true or false. Functions like this often start with "is".
bool isEven(int n) {
  return n % 2 == 0;
}

// Functions can call other functions.
int sumOfSquares(int a, int b) {
  return add(square(a), square(b));
}

double average(double a, double b, double c) {
  return (a + b + c) / 3.0;
}

int main() {
  sayHello("Storm");
  sayHello("Ace");

  std::cout << "add(3, 4) = " << add(3, 4) << "\n";
  std::cout << "square(9) = " << square(9) << "\n";
  std::cout << "sumOfSquares(3, 4) = " << sumOfSquares(3, 4) << "\n";
  std::cout << "average(80, 92, 77) = " << average(80, 92, 77) << "\n";

  for (int i = 1; i <= 5; i++) {
    std::cout << i << (isEven(i) ? " is even\n" : " is odd\n");
  }
  return 0;
}

// The real body of square, written after main.
int square(int n) {
  return n * n;
}
