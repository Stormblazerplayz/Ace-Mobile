// @title Dungeon Crawler on a Map
// @category Games
// @kind Console program
// @where Save as main.cpp and run: g++ -std=c++17 main.cpp -o crawler && ./crawler
// @keywords dungeon crawler, roguelike map, collect gold avoid traps, monsters chase player, ascii dungeon
// @about Explore an ASCII dungeon collecting gold while monsters chase you, then reach the stairs to escape.

#include <cstdlib>
#include <iostream>
#include <string>
#include <vector>

int main() {
  std::vector<std::string> map = {
    "##################",
    "#@...$....#.....$#",
    "#.####.##.#.###..#",
    "#.#..$.#....#M...#",
    "#.#.####.####.##.#",
    "#...#$...#....#..#",
    "###.#.##.#.##.#.##",
    "#M....#..$..#...>#",
    "##################",
  };
  int px = 1, py = 1, gold = 0, hp = 5;
  map[py][px] = '.';
  struct Mon { int x, y; };
  std::vector<Mon> mons;
  for (int y = 0; y < static_cast<int>(map.size()); y++)
    for (int x = 0; x < static_cast<int>(map[y].size()); x++)
      if (map[y][x] == 'M') { mons.push_back({x, y}); map[y][x] = '.'; }

  std::cout << "Collect gold ($), avoid monsters (M), reach the stairs (>). Move with w a s d.\n";
  while (true) {
    for (int y = 0; y < static_cast<int>(map.size()); y++) {
      std::string row = map[y];
      for (const Mon &m : mons) if (m.y == y) row[m.x] = 'M';
      if (y == py) row[px] = '@';
      std::cout << row << "\n";
    }
    std::cout << "HP " << hp << "  Gold " << gold << "  > ";
    char k;
    if (!(std::cin >> k)) { std::cout << "\nYou fall asleep in the dungeon.\n"; return 0; }
    int nx = px + (k == 'd') - (k == 'a'), ny = py + (k == 's') - (k == 'w');
    if (map[ny][nx] != '#') { px = nx; py = ny; }
    if (map[py][px] == '$') { gold += 10; map[py][px] = '.'; std::cout << "Gold! +10\n"; }
    if (map[py][px] == '>') { std::cout << "You escape with " << gold << " gold!\n"; return 0; }

    // Each monster takes one step toward you if that square isn't a wall.
    for (Mon &m : mons) {
      int dx = (px > m.x) - (px < m.x), dy = (py > m.y) - (py < m.y);
      if (std::abs(px - m.x) >= std::abs(py - m.y) && dx && map[m.y][m.x + dx] != '#') m.x += dx;
      else if (dy && map[m.y + dy][m.x] != '#') m.y += dy;
      else if (dx && map[m.y][m.x + dx] != '#') m.x += dx;
      if (m.x == px && m.y == py) {
        hp--;
        std::cout << "A monster bites you! -1 HP\n";
        m.x = m.y = 1;  // the monster gets knocked back to the corner
        while (map[m.y][m.x] == '#') m.x++;
      }
    }
    if (hp <= 0) { std::cout << "You were defeated with " << gold << " gold.\n"; return 0; }
  }
}
