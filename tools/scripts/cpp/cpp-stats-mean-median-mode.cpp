// @title Mean Median Mode Calculator
// @category Math and school
// @kind Console program
// @where Save as main.cpp and run: g++ -std=c++17 main.cpp -o stats && ./stats
// @keywords mean median mode, average calculator, range and standard deviation, statistics homework, data set summary
// @about Reads a list of numbers and works out the mean, median, mode, range and standard deviation.

#include <algorithm>
#include <cmath>
#include <iostream>
#include <map>
#include <vector>

int main() {
  std::cout << "Type numbers, then press Ctrl+D:\n";
  std::vector<double> data;
  double x;
  while (std::cin >> x) data.push_back(x);
  if (data.empty()) {
    std::cout << "No numbers, so nothing to work out. Try: 3 7 7 2 9\n";
    return 0;
  }

  std::sort(data.begin(), data.end());
  size_t n = data.size();

  double sum = 0;
  for (double d : data) sum += d;
  double mean = sum / n;  // mean = add them all, divide by how many

  // Median = the middle one when sorted (or the average of the middle two).
  double median = (n % 2 == 1) ? data[n / 2] : (data[n / 2 - 1] + data[n / 2]) / 2;

  // Mode = the one that shows up most often.
  std::map<double, int> counts;
  int best = 0;
  for (double d : data) best = std::max(best, ++counts[d]);

  double squares = 0;
  for (double d : data) squares += (d - mean) * (d - mean);
  double stdev = std::sqrt(squares / n);

  std::cout << "Sorted:";
  for (double d : data) std::cout << " " << d;
  std::cout << "\nCount:  " << n << "\nMean:   " << mean << "\nMedian: " << median << "\nMode:  ";
  if (best == 1) std::cout << " none (every number appears once)";
  else for (auto &[value, count] : counts) if (count == best) std::cout << " " << value;
  std::cout << "\nRange:  " << data.back() - data.front() << " (from " << data.front() << " to " << data.back() << ")\n";
  std::cout << "Standard deviation: " << stdev << " (how spread out the numbers are)\n";
  return 0;
}
