// @title Leap Years and Day of the Week
// @category Math and school
// @kind Console program
// @where Save as main.cpp and run: g++ -std=c++17 main.cpp -o calendar && ./calendar
// @keywords leap year checker, day of the week finder, zeller congruence, print a month calendar, what day was i born
// @about Finds the day of the week for any date, checks leap years, and prints a calendar for that month.

#include <iomanip>
#include <iostream>

bool isLeap(int y) {
  // Every 4 years, except every 100, except every 400.
  return (y % 4 == 0 && y % 100 != 0) || y % 400 == 0;
}

int daysIn(int month, int year) {
  const int days[] = {31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31};
  return (month == 2 && isLeap(year)) ? 29 : days[month - 1];
}

// Zeller's congruence: 0 = Sunday, 1 = Monday ... 6 = Saturday
int dayOfWeek(int d, int m, int y) {
  if (m < 3) { m += 12; y--; }  // January and February count as months 13 and 14 of last year
  int k = y % 100, j = y / 100;
  int h = (d + 13 * (m + 1) / 5 + k + k / 4 + j / 4 + 5 * j) % 7;  // 0 = Saturday here
  return (h + 6) % 7;
}

int main() {
  const char *names[] = {"Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"};
  std::cout << "Type a date as day month year, like 4 7 1776 (Ctrl+D to stop): ";
  int d, m, y;
  while (std::cin >> d >> m >> y) {
    if (y < 1583 || y > 9999 || m < 1 || m > 12 || d < 1 || d > daysIn(m, y)) {
      std::cout << "That's not a real date (years 1583 to 9999).\nDate: ";
      continue;
    }
    std::cout << d << "/" << m << "/" << y << " is a " << names[dayOfWeek(d, m, y)] << ".\n";
    std::cout << y << (isLeap(y) ? " is" : " is not") << " a leap year.\n\n";

    std::cout << " Su Mo Tu We Th Fr Sa\n";
    int start = dayOfWeek(1, m, y);
    std::cout << std::string(start * 3, ' ');
    for (int day = 1; day <= daysIn(m, y); day++) {
      if (day == d) std::cout << std::setw(2) << day << "*";
      else std::cout << std::setw(3) << day;
      if ((start + day) % 7 == 0) std::cout << "\n";
    }
    std::cout << "\n\nDate: ";
  }
  std::cout << "\n";
  return 0;
}
