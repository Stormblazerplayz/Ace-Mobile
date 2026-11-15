# @title Word Frequency Counter
# @category Files and data
# @kind Console program
# @where Save as word_freq.py and run: python3 word_freq.py, then type the path to any .txt file (or press Enter for a sample).
# @keywords python word frequency, python most common words, python text analysis, python count words in file
# @about Reads a text file and finds the most common words, skipping boring ones like "the" and "and".

import re
from collections import Counter
from pathlib import Path

SAMPLE = """Once upon a time a robot named Bolt lived in a garage. Bolt loved to build things.
Every day Bolt built a new robot friend, and every night the robot friends built Bolt a bigger garage."""
BORING = {"the", "a", "an", "and", "to", "of", "in", "it", "is", "was", "on", "for", "with", "that", "every"}

name = input("Text file to read (Enter for a sample): ").strip()
text = Path(name).expanduser().read_text(encoding="utf-8", errors="replace") if name else SAMPLE

words = re.findall(r"[a-z']+", text.lower())  # grab words, ignore punctuation
interesting = [w for w in words if w not in BORING and len(w) > 1]
counts = Counter(interesting)

print(f"\nTotal words: {len(words)}, different words: {len(set(words))}")
print(f"Longest word: {max(words, key=len) if words else '-'}")
print("Top words:")
top = counts.most_common(10)
biggest = top[0][1] if top else 1
for word, count in top:
    print(f"  {word:<12} {'#' * round(count / biggest * 30)} {count}")
