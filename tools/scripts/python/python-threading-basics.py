# @title Doing Two Things at Once
# @category Basics
# @kind Console program
# @where Save as threads.py and run: python3 threads.py
# @keywords python threading, python thread, python run at the same time, python join thread
# @about Uses threads so two pretend downloads run at the same time instead of one after another.

import threading
import time


def download(name, seconds):
    print(f"Starting {name}...")
    for step in range(1, 4):
        time.sleep(seconds / 3)
        print(f"  {name} is {step * 33}% done")
    print(f"Finished {name}!")


start = time.perf_counter()

# Make two threads. Each one runs its own function.
a = threading.Thread(target=download, args=("music.mp3", 1.5))
b = threading.Thread(target=download, args=("game.zip", 1.5))
a.start()
b.start()

# join() waits until each thread is done
a.join()
b.join()

print(f"Both done in {time.perf_counter() - start:.1f} seconds (not 3, because they overlapped!)")
