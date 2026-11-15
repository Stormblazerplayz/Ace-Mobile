# @title Sorting Algorithms
# @category Basics
# @kind Console program
# @where Save as sorting.py and run: python3 sorting.py
# @keywords python bubble sort, python selection sort, python insertion sort, python sorting algorithm
# @about Writes bubble sort, selection sort and insertion sort by hand and checks them against sorted().

import random


def bubble_sort(items):
    items = items[:]  # work on a copy
    for end in range(len(items) - 1, 0, -1):
        for i in range(end):
            if items[i] > items[i + 1]:  # bigger one "bubbles" to the right
                items[i], items[i + 1] = items[i + 1], items[i]
    return items


def selection_sort(items):
    items = items[:]
    for i in range(len(items)):
        smallest = i
        for j in range(i + 1, len(items)):  # find the smallest in the rest
            if items[j] < items[smallest]:
                smallest = j
        items[i], items[smallest] = items[smallest], items[i]
    return items


def insertion_sort(items):
    items = items[:]
    for i in range(1, len(items)):
        current = items[i]
        j = i - 1
        while j >= 0 and items[j] > current:  # slide bigger ones right
            items[j + 1] = items[j]
            j -= 1
        items[j + 1] = current
    return items


numbers = [random.randint(1, 99) for _ in range(12)]
print("Start:     ", numbers)
print("Bubble:    ", bubble_sort(numbers))
print("Selection: ", selection_sort(numbers))
print("Insertion: ", insertion_sort(numbers))

# Test them on 100 random lists to be sure they work
for _ in range(100):
    data = [random.randint(-50, 50) for _ in range(random.randint(0, 20))]
    assert bubble_sort(data) == selection_sort(data) == insertion_sort(data) == sorted(data)
print("All three passed 100 tests!")
