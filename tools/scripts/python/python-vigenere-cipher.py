# @title Vigenere Cipher
# @category Tools
# @kind Console program
# @where Save as vigenere.py and run: python3 vigenere.py
# @keywords python vigenere cipher, python keyword cipher, python encryption with password, python code message
# @about A stronger secret code than Caesar: a keyword decides how far each letter shifts.

def vigenere(text, key, decrypt=False):
    key = [ord(k) - ord("a") for k in key.lower() if k.isalpha()]
    if not key:
        raise ValueError("The key needs at least one letter")
    result = []
    k = 0  # which letter of the key we're on
    for ch in text:
        if ch.isalpha():
            base = ord("A") if ch.isupper() else ord("a")
            shift = -key[k % len(key)] if decrypt else key[k % len(key)]
            result.append(chr((ord(ch) - base + shift) % 26 + base))
            k += 1
        else:
            result.append(ch)
    return "".join(result)


mode = input("(e)ncrypt or (d)ecrypt? ").strip().lower()
message = input("Message: ")
key = input("Secret keyword: ").strip() or "lightning"
try:
    print("Result:", vigenere(message, key, decrypt=(mode == "d")))
except ValueError as error:
    print(error)

# Quick self test: encrypting then decrypting gives the original back
sample = "Meet me at the treehouse at 4!"
assert vigenere(vigenere(sample, "storm"), "storm", decrypt=True) == sample
