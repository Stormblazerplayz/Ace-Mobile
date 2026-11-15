# @title Merge Sort
# @category Basics
# @kind Console program
# @where Save as merge_sort.py and run: python3 merge_sort.py
# @keywords python merge sort, python recursive sort, python split and merge, python fast sorting
# @about Sorts a list by splitting it in half again and again, then merging the halves back in order.

import random


def merge(left, right):
    """Join two sorted lists into one sorted list."""
    result = []
    i = j = 0
    while i < len(left) and j < len(right):
        if left[i] <= right[j]:
            result.append(left[i])
            i += 1
        else:
            result.append(right[j])
            j += 1
    result.extend(left[i:])   # whatever is left over is already sorted
    result.extend(right[j:])
    return result


def merge_sort(items):
    if len(items) <= 1:  # a list of 0 or 1 items is already sorted
        return items
    middle = len(items) // 2
    return merge(merge_sort(items[:middle]), merge_sort(items[middle:]))


numbers = [random.randint(1, 100) for _ in range(15)]
print("Before:", numbers)
print("After: ", merge_sort(numbers))

big = [random.random() for _ in range(50000)]
print("Sorted 50,000 numbers correctly?", merge_sort(big) == sorted(big))
