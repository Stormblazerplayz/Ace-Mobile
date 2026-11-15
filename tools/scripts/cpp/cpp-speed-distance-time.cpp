// @title Speed Distance Time Solver
// @category Math and school
// @kind Console program
// @where Save as main.cpp and run: g++ -std=c++17 main.cpp -o sdt && ./sdt
// @keywords speed distance time, average speed, travel time calculator, km per hour, physics triangle
// @about Solves speed, distance and time problems by finding whichever one you don't know.

#include <iostream>
#include <string>

int main() {
  std::cout << "Speed = distance / time.  Type ? for the one you don't know.\n";
  std::cout << "Type distance (km), time (hours) and speed (km/h), like:  120 ? 60\n(Ctrl+D to stop)\n";
  std::string d, t, s;
  while (std::cout << "> " && std::cin >> d >> t >> s) {
    int unknowns = (d == "?") + (t == "?") + (s == "?");
    if (unknowns != 1) { std::cout << "Put exactly one ?\n"; continue; }
    try {
      if (d == "?") {
        double time = std::stod(t), speed = std::stod(s);
        std::cout << "Distance = speed x time = " << speed * time << " km\n";
      } else if (t == "?") {
        double dist = std::stod(d), speed = std::stod(s);
        if (speed <= 0) { std::cout << "Speed must be more than 0.\n"; continue; }
        double hours = dist / speed;
        int h = static_cast<int>(hours), m = static_cast<int>((hours - h) * 60 + 0.5);
        if (m == 60) { h++; m = 0; }
        std::cout << "Time = distance / speed = " << hours << " hours (" << h << " h " << m << " min)\n";
      } else {
        double dist = std::stod(d), time = std::stod(t);
        if (time <= 0) { std::cout << "Time must be more than 0.\n"; continue; }
        std::cout << "Speed = distance / time = " << dist / time << " km/h (" << dist / time / 3.6 << " m/s)\n";
      }
    } catch (const std::exception &) {
      std::cout << "Please type numbers (or ?).\n";
    }
  }
  std::cout << "\n";
  return 0;
}
