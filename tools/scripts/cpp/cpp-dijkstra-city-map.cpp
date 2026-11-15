// @title Shortest Route on a Map (Dijkstra)
// @category Data structures
// @kind Console program
// @where Save as main.cpp and run: g++ -std=c++17 main.cpp -o dijkstra && ./dijkstra
// @keywords dijkstra algorithm, shortest path graph, weighted graph c++, gps route finder, adjacency list
// @about Finds the shortest driving route between towns on a weighted map with Dijkstra's algorithm, like a GPS.

#include <climits>
#include <functional>
#include <iostream>
#include <queue>
#include <string>
#include <utility>
#include <vector>

int main() {
  std::vector<std::string> towns = {"Home", "School", "Park", "Mall", "Library", "Beach"};
  // Roads: each town has a list of (neighbor, minutes). This is an "adjacency list".
  std::vector<std::vector<std::pair<int, int>>> roads(towns.size());
  auto road = [&roads](int a, int b, int minutes) {
    roads[a].push_back({b, minutes});
    roads[b].push_back({a, minutes});  // two-way road
  };
  road(0, 1, 7); road(0, 2, 9); road(0, 5, 14); road(1, 2, 10);
  road(1, 3, 15); road(2, 3, 11); road(2, 5, 2); road(3, 4, 6); road(4, 5, 9);

  std::cout << "Towns:";
  for (std::size_t i = 0; i < towns.size(); i++) std::cout << " " << i << "=" << towns[i];
  std::cout << "\nFrom which town number? ";
  int from = 0;
  if (!(std::cin >> from) || from < 0 || from >= static_cast<int>(towns.size())) from = 0;

  std::vector<int> best(towns.size(), INT_MAX), cameFrom(towns.size(), -1);
  // A min priority queue of (minutes so far, town): always explore the closest town next.
  std::priority_queue<std::pair<int, int>, std::vector<std::pair<int, int>>, std::greater<>> next;
  best[from] = 0;
  next.push({0, from});
  while (!next.empty()) {
    auto [time, town] = next.top();
    next.pop();
    if (time > best[town]) continue;  // an old, slower entry: skip it
    for (auto [neighbor, minutes] : roads[town]) {
      if (time + minutes < best[neighbor]) {  // found a faster way!
        best[neighbor] = time + minutes;
        cameFrom[neighbor] = town;
        next.push({best[neighbor], neighbor});
      }
    }
  }

  std::cout << "\nFastest routes from " << towns[from] << ":\n";
  for (std::size_t t = 0; t < towns.size(); t++) {
    std::string route = towns[t];
    for (int at = cameFrom[t]; at != -1; at = cameFrom[at]) route = towns[at] + " > " + route;
    std::cout << "  " << towns[t] << ": " << best[t] << " min  (" << route << ")\n";
  }
  return 0;
}
