# @title Palindrome Checker
# @category Basics
# @kind Console program
# @where Save as palindrome.py and run: python3 palindrome.py
# @keywords python palindrome, python reverse string, python racecar check, python clean text
# @about Checks if a word or sentence reads the same forwards and backwards, ignoring spaces and punctuation.

def clean(text):
    # Keep only letters and numbers, all lowercase
    return "".join(ch.lower() for ch in text if ch.isalnum())


def is_palindrome(text):
    letters = clean(text)
    return letters != "" and letters == letters[::-1]


examples = ["racecar", "Python", "A man, a plan, a canal: Panama!", "Was it a car or a cat I saw?", "12321"]
for example in examples:
    answer = "YES" if is_palindrome(example) else "no"
    print(f"{answer:>3}  {example}")

print("\nYour turn! Press Enter on an empty line to stop.")
while True:
    text = input("Type something: ")
    if text == "":
        break
    if is_palindrome(text):
        print("That's a palindrome!")
    else:
        print("Not a palindrome. Backwards it's:", clean(text)[::-1])
