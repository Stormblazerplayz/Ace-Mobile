// @title Read and Total a CSV File
// @category Basics
// @kind Console program
// @where Save as main.cpp and run: g++ -std=c++17 main.cpp -o csv && ./csv (it writes a sample sales.csv first)
// @keywords c++ csv file, read csv c++, parse comma separated file, spreadsheet data c++, getline comma
// @about Writes a small CSV file of sales, then reads it back, splits each line at the commas, and totals it up.

#include <fstream>
#include <iomanip>
#include <iostream>
#include <map>
#include <sstream>
#include <string>

int main() {
  // Make a sample file so the program always has something to read.
  {
    std::ofstream out("sales.csv");
    out << "item,quantity,price\n"
        << "keychain,12,2.50\n"
        << "phone stand,4,6.00\n"
        << "keychain,8,2.50\n"
        << "dragon figure,2,15.00\n"
        << "this line is broken\n";
  }

  std::ifstream in("sales.csv");
  std::string line;
  std::getline(in, line);  // skip the header row

  std::map<std::string, double> earnedPerItem;
  double total = 0;
  int lineNumber = 1;
  while (std::getline(in, line)) {
    lineNumber++;
    std::istringstream row(line);
    std::string item, qtyText, priceText;
    if (!std::getline(row, item, ',') || !std::getline(row, qtyText, ',') || !std::getline(row, priceText)) {
      std::cout << "Skipping bad line " << lineNumber << ": " << line << "\n";
      continue;
    }
    try {
      double earned = std::stoi(qtyText) * std::stod(priceText);
      earnedPerItem[item] += earned;
      total += earned;
    } catch (const std::exception &) {
      std::cout << "Bad number on line " << lineNumber << "\n";
    }
  }

  std::cout << std::fixed << std::setprecision(2) << "\nSales by item:\n";
  for (const auto &[item, money] : earnedPerItem) {
    std::cout << "  " << std::left << std::setw(15) << item << "$" << money << "\n";
  }
  std::cout << "Total: $" << total << "\n";
  return 0;
}
