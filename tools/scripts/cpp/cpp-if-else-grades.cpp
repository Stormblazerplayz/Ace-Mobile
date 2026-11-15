// @title Grade Checker with if and else
// @category Basics
// @kind Console program
// @where Save as main.cpp and run: g++ -std=c++17 main.cpp -o grades && ./grades
// @keywords c++ if else if, c++ grade checker, letter grade program, c++ conditions, logical and or
// @about Turns test scores into letter grades using if, else if and else, and shows && and || in action.

#include <iostream>

char letterGrade(int score) {
  if (score >= 90) return 'A';
  else if (score >= 80) return 'B';
  else if (score >= 70) return 'C';
  else if (score >= 60) return 'D';
  else return 'F';
}

int main() {
  std::cout << "Type test scores (0 to 100). Type -1 to stop.\n";
  int score;
  int count = 0;
  int total = 0;

  while (std::cin >> score && score != -1) {
    // || means OR: if either part is true, the whole thing is true.
    if (score < 0 || score > 100) {
      std::cout << "  That's not a real score.\n";
      continue;
    }
    char grade = letterGrade(score);
    std::cout << "  " << score << " is a " << grade;

    // && means AND: both parts must be true.
    if (score >= 95 && score <= 100) std::cout << " (amazing!)";
    else if (grade == 'F') std::cout << " (time to study)";
    std::cout << "\n";

    count++;
    total += score;
  }

  if (count > 0) {
    double average = static_cast<double>(total) / count;
    std::cout << "Average: " << average << " which is a " << letterGrade(static_cast<int>(average)) << "\n";
    // The ternary operator: condition ? valueIfTrue : valueIfFalse
    std::cout << (average >= 60 ? "Passing overall." : "Not passing yet.") << "\n";
  } else {
    std::cout << "No scores entered.\n";
  }
  return 0;
}
