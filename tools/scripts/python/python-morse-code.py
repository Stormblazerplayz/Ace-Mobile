# @title Morse Code Translator
# @category Tools
# @kind Console program
# @where Save as morse.py and run: python3 morse.py
# @keywords python morse code, python text to morse, python morse to text, python dots and dashes
# @about Translates text into Morse code dots and dashes, and Morse code back into text.

MORSE = {
    "A": ".-", "B": "-...", "C": "-.-.", "D": "-..", "E": ".", "F": "..-.", "G": "--.", "H": "....",
    "I": "..", "J": ".---", "K": "-.-", "L": ".-..", "M": "--", "N": "-.", "O": "---", "P": ".--.",
    "Q": "--.-", "R": ".-.", "S": "...", "T": "-", "U": "..-", "V": "...-", "W": ".--", "X": "-..-",
    "Y": "-.--", "Z": "--..", "0": "-----", "1": ".----", "2": "..---", "3": "...--", "4": "....-",
    "5": ".....", "6": "-....", "7": "--...", "8": "---..", "9": "----.", ".": ".-.-.-", "?": "..--..",
}
BACK = {code: letter for letter, code in MORSE.items()}  # flip the dictionary around


def to_morse(text):
    # Letters are split by a space, words by a slash
    return " / ".join(" ".join(MORSE[ch] for ch in word if ch in MORSE) for word in text.upper().split())


def from_morse(code):
    words = code.strip().split("/")
    return " ".join("".join(BACK.get(sym, "?") for sym in word.split()) for word in words)


text = input("Type text or Morse code (use . and - with spaces, / between words): ").strip()
if text and set(text) <= set(".-/ "):
    print("Text:", from_morse(text))
else:
    print("Morse:", to_morse(text or "SOS"))
