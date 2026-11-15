# @title Tip and Bill Splitter
# @category Math and school
# @kind Console program
# @where Save as tip.py and run: python3 tip.py
# @keywords python tip calculator, python split the bill, python restaurant math, python money rounding
# @about Works out the tip for a bill at different percentages and splits the total between friends.

def money(prompt, default):
    text = input(f"{prompt} [{default}]: ").strip().replace("$", "")
    try:
        return float(text) if text else default
    except ValueError:
        return default


bill = money("Bill amount ($)", 48.50)
people = int(money("How many people", 3)) or 1

print(f"\n{'Tip':>5} {'Tip $':>8} {'Total':>9} {'Each':>8}")
for percent in (10, 15, 18, 20, 25):
    tip = bill * percent / 100
    total = bill + tip
    print(f"{percent:>4}% {tip:>8.2f} {total:>9.2f} {total / people:>8.2f}")

choice = money("\nWhich tip % do you want", 18)
total = bill * (1 + choice / 100)
each = total / people
# Round each share UP to the next cent so nobody comes up short
each_cents = -(-round(total * 100) // people)
print(f"Total with tip: ${total:.2f}. Each of {people} people pays ${each_cents / 100:.2f} (exactly {each:.4f}).")
