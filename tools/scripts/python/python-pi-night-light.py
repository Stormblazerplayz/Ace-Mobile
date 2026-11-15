# @title Raspberry Pi Automatic Night Light
# @category Raspberry Pi
# @kind Console program
# @where On a Raspberry Pi: light sensor (LDR) from 3.3V to GPIO4, a 1uF capacitor from GPIO4 to GND, and an LED on GPIO17. Run: python3 night_light.py
# @keywords raspberry pi light sensor, gpiozero lightsensor, pi ldr night light, raspberry pi when_dark
# @about Turns an LED on automatically when the room gets dark and off again when it's light.

from signal import pause
from time import sleep

from gpiozero import LED, LightSensor

sensor = LightSensor(4, threshold=0.2)  # below 0.2 counts as dark (tweak this for your room)
led = LED(17)

print("Watching the light level for 5 seconds so you can pick a good threshold...")
for _ in range(10):
    print(f"  light level: {sensor.value:.2f}")
    sleep(0.5)

sensor.when_dark = led.on   # no () here: we hand over the function itself
sensor.when_light = led.off
print("Night light running. Cover the sensor to test it. Ctrl+C to quit.")
pause()
