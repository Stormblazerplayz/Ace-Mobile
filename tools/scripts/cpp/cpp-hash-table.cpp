// @title Hash Table from Scratch
// @category Data structures
// @kind Console program
// @where Save as main.cpp and run: g++ -std=c++17 main.cpp -o hashtable && ./hashtable
// @keywords hash table, hash function, chaining buckets, how hash maps work, collision handling
// @about Builds a simple hash table with buckets and chaining to show how unordered_map finds things so fast.

#include <iostream>
#include <list>
#include <string>
#include <utility>
#include <vector>

class HashTable {
public:
  explicit HashTable(std::size_t buckets) : buckets_(buckets) {}

  void put(const std::string &key, int value) {
    auto &bucket = buckets_[indexFor(key)];
    for (auto &pair : bucket) {
      if (pair.first == key) { pair.second = value; return; }  // update
    }
    bucket.push_back({key, value});  // new key goes on the bucket's chain
  }

  bool get(const std::string &key, int &out) const {
    for (const auto &pair : buckets_[indexFor(key)]) {
      if (pair.first == key) { out = pair.second; return true; }
    }
    return false;
  }

  void draw() const {
    for (std::size_t i = 0; i < buckets_.size(); i++) {
      std::cout << "  bucket " << i << ":";
      for (const auto &pair : buckets_[i]) std::cout << " [" << pair.first << "=" << pair.second << "]";
      std::cout << "\n";
    }
  }

private:
  std::vector<std::list<std::pair<std::string, int>>> buckets_;

  // A hash function turns a key into a number. Same key = same number, every time.
  std::size_t indexFor(const std::string &key) const {
    std::size_t hash = 5381;
    for (char c : key) hash = hash * 33 + static_cast<unsigned char>(c);  // the "djb2" hash
    return hash % buckets_.size();
  }
};

int main() {
  HashTable ages(5);  // only 5 buckets, so some keys will share (a "collision")
  ages.put("Ava", 12);
  ages.put("Leo", 13);
  ages.put("Kai", 11);
  ages.put("Mia", 12);
  ages.put("Zoe", 14);
  ages.put("Sam", 10);
  ages.put("Leo", 14);  // happy birthday Leo: updates the old value

  std::cout << "Inside the hash table:\n";
  ages.draw();

  for (const std::string name : {"Leo", "Sam", "Bob"}) {
    int age;
    if (ages.get(name, age)) std::cout << name << " is " << age << "\n";
    else std::cout << name << " is not in the table\n";
  }
  return 0;
}
