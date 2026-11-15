# @title Raspberry Pi LED Bar Graph
# @category Raspberry Pi
# @kind Console program
# @where On a Raspberry Pi: five LEDs on GPIO5, GPIO6, GPIO13, GPIO19 and GPIO26 (each with a resistor to GND). Run: python3 bar_graph.py
# @keywords raspberry pi led bar graph, gpiozero ledbargraph, pi cpu load meter, raspberry pi level meter
# @about Uses a row of five LEDs as a meter that shows how busy the Pi's processor is.

import os
from time import sleep

from gpiozero import LEDBarGraph

graph = LEDBarGraph(5, 6, 13, 19, 26, pwm=True)  # pwm lets the last LED glow partly

print("Showing a quick sweep...")
for level in range(0, 11):
    graph.value = level / 10  # 0.5 means "half the LEDs on"
    sleep(0.1)

cores = os.cpu_count() or 1
print("Now showing the CPU load. Run something heavy to watch it climb! Ctrl+C to stop.")
try:
    while True:
        load = os.getloadavg()[0] / cores  # 1.0 means every core is busy
        graph.value = min(1.0, load)
        print(f"\rLoad: {load:4.0%}", end="", flush=True)
        sleep(1)
except KeyboardInterrupt:
    graph.off()
    print()
