# @title Raspberry Pi Blink an LED
# @category Raspberry Pi
# @kind Console program
# @where On a Raspberry Pi: wire an LED's long leg to GPIO17 through a 330 ohm resistor and its short leg to GND, save as blink.py and run: python3 blink.py
# @keywords raspberry pi blink led, gpiozero led, pi gpio first project, raspberry pi python led
# @about The "hello world" of electronics: makes an LED on GPIO17 blink on and off.

from time import sleep

from gpiozero import LED

led = LED(17)  # the GPIO number, not the physical pin number

print("Blinking! Press Ctrl+C to stop.")
try:
    for count in range(1, 1001):
        led.on()
        sleep(0.5)
        led.off()
        sleep(0.5)
        print(f"\rBlinks: {count}", end="", flush=True)
except KeyboardInterrupt:
    print("\nStopped.")

# Tip: gpiozero can blink by itself in the background, like this:
#   led.blink(on_time=0.2, off_time=0.2)
#   from signal import pause; pause()
