// @title Structs: Grouping Data Together
// @category Basics
// @kind Console program
// @where Save as main.cpp and run: g++ -std=c++17 main.cpp -o structs && ./structs
// @keywords struct basics, struct vs class, vector of structs, c++ record type, group data c++
// @about Makes a Book struct, fills a list of books, then searches and prints them in a table.

#include <iomanip>
#include <iostream>
#include <string>
#include <vector>

// A struct bundles related values into one new type.
struct Book {
  std::string title;
  std::string author;
  int pages;
  bool finished;
};

void printBook(const Book &b) {
  std::cout << std::left << std::setw(24) << b.title << std::setw(18) << b.author
            << std::right << std::setw(5) << b.pages << "  " << (b.finished ? "read" : "to read") << "\n";
}

int main() {
  std::vector<Book> shelf = {
    {"The Hobbit", "J.R.R. Tolkien", 310, true},
    {"Wings of Fire", "Tui T. Sutherland", 336, true},
    {"Hatchet", "Gary Paulsen", 195, false},
    {"Percy Jackson", "Rick Riordan", 377, false},
  };

  // Add one more. You can set fields one at a time too.
  Book newBook;
  newBook.title = "Holes";
  newBook.author = "Louis Sachar";
  newBook.pages = 233;
  newBook.finished = false;
  shelf.push_back(newBook);

  std::cout << "My bookshelf:\n";
  for (const Book &b : shelf) printBook(b);

  int pagesRead = 0, pagesLeft = 0;
  const Book *longest = &shelf[0];
  for (const Book &b : shelf) {
    if (b.finished) pagesRead += b.pages;
    else pagesLeft += b.pages;
    if (b.pages > longest->pages) longest = &b;
  }
  std::cout << "\nPages read: " << pagesRead << ", pages to go: " << pagesLeft << "\n";
  std::cout << "Longest book: " << longest->title << "\n";

  // Finish a book by changing its field.
  shelf[2].finished = true;
  std::cout << "Just finished " << shelf[2].title << "!\n";
  return 0;
}
