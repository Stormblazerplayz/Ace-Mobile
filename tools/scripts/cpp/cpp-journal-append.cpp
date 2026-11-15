// @title Diary that Saves to a File
// @category Basics
// @kind Console program
// @where Save as main.cpp and run: g++ -std=c++17 main.cpp -o diary && ./diary (it creates diary.txt next to it)
// @keywords append to file c++, ios app, c++ diary program, read all lines from file, ofstream append
// @about A little diary that adds your new entry to the end of diary.txt and then shows all the entries so far.

#include <fstream>
#include <iostream>
#include <string>

int main() {
  const std::string FILE_NAME = "diary.txt";

  std::cout << "What happened today? ";
  std::string entry;
  if (!std::getline(std::cin, entry) || entry.empty()) entry = "(nothing written)";

  // std::ios::app = "append": add to the end instead of wiping the file.
  std::ofstream out(FILE_NAME, std::ios::app);
  if (!out) {
    std::cout << "Could not open " << FILE_NAME << " for writing.\n";
    return 1;
  }
  out << entry << "\n";
  out.close();  // close it so everything is really saved

  // Now read the whole file back, line by line.
  std::ifstream in(FILE_NAME);
  std::string line;
  int number = 0;
  std::cout << "\n=== My Diary ===\n";
  while (std::getline(in, line)) {
    std::cout << ++number << ". " << line << "\n";
  }
  std::cout << "(" << number << " entries in " << FILE_NAME << ")\n";
  return 0;
}
