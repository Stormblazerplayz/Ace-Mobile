# @title Raspberry Pi Button Controls an LED
# @category Raspberry Pi
# @kind Console program
# @where On a Raspberry Pi: LED on GPIO17 (with a 330 ohm resistor to GND) and a push button between GPIO2 and GND. Save as button.py and run: python3 button.py
# @keywords raspberry pi button, gpiozero button, pi when_pressed, raspberry pi led switch
# @about Lights the LED while the button is held, and counts how many times you press it.

from signal import pause

from gpiozero import LED, Button

led = LED(17)
button = Button(2)  # gpiozero turns on the Pi's built-in pull-up resistor for you
presses = {"count": 0}


def pressed():
    led.on()
    presses["count"] += 1
    print(f"Pressed! ({presses['count']} times)")


def released():
    led.off()


# These functions run by themselves whenever the button changes
button.when_pressed = pressed
button.when_released = released

print("Press the button. Ctrl+C to quit.")
pause()  # wait forever so the program doesn't end
