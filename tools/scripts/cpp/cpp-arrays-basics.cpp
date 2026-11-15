// @title Arrays: Lists of Numbers
// @category Basics
// @kind Console program
// @where Save as main.cpp and run: g++ -std=c++17 main.cpp -o arrays && ./arrays
// @keywords c++ array, array loop c++, find biggest in array, array average c++, std array
// @about Stores a week of temperatures in an array, then finds the total, average, hottest and coldest day.

#include <array>
#include <iostream>
#include <string>

int main() {
  // A plain C-style array: 7 numbers in a row. Positions go from 0 to 6.
  int temps[7] = {18, 21, 25, 19, 23, 27, 22};
  const std::string days[7] = {"Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"};

  int total = 0;
  int hottest = 0;  // the POSITION of the hottest day
  int coldest = 0;
  for (int i = 0; i < 7; i++) {
    total += temps[i];
    if (temps[i] > temps[hottest]) hottest = i;
    if (temps[i] < temps[coldest]) coldest = i;
  }

  std::cout << "Day  Temp\n";
  for (int i = 0; i < 7; i++) {
    std::cout << days[i] << "  " << temps[i] << " C ";
    for (int b = 0; b < temps[i] / 2; b++) std::cout << '|';  // a little bar chart
    std::cout << "\n";
  }
  std::cout << "\nAverage: " << total / 7.0 << " C\n";
  std::cout << "Hottest: " << days[hottest] << " (" << temps[hottest] << " C)\n";
  std::cout << "Coldest: " << days[coldest] << " (" << temps[coldest] << " C)\n";

  // std::array is the modern version: it knows its own size and works with range-for.
  std::array<int, 5> lottery = {7, 13, 21, 34, 42};
  std::cout << "\nLottery numbers (" << lottery.size() << " of them):";
  for (int n : lottery) std::cout << " " << n;
  std::cout << "\n";

  // .at() checks the position for you, so a mistake gives an error instead of garbage.
  std::cout << "lottery.at(2) = " << lottery.at(2) << "\n";
  return 0;
}
