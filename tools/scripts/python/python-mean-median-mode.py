# @title Mean, Median and Mode
# @category Math and school
# @kind Console program
# @where Save as averages.py and run: python3 averages.py
# @keywords python mean median mode, python statistics module, python average of numbers, python range data
# @about Works out the mean, median, mode and range of any list of numbers, showing how each one is found.

import statistics

text = input("Type numbers separated by spaces (Enter for an example): ").split()
try:
    numbers = [float(t) for t in text] if text else [3, 7, 7, 2, 9, 4, 7, 5, 2]
except ValueError:
    raise SystemExit("Only numbers please.")

ordered = sorted(numbers)
print("Numbers in order:", [f"{n:g}" for n in ordered])

mean = sum(numbers) / len(numbers)
print(f"\nMean (add them up and divide by how many): {sum(numbers):g} / {len(numbers)} = {mean:.3g}")

middle = len(ordered) // 2
if len(ordered) % 2:
    print(f"Median (the middle one): {ordered[middle]:g}")
else:
    print(f"Median (average of the two middle ones): ({ordered[middle - 1]:g} + {ordered[middle]:g}) / 2 = {statistics.median(ordered):g}")

modes = statistics.multimode(numbers)  # every value that shows up the most
if len(modes) == len(set(numbers)):
    print("Mode: none (every number shows up the same number of times)")
else:
    print(f"Mode (shows up the most): {', '.join(f'{m:g}' for m in modes)}")

print(f"Range (biggest minus smallest): {ordered[-1]:g} - {ordered[0]:g} = {ordered[-1] - ordered[0]:g}")
if len(numbers) > 1:
    print(f"Standard deviation (how spread out): {statistics.stdev(numbers):.3g}")
