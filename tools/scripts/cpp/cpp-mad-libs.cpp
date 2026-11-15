// @title Mad Libs Story Maker
// @category Games
// @kind Console program
// @where Save as main.cpp and run: g++ -std=c++17 main.cpp -o madlibs && ./madlibs
// @keywords mad libs, silly story generator, fill in the blanks, nouns verbs adjectives, string replace placeholders
// @about Asks you for nouns, verbs and adjectives, then drops them into a story to make something silly.

#include <iostream>
#include <string>
#include <vector>

int main() {
  // Each {0}, {1}... in the story gets replaced by the matching word you type.
  std::string story =
    "One {0} morning, my robot {1} decided to {2} all the way to the {3}. "
    "On the way it met a {4} {5} who said, \"{6}!\" "
    "So {1} built a giant {7} out of {8} and they lived {0}ly ever after.";
  std::vector<std::string> prompts = {"an adjective", "a funny name", "a verb", "a place", "a color",
                                      "an animal", "a silly word", "a noun", "a plural noun"};
  std::vector<std::string> words;

  std::cout << "Let's make a story! Don't peek, just type a word for each.\n";
  for (const std::string &p : prompts) {
    std::cout << "Give me " << p << ": ";
    std::string w;
    if (!std::getline(std::cin, w) || w.empty()) w = "banana";  // a backup word if you skip one
    words.push_back(w);
  }

  // Replace every {n} in the story.
  for (size_t i = 0; i < words.size(); i++) {
    std::string tag = "{" + std::to_string(i) + "}";
    for (size_t pos = story.find(tag); pos != std::string::npos; pos = story.find(tag, pos + words[i].size()))
      story.replace(pos, tag.size(), words[i]);
  }

  std::cout << "\n=== Your Story ===\n";
  int col = 0;
  for (char c : story) {  // wrap the lines at about 60 characters
    std::cout << c;
    if (++col > 60 && c == ' ') { std::cout << "\n"; col = 0; }
  }
  std::cout << "\n";
  return 0;
}
