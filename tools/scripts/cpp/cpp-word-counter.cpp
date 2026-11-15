// @title Word and Sentence Counter
// @category Basics
// @kind Console program
// @where Save as main.cpp and run: g++ -std=c++17 main.cpp -o wordcount && ./wordcount, then type or paste text and press Ctrl+D (Ctrl+Z then Enter on Windows)
// @keywords word counter, count words in text c++, count sentences, essay word count, longest word c++
// @about Counts the words, sentences, letters and lines in text you type or paste, and finds the longest word.

#include <cctype>
#include <iostream>
#include <sstream>
#include <string>

int main() {
  std::cout << "Paste or type your text, then press Ctrl+D:\n";
  std::string line, all;
  int lines = 0;
  while (std::getline(std::cin, line)) {
    all += line + "\n";
    lines++;
  }

  int letters = 0, sentences = 0;
  for (char ch : all) {
    unsigned char c = static_cast<unsigned char>(ch);
    if (std::isalpha(c)) letters++;
    if (ch == '.' || ch == '!' || ch == '?') sentences++;
  }

  // Read word by word. Strip punctuation from the ends of each word.
  std::istringstream in(all);
  std::string word, longest;
  int words = 0;
  while (in >> word) {
    while (!word.empty() && std::ispunct(static_cast<unsigned char>(word.back()))) word.pop_back();
    while (!word.empty() && std::ispunct(static_cast<unsigned char>(word.front()))) word.erase(0, 1);
    if (word.empty()) continue;
    words++;
    if (word.size() > longest.size()) longest = word;
  }

  std::cout << "\nLines: " << lines << "\nWords: " << words << "\nLetters: " << letters
            << "\nSentences: " << sentences << "\n";
  if (words > 0) {
    std::cout << "Longest word: " << longest << " (" << longest.size() << " letters)\n";
    std::cout << "Average word length: " << static_cast<double>(letters) / words << " letters\n";
    // Most people read about 200 words a minute.
    std::cout << "Reading time: about " << (words + 199) / 200 << " minute(s)\n";
  }
  return 0;
}
