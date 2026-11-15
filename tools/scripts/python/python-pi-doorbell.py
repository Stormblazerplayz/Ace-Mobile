# @title Raspberry Pi Doorbell
# @category Raspberry Pi
# @kind Console program
# @where On a Raspberry Pi: active buzzer + leg to GPIO17 and - leg to GND, button between GPIO2 and GND. Run: python3 doorbell.py
# @keywords raspberry pi doorbell, gpiozero buzzer, pi buzzer beep, raspberry pi visitor log
# @about A doorbell: pressing the button beeps the buzzer and writes the time to a visitor log file.

from datetime import datetime
from pathlib import Path
from signal import pause

from gpiozero import Button, Buzzer

buzzer = Buzzer(17)
button = Button(2, bounce_time=0.1)  # bounce_time ignores the tiny flickers a button makes
LOG = Path(__file__).with_name("visitors.txt")


def ring():
    stamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    print(f"Ding dong! Someone is at the door ({stamp})")
    buzzer.beep(on_time=0.2, off_time=0.1, n=3)  # three quick beeps in the background
    with open(LOG, "a") as f:
        f.write(stamp + "\n")


button.when_pressed = ring
print(f"Doorbell ready. Visits are saved to {LOG.name}. Ctrl+C to quit.")
pause()
