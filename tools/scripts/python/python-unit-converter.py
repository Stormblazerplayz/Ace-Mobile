# @title Unit Converter
# @category Math and school
# @kind Console program
# @where Save as converter.py and run: python3 converter.py
# @keywords python unit converter, python convert units, python metric imperial, python length weight converter
# @about Converts lengths, weights and temperatures between metric and imperial units.

# Every unit is stored as "how many of the base unit" (meters or grams)
LENGTH = {"mm": 0.001, "cm": 0.01, "m": 1, "km": 1000, "in": 0.0254, "ft": 0.3048, "yd": 0.9144, "mi": 1609.344}
WEIGHT = {"mg": 0.001, "g": 1, "kg": 1000, "oz": 28.3495, "lb": 453.592}


def convert_temperature(value, unit_from, unit_to):
    # Change to Celsius first, then to the target
    celsius = {"c": value, "f": (value - 32) * 5 / 9, "k": value - 273.15}[unit_from]
    return {"c": celsius, "f": celsius * 9 / 5 + 32, "k": celsius + 273.15}[unit_to]


print("Type a conversion like: 5 km to mi,  12 in to cm,  150 lb to kg,  98.6 f to c")
print("Length units:", ", ".join(LENGTH), "| Weight units:", ", ".join(WEIGHT), "| Temperatures: c, f, k")
while True:
    parts = input("\n> ").lower().replace(" to ", " ").split()
    if not parts:
        break
    if len(parts) != 3:
        print("Format: <number> <from> to <to>")
        continue
    try:
        value = float(parts[0])
    except ValueError:
        print("Start with a number.")
        continue
    a, b = parts[1], parts[2]
    if a in LENGTH and b in LENGTH:
        result = value * LENGTH[a] / LENGTH[b]
    elif a in WEIGHT and b in WEIGHT:
        result = value * WEIGHT[a] / WEIGHT[b]
    elif a in "cfk" and b in "cfk" and len(a) == len(b) == 1:
        result = convert_temperature(value, a, b)
    else:
        print("I can't convert between those units.")
        continue
    print(f"{value:g} {a} = {result:.4g} {b}")
