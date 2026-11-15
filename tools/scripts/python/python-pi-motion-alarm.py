# @title Raspberry Pi Motion Alarm
# @category Raspberry Pi
# @kind Console program
# @where On a Raspberry Pi: PIR motion sensor OUT to GPIO4 (VCC to 5V, GND to GND), LED on GPIO17, buzzer on GPIO27. Run: python3 motion.py
# @keywords raspberry pi motion sensor, gpiozero motionsensor, pi pir alarm, raspberry pi intruder alarm
# @about A bedroom door alarm: when the PIR sensor sees movement, the LED flashes and the buzzer beeps.

from datetime import datetime
from signal import pause

from gpiozero import LED, Buzzer, MotionSensor

pir = MotionSensor(4)
led = LED(17)
buzzer = Buzzer(27)
count = {"events": 0}


def motion():
    count["events"] += 1
    print(f"{datetime.now():%H:%M:%S}  Motion detected! (#{count['events']})")
    led.blink(on_time=0.1, off_time=0.1)
    buzzer.beep(on_time=0.1, off_time=0.1, n=5)


def still():
    led.off()
    print(f"{datetime.now():%H:%M:%S}  All quiet.")


print("Warming up the sensor for a few seconds...")
pir.wait_for_no_motion()
print("Alarm armed! Ctrl+C to disarm.")
pir.when_motion = motion
pir.when_no_motion = still
pause()
