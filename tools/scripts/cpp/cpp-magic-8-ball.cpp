// @title Magic 8 Ball
// @category Games
// @kind Console program
// @where Save as main.cpp and run: g++ -std=c++17 main.cpp -o eightball && ./eightball
// @keywords magic 8 ball, magic 8 ball console, fortune teller game, random answers, ask a yes no question, getline whole sentence
// @about Ask the Magic 8 Ball any yes-or-no question and it gives you one of twenty mysterious answers.

#include <iostream>
#include <random>
#include <string>

int main() {
  const std::string answers[] = {
    "It is certain.", "Without a doubt.", "Yes, definitely.", "You may rely on it.", "As I see it, yes.",
    "Most likely.", "Outlook good.", "Yes.", "Signs point to yes.", "Reply hazy, try again.",
    "Ask again later.", "Better not tell you now.", "Cannot predict now.", "Concentrate and ask again.",
    "Don't count on it.", "My reply is no.", "My sources say no.", "Outlook not so good.", "Very doubtful.",
    "The robots say... maybe.",
  };
  std::mt19937 rng(std::random_device{}());
  std::uniform_int_distribution<int> pick(0, 19);

  std::cout << "I am the Magic 8 Ball. Ask me a yes or no question! (empty line or Ctrl+D to stop)\n";
  std::string question;
  while (std::cout << "\nYour question: " && std::getline(std::cin, question) && !question.empty()) {
    if (question.back() != '?') std::cout << "(That doesn't sound like a question, but I'll answer anyway.)\n";
    std::cout << "*shake shake shake*\n";
    std::cout << "The 8 Ball says: " << answers[pick(rng)] << "\n";
  }
  std::cout << "\nThe 8 Ball goes back to sleep. (Remember: it's just random!)\n";
  return 0;
}
