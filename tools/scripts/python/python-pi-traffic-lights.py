# @title Raspberry Pi Traffic Lights
# @category Raspberry Pi
# @kind Console program
# @where On a Raspberry Pi: red LED on GPIO22, amber on GPIO27, green on GPIO17 (each with a resistor to GND), optional button on GPIO2. Run: python3 traffic.py
# @keywords raspberry pi traffic lights, gpiozero trafficlights, pi crossing button, raspberry pi three leds
# @about Runs a traffic light sequence, and a button lets a pretend pedestrian ask to cross.

from time import sleep

from gpiozero import Button, TrafficLights

lights = TrafficLights(red=22, amber=27, green=17)
button = Button(2)

print("Traffic lights running. Press the button to cross. Ctrl+C to stop.")
try:
    while True:
        lights.green.on()
        # Stay green until someone presses the button (or 10 seconds pass)
        button.wait_for_press(timeout=10)
        lights.green.off()

        lights.amber.on()
        sleep(2)
        lights.amber.off()

        lights.red.on()
        print("WALK!")
        sleep(5)

        lights.amber.blink(on_time=0.3, off_time=0.3)  # flashing amber: get ready
        sleep(2)
        lights.off()  # turns every light off and stops the blinking
except KeyboardInterrupt:
    lights.off()
    print("\nLights off.")
