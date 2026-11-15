// @title Treasure Hunt Hot and Cold
// @category Games
// @kind Console program
// @where Save as main.cpp and run: g++ -std=c++17 main.cpp -o treasure && ./treasure
// @keywords treasure hunt, hotter colder game, distance clue, hidden treasure map, grid search game
// @about Dig on a 10 by 10 island to find buried treasure, using "warmer" and "colder" clues to guide you.

#include <cmath>
#include <iostream>
#include <random>

int main() {
  std::mt19937 rng(std::random_device{}());
  std::uniform_int_distribution<int> spot(0, 9);
  int tx = spot(rng), ty = spot(rng);
  char map[10][10];
  for (auto &row : map) for (char &c : row) c = '~';

  std::cout << "Treasure is buried somewhere on the island! Dig by typing x y (0-9 each). 12 digs.\n";
  double lastDist = -1;
  for (int dig = 1; dig <= 12; dig++) {
    std::cout << "\n  0123456789\n";
    for (int y = 0; y < 10; y++) {
      std::cout << y << " ";
      for (int x = 0; x < 10; x++) std::cout << map[y][x];
      std::cout << "\n";
    }
    std::cout << "Dig " << dig << ": ";
    int x, y;
    if (!(std::cin >> x >> y)) break;
    if (x < 0 || x > 9 || y < 0 || y > 9) { std::cout << "That's in the sea!\n"; dig--; continue; }
    if (x == tx && y == ty) { std::cout << "\n*** You found the TREASURE in " << dig << " digs! ***\n"; return 0; }

    map[y][x] = 'x';
    double dist = std::hypot(x - tx, y - ty);  // straight-line distance
    if (dist <= 1.5) std::cout << "BURNING HOT! It's right next to you!\n";
    else if (dist <= 3) std::cout << "Hot!\n";
    else if (dist <= 5) std::cout << "Warm.\n";
    else std::cout << "Cold.\n";
    if (lastDist >= 0) std::cout << (dist < lastDist ? "(warmer than last time)\n" : dist > lastDist ? "(colder than last time)\n" : "(same as last time)\n");
    lastDist = dist;
  }
  std::cout << "\nOut of digs! The treasure was at " << tx << " " << ty << ".\n";
  return 0;
}
