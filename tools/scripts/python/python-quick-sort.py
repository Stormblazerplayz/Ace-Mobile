# @title Quick Sort
# @category Basics
# @kind Console program
# @where Save as quick_sort.py and run: python3 quick_sort.py
# @keywords python quick sort, python quicksort, python pivot, python partition sort
# @about Sorts a list by picking a pivot and putting smaller items on one side and bigger on the other.

import random


def quick_sort(items):
    if len(items) <= 1:
        return items
    pivot = random.choice(items)  # pick any item as the pivot
    smaller = [x for x in items if x < pivot]
    same = [x for x in items if x == pivot]
    bigger = [x for x in items if x > pivot]
    # sort each side, then glue them together
    return quick_sort(smaller) + same + quick_sort(bigger)


words = ["zebra", "apple", "mango", "kiwi", "banana", "cherry", "apple"]
print("Words:", quick_sort(words))

numbers = [random.randint(-20, 20) for _ in range(15)]
print("Before:", numbers)
print("After: ", quick_sort(numbers))

for _ in range(200):
    data = [random.randint(0, 9) for _ in range(random.randint(0, 30))]
    assert quick_sort(data) == sorted(data)
print("Passed 200 random tests!")
