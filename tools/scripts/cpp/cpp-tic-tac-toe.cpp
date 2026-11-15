// @title Tic-Tac-Toe for Two Players
// @category Games
// @kind Console program
// @where Save as main.cpp and run: g++ -std=c++17 main.cpp -o game && ./game
// @keywords c++ tic tac toe, tic-tac-toe in c++, c++ noughts and crosses, two player game c++
// @about Two players take turns placing X and O on a 3 by 3 board until someone wins or it's a draw.

#include <array>
#include <iostream>
#include <sstream>
#include <string>

// The board: squares 1-9 start as their number.
std::array<char, 9> board = {'1', '2', '3', '4', '5', '6', '7', '8', '9'};

void drawBoard() {
  std::cout << "\n";
  for (int row = 0; row < 3; row++) {
    std::cout << " " << board[row * 3] << " | " << board[row * 3 + 1] << " | "
              << board[row * 3 + 2] << "\n";
    if (row < 2) std::cout << "---+---+---\n";
  }
  std::cout << "\n";
}

// Check every row, column and diagonal for three in a row.
bool hasWon(char player) {
  const int lines[8][3] = {{0, 1, 2}, {3, 4, 5}, {6, 7, 8},   // rows
                           {0, 3, 6}, {1, 4, 7}, {2, 5, 8},   // columns
                           {0, 4, 8}, {2, 4, 6}};             // diagonals
  for (const auto &line : lines) {
    if (board[line[0]] == player && board[line[1]] == player &&
        board[line[2]] == player) {
      return true;
    }
  }
  return false;
}

// Ask for a square number 1-9 that isn't taken yet.
// Returns -1 if the input is closed.
int askForSquare(char player) {
  std::string line;
  while (true) {
    std::cout << "Player " << player << ", pick a square (1-9): ";
    if (!std::getline(std::cin, line)) return -1;
    std::istringstream in(line);
    int square = 0;
    char extra;
    if (!(in >> square) || (in >> extra)) {
      std::cout << "Please type a number.\n";
    } else if (square < 1 || square > 9) {
      std::cout << "That square doesn't exist. Use 1 to 9.\n";
    } else if (board[square - 1] == 'X' || board[square - 1] == 'O') {
      std::cout << "That square is taken!\n";
    } else {
      return square - 1;
    }
  }
}

int main() {
  std::cout << "Tic-Tac-Toe! X goes first.\n";
  char player = 'X';

  for (int turn = 0; turn < 9; turn++) {
    drawBoard();
    int square = askForSquare(player);
    if (square < 0) return 0;
    board[square] = player;

    if (hasWon(player)) {
      drawBoard();
      std::cout << "Player " << player << " wins!\n";
      return 0;
    }
    player = (player == 'X') ? 'O' : 'X';  // swap turns
  }

  drawBoard();
  std::cout << "It's a draw!\n";
  return 0;
}
