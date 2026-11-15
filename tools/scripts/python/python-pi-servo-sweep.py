# @title Raspberry Pi Servo Control
# @category Raspberry Pi
# @kind Console program
# @where On a Raspberry Pi: servo signal (yellow or orange) to GPIO17, red to 5V, brown or black to GND. Big servos need their own power supply. Run: python3 servo.py
# @keywords raspberry pi servo, gpiozero angularservo, pi servo angle, raspberry pi servo sweep
# @about Sweeps a servo back and forth, then lets you type an angle to move it to.

from time import sleep

from gpiozero import AngularServo

# Many hobby servos need slightly wider pulses than the default to reach the full range
servo = AngularServo(17, min_angle=-90, max_angle=90, min_pulse_width=0.0005, max_pulse_width=0.0025)

print("Sweeping...")
for _ in range(2):
    for angle in range(-90, 91, 10):
        servo.angle = angle
        sleep(0.05)
    for angle in range(90, -91, -10):
        servo.angle = angle
        sleep(0.05)

servo.angle = 0
print("Type an angle from -90 to 90 (or q to quit).")
while True:
    text = input("Angle: ").strip()
    if text.lower() == "q":
        break
    try:
        angle = float(text)
    except ValueError:
        print("Type a number.")
        continue
    if -90 <= angle <= 90:
        servo.angle = angle
    else:
        print("Keep it between -90 and 90.")

servo.detach()  # stop sending pulses so the servo stops buzzing
