// @title Enums: Naming Your Options
// @category Basics
// @kind Console program
// @where Save as main.cpp and run: g++ -std=c++17 main.cpp -o enums && ./enums
// @keywords c++ enum class, enumeration c++, scoped enum, enum to string c++, enum switch
// @about Uses enum class to name directions and weather types, then switches on them to make choices.

#include <iostream>
#include <string>

// An enum class is a list of named choices. Much clearer than using 0, 1, 2, 3!
enum class Direction { North, East, South, West };
enum class Weather { Sunny, Rainy, Snowy, Stormy };

std::string toString(Direction d) {
  switch (d) {
    case Direction::North: return "North";
    case Direction::East: return "East";
    case Direction::South: return "South";
    case Direction::West: return "West";
  }
  return "?";
}

// Turning right: North -> East -> South -> West -> North.
Direction turnRight(Direction d) {
  int next = (static_cast<int>(d) + 1) % 4;
  return static_cast<Direction>(next);
}

std::string advice(Weather w) {
  switch (w) {
    case Weather::Sunny: return "Wear sunscreen.";
    case Weather::Rainy: return "Bring an umbrella.";
    case Weather::Snowy: return "Build a snowman!";
    case Weather::Stormy: return "Stay inside and code.";
  }
  return "";
}

int main() {
  Direction facing = Direction::North;
  for (int i = 0; i < 5; i++) {
    std::cout << "Facing " << toString(facing) << "\n";
    facing = turnRight(facing);
  }

  std::cout << "\n";
  Weather days[] = {Weather::Sunny, Weather::Rainy, Weather::Stormy, Weather::Snowy};
  for (Weather w : days) std::cout << advice(w) << "\n";

  // Enum class values don't mix with ints by accident. This would NOT compile:
  //   int x = Direction::East;
  // You must say what you mean:
  int x = static_cast<int>(Direction::East);
  std::cout << "\nDirection::East is number " << x << "\n";
  return 0;
}
