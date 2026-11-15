# @title Raspberry Pi Fading LED
# @category Raspberry Pi
# @kind Console program
# @where On a Raspberry Pi: LED on GPIO18 through a 330 ohm resistor to GND. Save as fade.py and run: python3 fade.py
# @keywords raspberry pi fade led, gpiozero pwmled, pi led brightness, raspberry pi breathing light
# @about Fades an LED smoothly brighter and dimmer using PWM, then lets gpiozero "breathe" it for you.

from time import sleep

from gpiozero import PWMLED

led = PWMLED(18)  # PWM lets us set brightness from 0.0 (off) to 1.0 (full)

print("Fading up and down by hand...")
for _ in range(3):
    for step in range(101):
        led.value = step / 100
        sleep(0.01)
    for step in range(100, -1, -1):
        led.value = step / 100
        sleep(0.01)

print("Now gpiozero does the breathing for us. Ctrl+C to stop.")
led.pulse(fade_in_time=1.5, fade_out_time=1.5)  # runs in the background
try:
    while True:
        sleep(1)
except KeyboardInterrupt:
    led.off()
    print("\nBye!")
