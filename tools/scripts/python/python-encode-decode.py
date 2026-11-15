# @title Encode, Decode and Hash
# @category Tools
# @kind Console program
# @where Save as encode.py and run: python3 encode.py
# @keywords python base64, python sha256 hash, python uuid, python hex encode, python md5
# @about Turns text into base64, hex and hash fingerprints, and makes a random unique ID.

import base64
import hashlib
import uuid

text = input("Type some text: ") or "Hello, Storm!"
data = text.encode("utf-8")  # text -> bytes

b64 = base64.b64encode(data).decode()
print("Base64:", b64)
print("Back from base64:", base64.b64decode(b64).decode("utf-8"))
print("Hex:", data.hex())

# A hash is a fingerprint. The same text ALWAYS gives the same hash,
# but you can't turn a hash back into the text.
print("SHA-256:", hashlib.sha256(data).hexdigest())
print("MD5 (old, not for passwords):", hashlib.md5(data).hexdigest())
print("Change one letter and the hash is totally different:")
print("  ", hashlib.sha256((text + "!").encode()).hexdigest())

print("Random unique ID:", uuid.uuid4())
