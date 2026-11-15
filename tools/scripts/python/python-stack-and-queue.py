# @title Stacks and Queues
# @category Basics
# @kind Console program
# @where Save as stack_queue.py and run: python3 stack_queue.py
# @keywords python stack, python queue, python deque, python undo button, python last in first out
# @about Shows a stack (last in, first out) for an undo button and a queue (first in, first out) for a line of players.

from collections import deque

# STACK: like a pile of plates. You take from the top.
undo_stack = []
text = ""
for word in ["Hello", " there", " friend", " :)"]:
    undo_stack.append(text)  # save the old version
    text += word
    print("Typed:", repr(text))

for _ in range(2):
    text = undo_stack.pop()   # undo takes the most recent save
    print("Undo ->", repr(text))

# QUEUE: like a line at the store. First one in is first one out.
line = deque()
for player in ["Storm", "Doodle", "Nova", "Ace"]:
    line.append(player)
    print(player, "joined the line:", list(line))

while line:
    up_next = line.popleft()
    print(up_next, "is playing now. Still waiting:", list(line))

# Checking brackets is a classic stack problem
def balanced(code):
    pairs = {")": "(", "]": "[", "}": "{"}
    stack = []
    for ch in code:
        if ch in "([{":
            stack.append(ch)
        elif ch in pairs:
            if not stack or stack.pop() != pairs[ch]:
                return False
    return not stack

for code in ["print((1 + 2) * [3])", "{[}]", "((("]:
    print(code, "->", "balanced" if balanced(code) else "NOT balanced")
