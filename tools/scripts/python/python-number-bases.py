# @title Binary, Hex and Decimal
# @category Math and school
# @kind Console program
# @where Save as bases.py and run: python3 bases.py
# @keywords python binary converter, python hexadecimal, python number bases, python bin hex oct
# @about Converts numbers between decimal, binary, hexadecimal and octal, and explains how binary works.

def explain_binary(n):
    """Show how a binary number is built from powers of 2."""
    bits = bin(n)[2:]
    parts = [f"{bit}x{2 ** power}" for power, bit in zip(range(len(bits) - 1, -1, -1), bits)]
    return " + ".join(parts)


print("Type a number: 42 (decimal), 0b101010 (binary), 0x2A (hex) or 0o52 (octal). Enter to quit.")
while True:
    text = input("\n> ").strip().lower()
    if not text:
        break
    try:
        n = int(text, 0)  # base 0 means "figure it out from the 0b, 0x or 0o at the front"
    except ValueError:
        print("I don't understand that number.")
        continue
    if n < 0:
        print("Let's stick to positive numbers.")
        continue
    print(f"Decimal: {n}")
    print(f"Binary:  {bin(n)}  ({n.bit_length()} bits)")
    print(f"Hex:     {hex(n)}")
    print(f"Octal:   {oct(n)}")
    if n < 256:
        print(f"How binary works: {explain_binary(n)} = {n}")
    if 32 <= n < 127:
        print(f"As a text character: {chr(n)!r}")
