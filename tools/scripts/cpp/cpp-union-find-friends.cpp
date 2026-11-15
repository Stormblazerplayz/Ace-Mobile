// @title Friend Groups with Union Find
// @category Data structures
// @kind Console program
// @where Save as main.cpp and run: g++ -std=c++17 main.cpp -o friendgroups && ./friendgroups
// @keywords union find, disjoint set, friend groups, connected groups c++, path compression
// @about Uses a union-find (disjoint set) to work out which kids are in the same friend group, even through friends of friends.

#include <iostream>
#include <map>
#include <numeric>
#include <string>
#include <vector>

class UnionFind {
public:
  explicit UnionFind(int n) : parent_(n), size_(n, 1) {
    std::iota(parent_.begin(), parent_.end(), 0);  // everyone starts as their own group leader
  }

  // Find the group leader. Path compression makes later finds super fast.
  int find(int x) {
    if (parent_[x] != x) parent_[x] = find(parent_[x]);
    return parent_[x];
  }

  void unite(int a, int b) {
    int ra = find(a), rb = find(b);
    if (ra == rb) return;
    if (size_[ra] < size_[rb]) std::swap(ra, rb);  // small group joins the big group
    parent_[rb] = ra;
    size_[ra] += size_[rb];
  }

private:
  std::vector<int> parent_, size_;
};

int main() {
  std::vector<std::string> kids = {"Ava", "Ben", "Cai", "Dee", "Eli", "Fay", "Gus", "Hana"};
  UnionFind groups(static_cast<int>(kids.size()));

  // Pairs who are friends.
  std::vector<std::pair<int, int>> friendships = {{0, 1}, {1, 4}, {2, 3}, {5, 6}, {6, 2}};
  for (auto [a, b] : friendships) {
    std::cout << kids[a] << " and " << kids[b] << " are friends\n";
    groups.unite(a, b);
  }

  std::cout << "\nAre Ava and Eli in the same group? "
            << (groups.find(0) == groups.find(4) ? "yes (through Ben)" : "no") << "\n";
  std::cout << "Are Ava and Dee in the same group? " << (groups.find(0) == groups.find(3) ? "yes" : "no") << "\n";

  std::map<int, std::vector<std::string>> byLeader;
  for (int i = 0; i < static_cast<int>(kids.size()); i++) byLeader[groups.find(i)].push_back(kids[i]);
  std::cout << "\nFriend groups:\n";
  for (const auto &[leader, members] : byLeader) {
    std::cout << " -";
    for (const auto &m : members) std::cout << " " << m;
    std::cout << "\n";
  }
  return 0;
}
