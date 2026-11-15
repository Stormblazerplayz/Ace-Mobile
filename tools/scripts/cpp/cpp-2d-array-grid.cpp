// @title 2D Arrays: a Game Map Grid
// @category Basics
// @kind Console program
// @where Save as main.cpp and run: g++ -std=c++17 main.cpp -o grid && ./grid
// @keywords c++ 2d array, grid map c++, rows and columns array, nested loop 2d, tile map c++
// @about Stores a little game map in a 2D array of characters, prints it, counts the coins, and moves a player around.

#include <iostream>

const int ROWS = 6;
const int COLS = 10;

void printMap(const char map[ROWS][COLS + 1]) {
  for (int r = 0; r < ROWS; r++) {
    for (int c = 0; c < COLS; c++) std::cout << map[r][c];
    std::cout << "\n";
  }
}

int main() {
  // Each row is a string of 10 characters (+1 hidden end marker).
  char map[ROWS][COLS + 1] = {
    "##########",
    "#P...$...#",
    "#.##.##..#",
    "#..$...#$#",
    "#....$...#",
    "##########",
  };

  printMap(map);

  // Count the coins ($) by visiting every row and every column.
  int coins = 0;
  int playerRow = 0, playerCol = 0;
  for (int r = 0; r < ROWS; r++) {
    for (int c = 0; c < COLS; c++) {
      if (map[r][c] == '$') coins++;
      if (map[r][c] == 'P') { playerRow = r; playerCol = c; }
    }
  }
  std::cout << "\nCoins on the map: " << coins << "\n";
  std::cout << "Player is at row " << playerRow << ", column " << playerCol << "\n";

  // Try to move the player right 4 times, but never through a wall.
  int collected = 0;
  for (int step = 0; step < 4; step++) {
    int nextCol = playerCol + 1;
    if (map[playerRow][nextCol] == '#') break;  // wall: stop
    if (map[playerRow][nextCol] == '$') collected++;
    map[playerRow][playerCol] = '.';
    playerCol = nextCol;
    map[playerRow][playerCol] = 'P';
  }
  std::cout << "\nAfter walking right (collected " << collected << " coins):\n";
  printMap(map);
  return 0;
}
