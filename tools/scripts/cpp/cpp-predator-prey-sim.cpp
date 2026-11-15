// @title Foxes and Rabbits Simulation
// @category Games
// @kind Console program
// @where Save as main.cpp and run: g++ -std=c++17 main.cpp -o ecosystem && ./ecosystem
// @keywords predator prey simulation, foxes and rabbits, population cycles, lotka volterra, ecosystem balance
// @about Simulates rabbits and foxes over 120 seasons, showing how the two populations rise and fall in cycles.

#include <iomanip>
#include <iostream>
#include <string>

int main() {
  double rabbits = 100, foxes = 10;
  std::cout << "Starting rabbits (10-500): ";
  double r0;
  if (std::cin >> r0 && r0 >= 10 && r0 <= 500) rabbits = r0;
  std::cout << "Starting foxes (1-100): ";
  double f0;
  if (std::cin >> f0 && f0 >= 1 && f0 <= 100) foxes = f0;

  // Lotka-Volterra: rabbits breed, foxes eat rabbits, foxes need rabbits to survive.
  const double rabbitBirth = 0.10, eaten = 0.002, foxBirth = 0.0005, foxDeath = 0.08;
  std::cout << "\nSeason  Rabbits  Foxes   (R = rabbits, F = foxes)\n";
  for (int season = 0; season <= 120; season++) {
    if (season % 2 == 0) {
      std::string chart(60, ' ');
      int r = std::min(59, static_cast<int>(rabbits / 10));
      int f = std::min(59, static_cast<int>(foxes));
      chart[r] = 'R';
      chart[f] = (chart[f] == 'R') ? '*' : 'F';
      std::cout << std::setw(6) << season << std::setw(9) << static_cast<int>(rabbits) << std::setw(7)
                << static_cast<int>(foxes) << "  |" << chart << "\n";
    }
    double newRabbits = rabbits + rabbitBirth * rabbits - eaten * rabbits * foxes;
    double newFoxes = foxes + foxBirth * rabbits * foxes - foxDeath * foxes;
    rabbits = std::max(0.0, newRabbits);
    foxes = std::max(0.0, newFoxes);
    if (rabbits < 1 && foxes < 1) { std::cout << "Everything died out!\n"; break; }
  }
  std::cout << "\nMore rabbits -> more food -> more foxes -> fewer rabbits -> fewer foxes... and round again!\n";
  return 0;
}
