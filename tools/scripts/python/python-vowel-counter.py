# @title Vowel and Letter Counter
# @category Basics
# @kind Console program
# @where Save as vowels.py and run: python3 vowels.py
# @keywords python count vowels, python count letters, python counter, python most common letter
# @about Counts the vowels, consonants and most common letters in any sentence you type.

from collections import Counter

text = input("Type a sentence: ")
if not text.strip():
    text = "The quick brown fox jumps over the lazy dog"
    print("Using an example:", text)

vowels = "aeiou"
vowel_count = 0
consonant_count = 0

for ch in text.lower():
    if ch in vowels:
        vowel_count += 1
    elif ch.isalpha():
        consonant_count += 1

print("Vowels:", vowel_count)
print("Consonants:", consonant_count)
print("Spaces:", text.count(" "))

# Counter counts everything for us
letters = Counter(ch for ch in text.lower() if ch.isalpha())
print("Top 3 letters:")
for letter, count in letters.most_common(3):
    print(f"  {letter}: {'#' * count} ({count})")
