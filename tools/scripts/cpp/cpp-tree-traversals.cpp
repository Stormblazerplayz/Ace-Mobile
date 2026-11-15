// @title Tree Traversals: Pre, In, Post and Level Order
// @category Data structures
// @kind Console program
// @where Save as main.cpp and run: g++ -std=c++17 main.cpp -o traversals && ./traversals
// @keywords tree traversal, preorder inorder postorder, level order bfs tree, binary tree c++, expression tree
// @about Builds a small expression tree for (3 + 4) * (5 - 2) and visits it in four different orders.

#include <iostream>
#include <memory>
#include <queue>
#include <string>

struct Node {
  std::string label;
  std::unique_ptr<Node> left, right;
};

std::unique_ptr<Node> leaf(const std::string &s) {
  return std::make_unique<Node>(Node{s, nullptr, nullptr});
}

std::unique_ptr<Node> op(const std::string &s, std::unique_ptr<Node> l, std::unique_ptr<Node> r) {
  return std::make_unique<Node>(Node{s, std::move(l), std::move(r)});
}

// Pre-order: me, then left, then right. (Good for copying a tree.)
void preOrder(const Node *n) {
  if (!n) return;
  std::cout << n->label << " ";
  preOrder(n->left.get());
  preOrder(n->right.get());
}

// In-order: left, me, right. (Gives normal math order.)
void inOrder(const Node *n) {
  if (!n) return;
  bool isOp = n->left || n->right;
  if (isOp) std::cout << "( ";
  inOrder(n->left.get());
  std::cout << n->label << " ";
  inOrder(n->right.get());
  if (isOp) std::cout << ") ";
}

// Post-order: left, right, me. (Gives RPN, and is how you'd work out the answer.)
void postOrder(const Node *n) {
  if (!n) return;
  postOrder(n->left.get());
  postOrder(n->right.get());
  std::cout << n->label << " ";
}

double solve(const Node *n) {
  if (!n->left) return std::stod(n->label);
  double a = solve(n->left.get()), b = solve(n->right.get());
  if (n->label == "+") return a + b;
  if (n->label == "-") return a - b;
  if (n->label == "*") return a * b;
  return a / b;
}

int main() {
  /*        *
          /   \
         +     -
        / \   / \
       3   4 5   2      */
  auto root = op("*", op("+", leaf("3"), leaf("4")), op("-", leaf("5"), leaf("2")));

  std::cout << "Pre-order:   "; preOrder(root.get()); std::cout << "\n";
  std::cout << "In-order:    "; inOrder(root.get()); std::cout << "\n";
  std::cout << "Post-order:  "; postOrder(root.get()); std::cout << "\n";

  // Level order: row by row, using a queue.
  std::cout << "Level order: ";
  std::queue<const Node *> q;
  q.push(root.get());
  while (!q.empty()) {
    const Node *n = q.front();
    q.pop();
    std::cout << n->label << " ";
    if (n->left) q.push(n->left.get());
    if (n->right) q.push(n->right.get());
  }
  std::cout << "\nAnswer: " << solve(root.get()) << "\n";
  return 0;
}
