# @title 3D Print Cost Calculator
# @category Tools
# @kind Console program
# @where Save as print_cost.py and run: python3 print_cost.py
# @keywords python 3d print cost, python filament cost, python print price calculator, python pricing tool
# @about Works out what a 3D print costs in filament and electricity, and suggests a selling price.

def ask(question, default):
    text = input(f"{question} [{default}]: ").strip()
    try:
        return float(text) if text else default
    except ValueError:
        print(f"  Using {default}.")
        return default


print("=== 3D Print Cost Calculator === (press Enter to use the value in brackets)")
grams = ask("Filament used (grams)", 50)
spool_price = ask("Spool price ($)", 20)
spool_grams = ask("Spool size (grams)", 1000)
hours = ask("Print time (hours)", 3)
watts = ask("Printer power (watts)", 120)
power_price = ask("Electricity price per kWh ($)", 0.15)
markup = ask("Profit markup (%)", 100)

filament_cost = grams / spool_grams * spool_price
power_cost = watts / 1000 * hours * power_price
wear = hours * 0.05  # a little for nozzle and printer wear
cost = filament_cost + power_cost + wear
price = cost * (1 + markup / 100)

print(f"\nFilament:    ${filament_cost:6.2f}")
print(f"Electricity: ${power_cost:6.2f}")
print(f"Wear:        ${wear:6.2f}")
print(f"Total cost:  ${cost:6.2f}")
print(f"Sell for about ${price:.2f} (round to ${round(price + 0.49):.0f})")
