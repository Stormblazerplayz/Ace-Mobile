# @title Raspberry Pi Temperature Logger
# @category Raspberry Pi
# @kind Console program
# @where On a Raspberry Pi (no wiring needed; an optional LED on GPIO17 lights when it's hot). Run: python3 temp_log.py
# @keywords raspberry pi cpu temperature, gpiozero cputemperature, pi temperature log csv, raspberry pi overheating
# @about Reads the Pi's processor temperature every few seconds, saves it to a CSV file and warns if it gets hot.

import csv
from datetime import datetime
from pathlib import Path
from time import sleep

from gpiozero import LED, CPUTemperature

cpu = CPUTemperature(threshold=70)  # is_active becomes True above 70 C
warning = LED(17)
LOG = Path(__file__).with_name("cpu_temps.csv")
new_file = not LOG.exists()

print("Logging every 5 seconds to", LOG.name, "(Ctrl+C to stop)")
with open(LOG, "a", newline="") as f:
    writer = csv.writer(f)
    if new_file:
        writer.writerow(["time", "celsius"])
    try:
        while True:
            temp = cpu.temperature
            writer.writerow([datetime.now().isoformat(timespec="seconds"), f"{temp:.1f}"])
            f.flush()  # save right away
            bar = "#" * int(temp / 2)
            print(f"{datetime.now():%H:%M:%S}  {temp:5.1f} C  {bar}")
            if cpu.is_active:
                warning.on()
                print("  It's getting hot! Check the fan or heatsink.")
            else:
                warning.off()
            sleep(5)
    except KeyboardInterrupt:
        print("Stopped.")
