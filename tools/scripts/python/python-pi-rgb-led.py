# @title Raspberry Pi RGB LED Colors
# @category Raspberry Pi
# @kind Console program
# @where On a Raspberry Pi: common-cathode RGB LED with red on GPIO17, green on GPIO27, blue on GPIO22 (each through a resistor) and the long leg to GND. Run: python3 rgb.py
# @keywords raspberry pi rgb led, gpiozero rgbled, pi color mixing, raspberry pi rainbow led
# @about Mixes colors on an RGB LED: shows a list of named colors, then fades through a rainbow.

import colorsys
from time import sleep

from gpiozero import RGBLED

led = RGBLED(red=17, green=27, blue=22)  # add active_high=False for a common-anode LED

COLORS = {
    "red": (1, 0, 0), "green": (0, 1, 0), "blue": (0, 0, 1),
    "yellow": (1, 1, 0), "cyan": (0, 1, 1), "purple": (1, 0, 1), "white": (1, 1, 1),
}

for name, color in COLORS.items():
    print("Showing", name)
    led.color = color  # each part goes from 0 (off) to 1 (full)
    sleep(1)

print("Rainbow! Ctrl+C to stop.")
try:
    hue = 0.0
    while True:
        led.color = colorsys.hsv_to_rgb(hue, 1, 1)
        hue = (hue + 0.005) % 1
        sleep(0.02)
except KeyboardInterrupt:
    led.off()
