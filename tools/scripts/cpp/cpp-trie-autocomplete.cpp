// @title Autocomplete with a Trie
// @category Data structures
// @kind Console program
// @where Save as main.cpp and run: g++ -std=c++17 main.cpp -o autocomplete && ./autocomplete
// @keywords trie data structure, prefix tree, autocomplete c++, word suggestions, search by prefix
// @about Stores words in a trie (prefix tree) and suggests every word that starts with the letters you type.

#include <iostream>
#include <map>
#include <memory>
#include <string>
#include <vector>

struct TrieNode {
  std::map<char, std::unique_ptr<TrieNode>> children;  // one child per next letter
  bool endsWord = false;
};

class Trie {
public:
  void insert(const std::string &word) {
    TrieNode *node = &root_;
    for (char c : word) {
      auto &child = node->children[c];
      if (!child) child = std::make_unique<TrieNode>();
      node = child.get();
    }
    node->endsWord = true;
  }

  std::vector<std::string> startingWith(const std::string &prefix) const {
    const TrieNode *node = &root_;
    for (char c : prefix) {  // walk down the letters of the prefix
      auto it = node->children.find(c);
      if (it == node->children.end()) return {};
      node = it->second.get();
    }
    std::vector<std::string> found;
    collect(node, prefix, found);
    return found;
  }

private:
  TrieNode root_;

  // Visit every branch below this node and gather complete words.
  static void collect(const TrieNode *node, const std::string &sofar, std::vector<std::string> &out) {
    if (node->endsWord) out.push_back(sofar);
    for (const auto &[letter, child] : node->children) collect(child.get(), sofar + letter, out);
  }
};

int main() {
  Trie words;
  for (const char *w : {"arduino", "array", "arrow", "robot", "rocket", "rock", "roblox", "router",
                        "sensor", "servo", "server", "serial", "stepper", "steam"}) {
    words.insert(w);
  }

  std::cout << "Type the start of a word (Ctrl+D to quit). Try: ro, ser, ar, st\n";
  std::string prefix;
  while (std::cout << "> " && std::cin >> prefix) {
    auto matches = words.startingWith(prefix);
    if (matches.empty()) std::cout << "  no words start with \"" << prefix << "\"\n";
    for (const auto &m : matches) std::cout << "  " << m << "\n";
  }
  std::cout << "\n";
  return 0;
}
