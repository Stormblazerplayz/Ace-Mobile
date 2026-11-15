# @title Savings and Compound Interest
# @category Math and school
# @kind Console program
# @where Save as savings.py and run: python3 savings.py
# @keywords python compound interest, python savings calculator, python simple interest, python money growth
# @about Shows how savings grow each year with simple and compound interest, and how monthly deposits add up.

def num(prompt, default):
    text = input(f"{prompt} [{default}]: ").strip()
    try:
        return float(text) if text else default
    except ValueError:
        return default


start = num("Starting money ($)", 100)
rate = num("Interest per year (%)", 5) / 100
monthly = num("Money added each month ($)", 10)
years = int(num("Years", 10))

simple = start
compound = start
print(f"\n{'Year':>4} {'Simple':>12} {'Compound':>12}")
for year in range(1, years + 1):
    simple += start * rate + monthly * 12          # interest only on the starting money
    for _ in range(12):
        compound = compound * (1 + rate / 12) + monthly  # interest on EVERYTHING, every month
    print(f"{year:>4} {simple:>12,.2f} {compound:>12,.2f}")

deposited = start + monthly * 12 * years
print(f"\nYou put in ${deposited:,.2f}.")
print(f"Compound interest earned you ${compound - deposited:,.2f} for free!")
