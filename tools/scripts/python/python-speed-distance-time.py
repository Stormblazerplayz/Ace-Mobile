# @title Speed, Distance and Time
# @category Math and school
# @kind Console program
# @where Save as sdt.py and run: python3 sdt.py
# @keywords python speed distance time, python physics calculator, python travel time, python average speed
# @about Solves speed, distance and time problems: give any two and it works out the third.

print("Speed = Distance / Time. Fill in two of these and leave one blank.")


def ask(label):
    text = input(f"{label}: ").strip()
    if not text:
        return None
    try:
        return float(text)
    except ValueError:
        return None


speed = ask("Speed (km/h)")
distance = ask("Distance (km)")
hours = ask("Time (hours)")


def show_time(h):
    whole = int(h)
    minutes = round((h - whole) * 60)
    return f"{whole} h {minutes} min"


if speed is None and distance is not None and hours:
    print(f"Speed = {distance:g} / {hours:g} = {distance / hours:.2f} km/h")
elif distance is None and speed is not None and hours is not None:
    print(f"Distance = {speed:g} x {hours:g} = {speed * hours:.2f} km")
elif hours is None and speed and distance is not None:
    t = distance / speed
    print(f"Time = {distance:g} / {speed:g} = {t:.2f} hours ({show_time(t)})")
else:
    print("Leave exactly one blank (and don't divide by zero).")

print("\nFun facts: walking is about 5 km/h, a car on the highway about 100 km/h,")
print("and sound travels about 1,235 km/h!")
