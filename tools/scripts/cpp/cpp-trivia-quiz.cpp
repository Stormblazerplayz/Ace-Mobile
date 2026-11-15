// @title Science Trivia Quiz
// @category Games
// @kind Console program
// @where Save as main.cpp and run: g++ -std=c++17 main.cpp -o trivia && ./trivia
// @keywords trivia quiz, multiple choice questions, science quiz game, quiz with score, struct of questions
// @about A multiple-choice science and tech quiz that shuffles its questions, keeps score and explains each answer.

#include <algorithm>
#include <cctype>
#include <iostream>
#include <random>
#include <string>
#include <vector>

struct Question {
  std::string text;
  std::string options[4];
  char answer;  // 'a', 'b', 'c' or 'd'
  std::string why;
};

int main() {
  std::vector<Question> quiz = {
    {"What does LED stand for?", {"Light Emitting Diode", "Low Energy Device", "Laser Electric Dot", "Long Electron Drive"}, 'a',
     "A diode only lets current flow one way, and this one gives off light."},
    {"Which planet is the biggest?", {"Saturn", "Earth", "Jupiter", "Neptune"}, 'c', "Jupiter is over 11 times wider than Earth."},
    {"How many bits are in a byte?", {"4", "8", "10", "16"}, 'b', "8 bits make a byte, so a byte holds 0 to 255."},
    {"What pulls things toward the Earth?", {"Magnetism", "Friction", "Static", "Gravity"}, 'd', "Gravity pulls all masses together."},
    {"Ohm's law: Voltage = Current x ...?", {"Power", "Resistance", "Time", "Charge"}, 'b', "V = I x R."},
    {"What gas do plants breathe in?", {"Oxygen", "Helium", "Carbon dioxide", "Nitrogen"}, 'c', "Plants use CO2 and sunlight to make food."},
    {"Which is NOT a programming language?", {"Python", "Lua", "Swift", "HTML5 Turbo"}, 'd', "Python, Lua and Swift are all real languages."},
    {"Sound travels fastest through...", {"Air", "Water", "Steel", "Space"}, 'c', "Sound moves fastest through solids; in space it can't travel at all."},
  };
  std::mt19937 rng(std::random_device{}());
  std::shuffle(quiz.begin(), quiz.end(), rng);

  int score = 0, asked = 0;
  for (const Question &q : quiz) {
    std::cout << "\n" << q.text << "\n";
    for (int i = 0; i < 4; i++) std::cout << "  " << static_cast<char>('a' + i) << ") " << q.options[i] << "\n";
    std::cout << "Answer: ";
    char a;
    if (!(std::cin >> a)) break;
    asked++;
    a = static_cast<char>(std::tolower(static_cast<unsigned char>(a)));
    if (a == q.answer) { score++; std::cout << "Correct! "; }
    else std::cout << "Nope, it's " << q.answer << ". ";
    std::cout << q.why << "\n";
  }
  std::cout << "\nYou scored " << score << " out of " << asked << ".\n";
  if (asked > 0 && score == asked) std::cout << "Perfect! You're a science genius!\n";
  return 0;
}
