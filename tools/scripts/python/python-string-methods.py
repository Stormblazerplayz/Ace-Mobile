# @title String Methods
# @category Basics
# @kind Console program
# @where Save as strings.py and run: python3 strings.py
# @keywords python string methods, python upper lower, python split join, python replace text, python strip
# @about Shows the handy built-in tricks for working with text, like upper, split, replace and find.

text = "  Python is Super Fun  "

print(repr(text.strip()))           # remove spaces at both ends
print(text.upper())                 # ALL CAPS
print(text.lower())                 # all lowercase
print(text.strip().title())         # Each Word Capitalized
print(text.replace("Fun", "Cool"))  # swap words

sentence = "the quick brown fox jumps over the lazy dog"
words = sentence.split()            # split into a list of words
print("Words:", words)
print("Word count:", len(words))
print("Joined with dashes:", "-".join(words))

print("Starts with 'the'?", sentence.startswith("the"))
print("Ends with 'dog'?", sentence.endswith("dog"))
print("Where is 'fox'?", sentence.find("fox"))
print("How many 'the'?", sentence.count("the"))

# Strings can be sliced like lists
word = "skateboard"
print("First 5 letters:", word[:5])
print("Last 5 letters:", word[-5:])
print("Reversed:", word[::-1])

# Checking what kind of characters are in a string
print("'123'.isdigit() ->", "123".isdigit())
print("'abc'.isalpha() ->", "abc".isalpha())
print("'Hi5'.isalnum() ->", "Hi5".isalnum())
