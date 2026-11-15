# @title Linked List
# @category Basics
# @kind Console program
# @where Save as linked_list.py and run: python3 linked_list.py
# @keywords python linked list, python node class, python data structure, python next pointer
# @about Builds a linked list from Node objects that each point to the next one, like a conga line.

class Node:
    def __init__(self, value):
        self.value = value
        self.next = None  # the node after this one (None means the end)


class LinkedList:
    def __init__(self):
        self.head = None  # the first node

    def add_to_front(self, value):
        node = Node(value)
        node.next = self.head
        self.head = node

    def add_to_end(self, value):
        node = Node(value)
        if self.head is None:
            self.head = node
            return
        current = self.head
        while current.next is not None:  # walk to the last node
            current = current.next
        current.next = node

    def remove(self, value):
        if self.head and self.head.value == value:
            self.head = self.head.next
            return True
        current = self.head
        while current and current.next:
            if current.next.value == value:
                current.next = current.next.next  # skip over it
                return True
            current = current.next
        return False

    def __len__(self):
        count, current = 0, self.head
        while current:
            count += 1
            current = current.next
        return count

    def __str__(self):
        parts, current = [], self.head
        while current:
            parts.append(str(current.value))
            current = current.next
        return " -> ".join(parts + ["None"])


train = LinkedList()
for car in ["engine", "coal", "passengers", "caboose"]:
    train.add_to_end(car)
print(train)
train.add_to_front("cowcatcher")
train.remove("coal")
print(train)
print("Length:", len(train))
