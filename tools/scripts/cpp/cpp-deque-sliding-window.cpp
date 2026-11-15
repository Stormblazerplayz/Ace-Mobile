// @title std::deque: Rolling Average of Sensor Readings
// @category Data structures
// @kind Console program
// @where Save as main.cpp and run: g++ -std=c++17 main.cpp -o rolling && ./rolling
// @keywords std deque, double ended queue, sliding window average, push_front push_back, rolling maximum
// @about Uses a deque to keep the last 5 sensor readings for a rolling average and a fast rolling maximum.

#include <deque>
#include <iostream>
#include <vector>

int main() {
  std::vector<int> readings = {12, 15, 11, 30, 28, 9, 14, 40, 13, 12, 11, 18};
  const std::size_t WINDOW = 5;

  std::deque<int> window;       // the last 5 readings
  std::deque<std::size_t> maxQ; // positions that could still be the biggest, biggest at the front
  int sum = 0;

  for (std::size_t i = 0; i < readings.size(); i++) {
    int r = readings[i];

    // Add the new reading at the back, drop the oldest from the front.
    window.push_back(r);
    sum += r;
    if (window.size() > WINDOW) {
      sum -= window.front();
      window.pop_front();
    }

    // Rolling max trick: smaller readings behind a new big one can never be the max again.
    while (!maxQ.empty() && readings[maxQ.back()] <= r) maxQ.pop_back();
    maxQ.push_back(i);
    if (maxQ.front() + WINDOW <= i) maxQ.pop_front();  // too old, out of the window

    std::cout << "reading " << r << "\twindow [";
    for (std::size_t k = 0; k < window.size(); k++) std::cout << (k ? " " : "") << window[k];
    std::cout << "]\tavg " << static_cast<double>(sum) / window.size() << "\tmax " << readings[maxQ.front()] << "\n";
  }

  // A deque can grow at BOTH ends.
  std::deque<char> word = {'o', 'b', 'o'};
  word.push_front('r');
  word.push_back('t');
  std::cout << "\nBuilt from both ends: ";
  for (char c : word) std::cout << c;
  std::cout << "\n";
  return 0;
}
