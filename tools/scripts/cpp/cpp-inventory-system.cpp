// @title Game Inventory System
// @category Data structures
// @kind Console program
// @where Save as main.cpp and run: g++ -std=c++17 main.cpp -o inventory && ./inventory
// @keywords inventory system c++, game inventory map, item stacks, crafting recipe, map of structs
// @about A game inventory using a map of item stacks, with picking up, dropping, a weight limit and a simple crafting recipe.

#include <iomanip>
#include <iostream>
#include <map>
#include <string>

struct ItemInfo {
  double weight;
  int maxStack;
};

const std::map<std::string, ItemInfo> ITEMS = {
  {"wood", {1.0, 64}}, {"stone", {2.0, 64}}, {"stick", {0.5, 64}},
  {"pickaxe", {3.0, 1}}, {"apple", {0.3, 16}},
};

class Inventory {
public:
  bool add(const std::string &item, int count) {
    auto info = ITEMS.find(item);
    if (info == ITEMS.end()) { std::cout << "  Unknown item: " << item << "\n"; return false; }
    auto have = counts_.find(item);
    int already = have == counts_.end() ? 0 : have->second;  // find() doesn't add empty entries like [] does
    if (already + count > info->second.maxStack) { std::cout << "  Stack of " << item << " is full!\n"; return false; }
    if (weight() + info->second.weight * count > MAX_WEIGHT) { std::cout << "  Too heavy!\n"; return false; }
    counts_[item] += count;
    return true;
  }

  bool remove(const std::string &item, int count) {
    auto it = counts_.find(item);
    if (it == counts_.end() || it->second < count) return false;
    it->second -= count;
    if (it->second == 0) counts_.erase(it);
    return true;
  }

  bool has(const std::string &item, int count) const {
    auto it = counts_.find(item);
    return it != counts_.end() && it->second >= count;
  }

  double weight() const {
    double total = 0;
    for (const auto &[item, n] : counts_) total += ITEMS.at(item).weight * n;
    return total;
  }

  void show() const {
    std::cout << "  Inventory (" << std::fixed << std::setprecision(1) << weight() << "/" << MAX_WEIGHT << " kg):";
    if (counts_.empty()) std::cout << " empty";
    for (const auto &[item, n] : counts_) std::cout << " " << item << " x" << n << ";";
    std::cout << "\n";
  }

private:
  static constexpr double MAX_WEIGHT = 50.0;
  std::map<std::string, int> counts_;
};

// Recipe: 3 stone + 2 sticks = 1 pickaxe.
bool craftPickaxe(Inventory &inv) {
  if (!inv.has("stone", 3) || !inv.has("stick", 2)) return false;
  inv.remove("stone", 3);
  inv.remove("stick", 2);
  return inv.add("pickaxe", 1);
}

int main() {
  Inventory inv;
  std::cout << "Commands: add ITEM N, drop ITEM N, craft, show, quit\nItems: wood stone stick pickaxe apple\n";
  std::string cmd;
  while (std::cout << "> " && std::cin >> cmd && cmd != "quit") {
    if (cmd == "add" || cmd == "drop") {
      std::string item;
      int n;
      if (!(std::cin >> item >> n) || n <= 0) break;
      bool ok = cmd == "add" ? inv.add(item, n) : inv.remove(item, n);
      if (!ok && cmd == "drop") std::cout << "  You don't have that many.\n";
    } else if (cmd == "craft") {
      std::cout << (craftPickaxe(inv) ? "  Crafted a pickaxe!\n" : "  Need 3 stone and 2 sticks (and a free slot).\n");
    } else if (cmd != "show") {
      std::cout << "  Unknown command\n";
      continue;
    }
    inv.show();
  }
  return 0;
}
