// @title Battleship vs the Computer
// @category Games
// @kind Console program
// @where Save as main.cpp and run: g++ -std=c++17 main.cpp -o battleship && ./battleship
// @keywords battleship, sink the ships, grid guessing game, hit or miss, naval battle game
// @about Find and sink the computer's hidden ships on an 8 by 8 grid by calling out coordinates like B4.

#include <cctype>
#include <iostream>
#include <random>
#include <string>

const int N = 8;
char ships[N][N];  // 'S' = ship, '.' = water
char shots[N][N];  // what you've seen: 'X' hit, 'o' miss, '.' unknown

void placeShips(std::mt19937 &rng) {
  for (auto &row : ships) for (char &c : row) c = '.';
  const int sizes[] = {4, 3, 3, 2};
  std::uniform_int_distribution<int> pos(0, N - 1), coin(0, 1);
  for (int size : sizes) {
    while (true) {  // keep trying random spots until the ship fits without overlapping
      bool across = coin(rng);
      int r = pos(rng), c = pos(rng);
      if ((across ? c : r) + size > N) continue;
      bool clear = true;
      for (int i = 0; i < size; i++) if (ships[across ? r : r + i][across ? c + i : c] != '.') clear = false;
      if (!clear) continue;
      for (int i = 0; i < size; i++) ships[across ? r : r + i][across ? c + i : c] = 'S';
      break;
    }
  }
}

void draw() {
  std::cout << "\n   1 2 3 4 5 6 7 8\n";
  for (int r = 0; r < N; r++) {
    std::cout << ' ' << static_cast<char>('A' + r) << ' ';
    for (int c = 0; c < N; c++) std::cout << shots[r][c] << ' ';
    std::cout << "\n";
  }
}

int main() {
  std::mt19937 rng(std::random_device{}());
  placeShips(rng);
  for (auto &row : shots) for (char &c : row) c = '.';
  int shipCells = 4 + 3 + 3 + 2, hits = 0, torpedoes = 40;

  std::cout << "Ships of size 4, 3, 3 and 2 are hidden. You have 40 torpedoes.\n";
  while (hits < shipCells && torpedoes > 0) {
    draw();
    std::cout << "Torpedoes left: " << torpedoes << ". Fire at (like B4): ";
    std::string target;
    if (!(std::cin >> target)) break;
    if (target.size() < 2) continue;
    int r = std::toupper(static_cast<unsigned char>(target[0])) - 'A';
    int c = target[1] - '1';
    if (r < 0 || r >= N || c < 0 || c >= N) { std::cout << "Off the map! Use A-H and 1-8.\n"; continue; }
    if (shots[r][c] != '.') { std::cout << "You already fired there.\n"; continue; }
    torpedoes--;
    if (ships[r][c] == 'S') { shots[r][c] = 'X'; hits++; std::cout << "HIT!\n"; }
    else { shots[r][c] = 'o'; std::cout << "Splash, a miss.\n"; }
  }

  draw();
  if (hits == shipCells) std::cout << "You sank the whole fleet with " << torpedoes << " torpedoes to spare!\n";
  else {
    std::cout << "Out of torpedoes (or game stopped). The ships were here:\n";
    for (int r = 0; r < N; r++) { for (int c = 0; c < N; c++) std::cout << ships[r][c] << ' '; std::cout << "\n"; }
  }
  return 0;
}
