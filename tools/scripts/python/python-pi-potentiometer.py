# @title Raspberry Pi Knob Controls Brightness
# @category Raspberry Pi
# @kind Console program
# @where On a Raspberry Pi with SPI turned on (sudo raspi-config): MCP3008 chip wired to the SPI pins, a potentiometer's middle leg on channel 0, and an LED on GPIO18. Run: python3 knob.py
# @keywords raspberry pi potentiometer, gpiozero mcp3008, pi analog input, raspberry pi dimmer knob
# @about Turning a knob (potentiometer) changes how bright an LED is, using an MCP3008 to read analog values.

from signal import pause

from gpiozero import MCP3008, PWMLED

knob = MCP3008(channel=0)  # the Pi can't read analog voltages, so the MCP3008 chip does it
led = PWMLED(18)

# "source" links devices: the LED's brightness follows the knob's value (0.0 to 1.0)
led.source = knob
print("Turn the knob to change the brightness. Ctrl+C to quit.")
print("Starting value:", round(knob.value, 2))
pause()
