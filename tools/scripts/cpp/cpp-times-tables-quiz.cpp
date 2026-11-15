// @title Times Tables Quiz with a Timer
// @category Math and school
// @kind Console program
// @where Save as main.cpp and run: g++ -std=c++17 main.cpp -o timesquiz && ./timesquiz
// @keywords times tables quiz, multiplication practice, math flash cards c++, timed quiz, practice mistakes again
// @about Quizzes you on a times table you pick, times your answers, and asks the ones you got wrong again at the end.

#include <algorithm>
#include <chrono>
#include <iostream>
#include <random>
#include <vector>

int main() {
  std::cout << "Which times table do you want to practice (2 to 12)? ";
  int table = 7;
  if (!(std::cin >> table) || table < 2 || table > 12) table = 7;

  std::vector<int> questions;
  for (int i = 1; i <= 12; i++) questions.push_back(i);
  std::mt19937 rng(std::random_device{}());
  std::shuffle(questions.begin(), questions.end(), rng);

  std::vector<int> wrong;
  int correct = 0;
  auto start = std::chrono::steady_clock::now();
  for (int q : questions) {
    std::cout << q << " x " << table << " = ";
    int answer;
    if (!(std::cin >> answer)) { std::cout << "\nQuiz stopped.\n"; return 0; }
    if (answer == q * table) {
      correct++;
      std::cout << "  Yes!\n";
    } else {
      std::cout << "  Not quite, it's " << q * table << "\n";
      wrong.push_back(q);
    }
  }
  double seconds = std::chrono::duration<double>(std::chrono::steady_clock::now() - start).count();

  std::cout << "\nScore: " << correct << "/12 in " << static_cast<int>(seconds) << " seconds";
  std::cout << " (" << seconds / 12 << " s per question)\n";

  if (!wrong.empty()) {
    std::cout << "\nLet's try the tricky ones again:\n";
    for (int q : wrong) {
      std::cout << q << " x " << table << " = ";
      int answer;
      if (!(std::cin >> answer)) break;
      std::cout << (answer == q * table ? "  Got it this time!\n" : "  It's " + std::to_string(q * table) + ". Keep practicing!\n");
    }
  } else {
    std::cout << "Perfect score! Try a harder table.\n";
  }
  return 0;
}
