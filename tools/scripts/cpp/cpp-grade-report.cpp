// @title Class Grade Report
// @category Math and school
// @kind Console program
// @where Save as main.cpp and run: g++ -std=c++17 main.cpp -o grades && ./grades
// @keywords grade report, class test scores, letter grade a b c, top student, report card c++
// @about Reads student names and test scores, then prints a sorted report card with averages, letter grades and a bar chart.

#include <algorithm>
#include <iomanip>
#include <iostream>
#include <sstream>
#include <string>
#include <vector>

struct Student {
  std::string name;
  std::vector<double> scores;
  double average = 0;
};

char letter(double avg) {
  if (avg >= 90) return 'A';
  if (avg >= 80) return 'B';
  if (avg >= 70) return 'C';
  if (avg >= 60) return 'D';
  return 'F';
}

int main() {
  std::cout << "Type one student per line: name then scores, like  Storm 95 88 100\n";
  std::cout << "Press Ctrl+D when done.\n";
  std::vector<Student> students;
  std::string line;
  while (std::getline(std::cin, line)) {
    std::istringstream in(line);
    Student s;
    if (!(in >> s.name)) continue;
    double x;
    while (in >> x) s.scores.push_back(std::clamp(x, 0.0, 100.0));
    if (s.scores.empty()) { std::cout << "(" << s.name << " has no scores, skipped)\n"; continue; }
    double sum = 0;
    for (double v : s.scores) sum += v;
    s.average = sum / s.scores.size();
    students.push_back(s);
  }
  if (students.empty()) {
    students = {{"Ada", {95, 90}, 92.5}, {"Ben", {72, 80}, 76}, {"Cy", {55, 68}, 61.5}};
    std::cout << "No students typed, so here's a sample class.\n";
  }

  std::sort(students.begin(), students.end(), [](const Student &a, const Student &b) { return a.average > b.average; });

  std::cout << "\n" << std::left << std::setw(12) << "Name" << "Avg    Grade\n";
  double classTotal = 0;
  for (const Student &s : students) {
    std::cout << std::left << std::setw(12) << s.name << std::fixed << std::setprecision(1) << std::setw(7)
              << s.average << letter(s.average) << "  " << std::string(static_cast<size_t>(s.average / 5), '#') << "\n";
    classTotal += s.average;
  }
  std::cout << "\nClass average: " << classTotal / students.size() << "\n";
  std::cout << "Top of the class: " << students.front().name << "!\n";
  return 0;
}
