// @title LRU Cache (Least Recently Used)
// @category Data structures
// @kind Console program
// @where Save as main.cpp and run: g++ -std=c++17 main.cpp -o lru && ./lru
// @keywords lru cache, least recently used, list plus map, cache eviction, recently used items
// @about Builds a small cache that forgets the item used longest ago when it gets full, using a list and a map together.

#include <iostream>
#include <list>
#include <string>
#include <unordered_map>

class LRUCache {
public:
  explicit LRUCache(std::size_t capacity) : capacity_(capacity) {}

  // Returns true and fills value if the key is in the cache.
  bool get(const std::string &key, std::string &value) {
    auto it = where_.find(key);
    if (it == where_.end()) return false;
    order_.splice(order_.begin(), order_, it->second);  // move to the front: just used!
    value = it->second->second;
    return true;
  }

  void put(const std::string &key, const std::string &value) {
    auto it = where_.find(key);
    if (it != where_.end()) {
      it->second->second = value;
      order_.splice(order_.begin(), order_, it->second);
      return;
    }
    if (order_.size() == capacity_) {  // full: throw out the least recently used (the back)
      std::cout << "  (cache full, forgetting " << order_.back().first << ")\n";
      where_.erase(order_.back().first);
      order_.pop_back();
    }
    order_.push_front({key, value});
    where_[key] = order_.begin();
  }

  void show() const {
    std::cout << "  cache (newest first):";
    for (const auto &kv : order_) std::cout << " " << kv.first;
    std::cout << "\n";
  }

private:
  std::size_t capacity_;
  std::list<std::pair<std::string, std::string>> order_;  // front = most recently used
  std::unordered_map<std::string, std::list<std::pair<std::string, std::string>>::iterator> where_;
};

int main() {
  LRUCache cache(3);
  cache.put("cat.png", "picture of a cat");
  cache.put("dog.png", "picture of a dog");
  cache.put("map.png", "picture of a map");
  cache.show();

  std::string v;
  std::cout << "Look up cat.png: " << (cache.get("cat.png", v) ? v : "miss") << "\n";
  cache.show();

  cache.put("sun.png", "picture of the sun");  // dog.png is now the oldest, so it goes
  cache.show();
  std::cout << "Look up dog.png: " << (cache.get("dog.png", v) ? v : "miss (it was forgotten)") << "\n";
  return 0;
}
