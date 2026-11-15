// @title Binary Search Tree
// @category Data structures
// @kind Console program
// @where Save as main.cpp and run: g++ -std=c++17 main.cpp -o bst && ./bst
// @keywords binary search tree, bst insert search, tree traversal inorder, tree height c++, unique_ptr tree
// @about Builds a binary search tree of numbers, searches it, prints it in sorted order and draws its shape sideways.

#include <iostream>
#include <memory>

struct TreeNode {
  int value;
  std::unique_ptr<TreeNode> left;   // smaller numbers go left
  std::unique_ptr<TreeNode> right;  // bigger numbers go right
  explicit TreeNode(int v) : value(v) {}
};

class BST {
public:
  void insert(int v) { insert(root_, v); }
  bool contains(int v) const {
    const TreeNode *cur = root_.get();
    while (cur) {
      if (v == cur->value) return true;
      cur = v < cur->value ? cur->left.get() : cur->right.get();  // go left or right
    }
    return false;
  }
  void printSorted() const { inOrder(root_.get()); std::cout << "\n"; }
  int height() const { return height(root_.get()); }
  void draw() const { draw(root_.get(), 0); }

private:
  std::unique_ptr<TreeNode> root_;

  static void insert(std::unique_ptr<TreeNode> &node, int v) {
    if (!node) { node = std::make_unique<TreeNode>(v); return; }
    if (v < node->value) insert(node->left, v);
    else if (v > node->value) insert(node->right, v);
    // equal: already in the tree, do nothing
  }
  // In-order (left, me, right) visits the numbers smallest to biggest.
  static void inOrder(const TreeNode *n) {
    if (!n) return;
    inOrder(n->left.get());
    std::cout << n->value << " ";
    inOrder(n->right.get());
  }
  static int height(const TreeNode *n) {
    if (!n) return 0;
    int l = height(n->left.get()), r = height(n->right.get());
    return 1 + (l > r ? l : r);
  }
  // Draw sideways: right side on top, root on the left edge.
  static void draw(const TreeNode *n, int depth) {
    if (!n) return;
    draw(n->right.get(), depth + 1);
    std::cout << std::string(depth * 4, ' ') << n->value << "\n";
    draw(n->left.get(), depth + 1);
  }
};

int main() {
  BST tree;
  for (int v : {50, 30, 70, 20, 40, 60, 80, 35, 65}) tree.insert(v);

  std::cout << "Sorted: ";
  tree.printSorted();
  std::cout << "Height: " << tree.height() << "\n";
  std::cout << "Tree (turn your head left!):\n";
  tree.draw();

  std::cout << "\nType numbers to search for (Ctrl+D to stop):\n";
  int n;
  while (std::cin >> n) {
    std::cout << n << (tree.contains(n) ? " is in the tree\n" : " is not in the tree\n");
  }
  return 0;
}
