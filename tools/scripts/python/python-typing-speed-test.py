# @title Typing Speed Test
# @category Games
# @kind Console program
# @where Save as typing_test.py and run: python3 typing_test.py
# @keywords python typing test, python words per minute, python wpm, python accuracy check
# @about Type a random sentence as fast as you can and get your words per minute and accuracy.

import random
import time

SENTENCES = [
    "the quick brown fox jumps over the lazy dog",
    "python makes coding fun and easy to learn",
    "my robot can draw circles and squares all day",
    "pack my box with five dozen liquor jugs",
    "storms bring thunder lightning and lots of rain",
]

sentence = random.choice(SENTENCES)
print("Type this sentence exactly, then press Enter:\n")
print("   " + sentence + "\n")
input("Press Enter when you're ready to start...")
start = time.perf_counter()
typed = input("> ")
seconds = time.perf_counter() - start

# Accuracy: how many characters match in the same spot
correct = sum(a == b for a, b in zip(typed, sentence))
accuracy = correct / len(sentence) * 100
# Words per minute: typing teachers count 5 characters as one word
wpm = (len(typed) / 5) / (seconds / 60) if seconds > 0 else 0

print(f"\nTime: {seconds:.1f} seconds")
print(f"Speed: {wpm:.0f} words per minute")
print(f"Accuracy: {accuracy:.0f}%")
if typed == sentence:
    print("Perfect typing!")
