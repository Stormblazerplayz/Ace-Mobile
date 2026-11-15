// @title Read and Write a Text File
// @category Basics
// @kind Console program
// @where Save as main.cpp and run: g++ -std=c++17 main.cpp -o notes && ./notes (it makes notes.txt in the same folder).
// @keywords c++ read and write file, c++ fstream, c++ save to text file, c++ ofstream ifstream, load a file in c++
// @about Adds a note you type to notes.txt, then reads the whole file back and prints it.

#include <fstream>
#include <iostream>
#include <string>

const std::string FILE_NAME = "notes.txt";

int main() {
  // Ask for a note.
  std::cout << "Type a note to save: ";
  std::string note;
  if (!std::getline(std::cin, note) || note.empty()) {
    std::cout << "No note typed, nothing saved.\n";
  } else {
    // std::ios::app means "add to the end" instead of wiping the file.
    std::ofstream out(FILE_NAME, std::ios::app);
    if (!out) {
      std::cout << "Couldn't open " << FILE_NAME << " for writing.\n";
      return 1;
    }
    out << note << "\n";
    std::cout << "Saved!\n";
  }  // the file closes by itself here

  // Read the file back, one line at a time.
  std::ifstream in(FILE_NAME);
  if (!in) {
    std::cout << "There's no " << FILE_NAME << " yet.\n";
    return 0;
  }

  std::cout << "\n--- Everything in " << FILE_NAME << " ---\n";
  std::string line;
  int lineNumber = 1;
  while (std::getline(in, line)) {
    std::cout << lineNumber << ": " << line << "\n";
    lineNumber++;
  }
  std::cout << "--- Total notes: " << (lineNumber - 1) << " ---\n";
  return 0;
}
