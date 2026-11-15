// @title Build Your Own Stack (Undo Button)
// @category Data structures
// @kind Console program
// @where Save as main.cpp and run: g++ -std=c++17 main.cpp -o stack && ./stack
// @keywords stack data structure, push pop peek, last in first out, lifo, undo with a stack
// @about Builds a Stack class template (last in, first out) and uses it as the undo button of a tiny text editor.

#include <iostream>
#include <stdexcept>
#include <string>
#include <vector>

template <typename T>
class Stack {
public:
  void push(const T &item) { items_.push_back(item); }  // put on top

  T pop() {  // take off the top
    if (empty()) throw std::runtime_error("pop on an empty stack");
    T top = items_.back();
    items_.pop_back();
    return top;
  }

  const T &peek() const {  // look at the top without taking it
    if (empty()) throw std::runtime_error("peek on an empty stack");
    return items_.back();
  }

  bool empty() const { return items_.empty(); }
  std::size_t size() const { return items_.size(); }

private:
  std::vector<T> items_;
};

int main() {
  std::string text;
  Stack<std::string> undo;  // remembers what the text looked like before each change

  std::cout << "Mini editor. Type a word to add it, 'undo' to undo, 'quit' to stop.\n";
  std::string word;
  while (std::cout << "text: \"" << text << "\"\n> " && std::cin >> word && word != "quit") {
    if (word == "undo") {
      if (undo.empty()) {
        std::cout << "Nothing to undo!\n";
      } else {
        text = undo.pop();
        std::cout << "Undone. (" << undo.size() << " undo steps left)\n";
      }
    } else {
      undo.push(text);  // save the old version first
      text += (text.empty() ? "" : " ") + word;
    }
  }

  // A stack reverses things: push 1,2,3 and pop gives 3,2,1.
  Stack<int> nums;
  for (int i = 1; i <= 5; i++) nums.push(i);
  std::cout << "\nPopping 1..5 gives:";
  while (!nums.empty()) std::cout << " " << nums.pop();
  std::cout << "\n";
  return 0;
}
