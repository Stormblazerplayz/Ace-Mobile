// @title Countdown Timer
// @category Basics
// @kind Console program
// @where Save as main.cpp and run: g++ -std=c++17 main.cpp -o timer && ./timer
// @keywords c++ countdown timer, c++ chrono timer, c++ sleep for seconds, c++ this_thread sleep_for
// @about Asks how many seconds to count down, ticks once a second, then shows how long it really took.

#include <chrono>
#include <iostream>
#include <sstream>
#include <string>
#include <thread>

int main() {
  int seconds = 0;
  std::string line;

  // Keep asking until we get a number from 1 to 3600.
  while (true) {
    std::cout << "Count down from how many seconds? (1-3600): ";
    if (!std::getline(std::cin, line)) return 0;  // input closed
    std::istringstream in(line);
    char extra;
    if (in >> seconds && !(in >> extra) && seconds >= 1 && seconds <= 3600) break;
    std::cout << "Please type a whole number from 1 to 3600.\n";
  }

  // Remember when we started.
  auto start = std::chrono::steady_clock::now();

  for (int left = seconds; left > 0; left--) {
    int minutes = left / 60;
    int secs = left % 60;
    // \r jumps back to the start of the line so the number updates in place.
    std::cout << "\r" << minutes << ":" << (secs < 10 ? "0" : "") << secs << "   " << std::flush;
    std::this_thread::sleep_for(std::chrono::seconds(1));
  }

  auto end = std::chrono::steady_clock::now();
  auto tookMs = std::chrono::duration_cast<std::chrono::milliseconds>(end - start).count();

  std::cout << "\r0:00   \nTime's up! Beep beep beep!\n";
  std::cout << "That really took " << tookMs / 1000.0 << " seconds.\n";
  return 0;
}
