# @title Percent Calculator
# @category Math and school
# @kind Console program
# @where Save as percent.py and run: python3 percent.py
# @keywords python percent calculator, python percentage change, python discount calculator, python what percent
# @about Answers the three classic percent questions plus discounts and percent change.

def num(prompt):
    while True:
        try:
            return float(input(prompt))
        except ValueError:
            print("Type a number.")


print("1. What is X% of Y?")
print("2. X is what percent of Y?")
print("3. Percent change from X to Y")
print("4. Price after a discount")
choice = input("Pick 1-4: ").strip()

if choice == "1":
    p, y = num("X (percent): "), num("Y: ")
    print(f"{p:g}% of {y:g} = {p / 100 * y:g}")
elif choice == "2":
    x, y = num("X: "), num("Y: ")
    print(f"{x:g} is {x / y * 100:.2f}% of {y:g}" if y else "Y can't be 0.")
elif choice == "3":
    old, new = num("Old value: "), num("New value: ")
    if old:
        change = (new - old) / abs(old) * 100
        print(f"That's a {'rise' if change >= 0 else 'drop'} of {abs(change):.2f}%")
    else:
        print("The old value can't be 0.")
elif choice == "4":
    price, off = num("Price: $"), num("Discount %: ")
    saved = price * off / 100
    print(f"You save ${saved:.2f} and pay ${price - saved:.2f}")
else:
    print("Pick 1 to 4.")
