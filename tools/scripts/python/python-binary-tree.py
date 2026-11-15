# @title Binary Search Tree
# @category Basics
# @kind Console program
# @where Save as bst.py and run: python3 bst.py
# @keywords python binary tree, python binary search tree, python tree traversal, python insert search tree
# @about Builds a binary search tree where smaller values go left and bigger go right, then walks it in order.

class TreeNode:
    def __init__(self, value):
        self.value = value
        self.left = None
        self.right = None


def insert(node, value):
    if node is None:
        return TreeNode(value)
    if value < node.value:
        node.left = insert(node.left, value)
    else:
        node.right = insert(node.right, value)
    return node


def contains(node, value):
    while node is not None:
        if value == node.value:
            return True
        node = node.left if value < node.value else node.right
    return False


def in_order(node, out):
    """Left, me, right: this visits the values in sorted order."""
    if node:
        in_order(node.left, out)
        out.append(node.value)
        in_order(node.right, out)
    return out


def height(node):
    if node is None:
        return 0
    return 1 + max(height(node.left), height(node.right))


def show(node, depth=0):
    """Print the tree sideways (right side on top)."""
    if node:
        show(node.right, depth + 1)
        print("    " * depth + str(node.value))
        show(node.left, depth + 1)


root = None
for n in [50, 30, 70, 20, 40, 60, 80, 35]:
    root = insert(root, n)

show(root)
print("In order:", in_order(root, []))
print("Height:", height(root))
print("Has 60?", contains(root, 60), " Has 65?", contains(root, 65))
