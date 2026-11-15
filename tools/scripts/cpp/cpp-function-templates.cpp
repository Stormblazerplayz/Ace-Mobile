// @title Function Templates
// @category Basics
// @kind Console program
// @where Save as main.cpp and run: g++ -std=c++17 main.cpp -o templates && ./templates
// @keywords c++ templates, function template, generic function c++, typename t, template any type
// @about Writes one function that works for ints, doubles and strings by using templates.

#include <iostream>
#include <string>
#include <vector>

// "template <typename T>" means: T can be any type. The compiler makes a copy for each type you use.
template <typename T>
T biggest(const T &a, const T &b) {
  return (a > b) ? a : b;
}

template <typename T>
void printList(const std::vector<T> &items) {
  std::cout << "[ ";
  for (const T &item : items) std::cout << item << " ";
  std::cout << "]\n";
}

template <typename T>
T sum(const std::vector<T> &items) {
  T total{};  // {} makes a "zero" of any type: 0 for int, "" for string
  for (const T &item : items) total += item;
  return total;
}

// Two different template types.
template <typename A, typename B>
void showPair(const A &first, const B &second) {
  std::cout << "(" << first << ", " << second << ")\n";
}

int main() {
  std::cout << "biggest(3, 9) = " << biggest(3, 9) << "\n";
  std::cout << "biggest(2.5, 1.5) = " << biggest(2.5, 1.5) << "\n";
  std::cout << "biggest(\"apple\", \"pear\") = " << biggest(std::string("apple"), std::string("pear")) << "\n\n";

  std::vector<int> scores = {10, 20, 30};
  std::vector<double> prices = {1.25, 3.5, 0.75};
  std::vector<std::string> words = {"tem", "pla", "tes"};

  printList(scores);
  printList(prices);
  printList(words);

  std::cout << "sum of scores = " << sum(scores) << "\n";
  std::cout << "sum of prices = " << sum(prices) << "\n";
  std::cout << "sum of words = " << sum(words) << "  (strings add by joining!)\n\n";

  showPair("level", 7);
  showPair(3.14, 'x');
  return 0;
}
