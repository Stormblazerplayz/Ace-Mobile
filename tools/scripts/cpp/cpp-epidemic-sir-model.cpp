// @title How a Cold Spreads (SIR Model)
// @category Math and school
// @kind Console program
// @where Save as main.cpp and run: g++ -std=c++17 main.cpp -o sir && ./sir
// @keywords sir model, disease spread simulation, susceptible infected recovered, epidemic curve, flatten the curve
// @about Simulates a cold spreading through a school using the SIR model, and draws the infection curve day by day.

#include <iomanip>
#include <iostream>
#include <string>

int main() {
  double people = 1000, infected = 1, recovered = 0;
  double contacts = 0.4;  // chance per day of passing it on, per sick person
  double getWell = 0.1;   // fraction of sick people who get better each day (about 10 days sick)

  std::cout << "Spread rate per day (0.1 to 1, try 0.4 then 0.2): ";
  double typed;
  if (std::cin >> typed && typed >= 0.1 && typed <= 1) contacts = typed;

  double healthy = people - infected;
  double peak = 0;
  int peakDay = 0;
  std::cout << "R0 = " << contacts / getWell << " (each sick person infects this many at the start)\n\n";
  std::cout << "Day  Healthy   Sick  Better\n";
  for (int day = 0; day <= 120; day++) {
    if (infected > peak) { peak = infected; peakDay = day; }
    if (day % 4 == 0) {
      std::cout << std::setw(3) << day << std::setw(9) << static_cast<int>(healthy) << std::setw(7) << static_cast<int>(infected)
                << std::setw(8) << static_cast<int>(recovered) << " " << std::string(static_cast<int>(infected / 10), '#') << "\n";
    }
    // New infections need a sick person to meet a healthy one.
    double newSick = contacts * infected * healthy / people;
    double newBetter = getWell * infected;
    healthy -= newSick;
    infected += newSick - newBetter;
    recovered += newBetter;
  }
  std::cout << "\nThe most people sick at once was " << static_cast<int>(peak) << " on day " << peakDay << ".\n";
  std::cout << static_cast<int>(healthy) << " people never caught it.\n";
  std::cout << "Lower the spread rate (washing hands!) and the peak gets smaller: that's flattening the curve.\n";
  return 0;
}
