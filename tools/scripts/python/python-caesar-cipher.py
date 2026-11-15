# @title Caesar Cipher
# @category Tools
# @kind Console program
# @where Save as caesar.py and run: python3 caesar.py
# @keywords python caesar cipher, python secret code, python encrypt decrypt, python shift letters
# @about Encrypts and decrypts secret messages by shifting every letter along the alphabet, and can crack them too.

import string


def shift_text(text, shift):
    result = []
    for ch in text:
        if ch in string.ascii_lowercase:
            result.append(chr((ord(ch) - ord("a") + shift) % 26 + ord("a")))
        elif ch in string.ascii_uppercase:
            result.append(chr((ord(ch) - ord("A") + shift) % 26 + ord("A")))
        else:
            result.append(ch)  # spaces and punctuation stay the same
    return "".join(result)


choice = input("(e)ncrypt, (d)ecrypt or (c)rack? ").strip().lower()
message = input("Message: ")

if choice == "c":
    # Try all 25 shifts. One of them will look like real words!
    for shift in range(1, 26):
        print(f"{shift:>2}: {shift_text(message, -shift)}")
else:
    text = input("Shift amount (1-25): ").strip()
    shift = int(text) if text.isdigit() else 3
    if choice == "d":
        shift = -shift
    print("Result:", shift_text(message, shift))
