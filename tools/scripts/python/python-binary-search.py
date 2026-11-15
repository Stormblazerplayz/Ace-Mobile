# @title Binary Search
# @category Basics
# @kind Console program
# @where Save as binary_search.py and run: python3 binary_search.py
# @keywords python binary search, python search sorted list, python divide and conquer, python bisect
# @about Finds a number in a sorted list by cutting the search area in half each step.

def binary_search(items, target):
    low, high = 0, len(items) - 1
    steps = 0
    while low <= high:
        steps += 1
        middle = (low + high) // 2
        print(f"  step {steps}: checking position {middle} (value {items[middle]})")
        if items[middle] == target:
            return middle, steps
        if items[middle] < target:
            low = middle + 1   # target is in the right half
        else:
            high = middle - 1  # target is in the left half
    return -1, steps


numbers = list(range(0, 1000, 3))  # 0, 3, 6, ... sorted!
for target in [588, 1, 999]:
    print(f"Looking for {target} in {len(numbers)} numbers:")
    position, steps = binary_search(numbers, target)
    if position == -1:
        print(f"  Not found after {steps} steps.\n")
    else:
        print(f"  Found at position {position} in just {steps} steps!\n")
