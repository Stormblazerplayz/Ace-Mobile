// @title Typing Speed Test
// @category Games
// @kind Console program
// @where Save as main.cpp and run: g++ -std=c++17 main.cpp -o typing && ./typing
// @keywords typing speed test, words per minute, typing accuracy, keyboard practice, chrono stopwatch typing
// @about Times how fast you type a sentence and works out your words per minute and accuracy.

#include <algorithm>
#include <chrono>
#include <iostream>
#include <random>
#include <string>
#include <vector>

int main() {
  std::vector<std::string> sentences = {
    "the quick brown fox jumps over the lazy dog",
    "my robot can drive around the room and avoid walls",
    "arduino boards read sensors and control motors",
    "practice every day and your typing will get faster",
  };
  std::mt19937 rng(std::random_device{}());
  std::shuffle(sentences.begin(), sentences.end(), rng);

  for (int round = 0; round < 3; round++) {
    const std::string &target = sentences[round];
    std::cout << "\nType this, then press Enter:\n  " << target << "\n> ";
    auto start = std::chrono::steady_clock::now();
    std::string typed;
    if (!std::getline(std::cin, typed)) break;
    double seconds = std::chrono::duration<double>(std::chrono::steady_clock::now() - start).count();
    if (seconds < 0.5) seconds = 0.5;

    // Accuracy: compare letter by letter.
    size_t same = 0;
    for (size_t i = 0; i < std::min(typed.size(), target.size()); i++) if (typed[i] == target[i]) same++;
    double accuracy = 100.0 * same / std::max(typed.size(), target.size());

    // Typists count every 5 characters as one "word".
    double wpm = (typed.size() / 5.0) / (seconds / 60.0);
    std::cout << "Time: " << seconds << " s   Speed: " << static_cast<int>(wpm) << " words per minute   Accuracy: "
              << static_cast<int>(accuracy) << "%\n";
    if (typed == target) std::cout << "Perfect match!\n";
  }
  std::cout << "\nTip: keep your fingers on the home row (asdf jkl;) and don't look at the keys!\n";
  return 0;
}
