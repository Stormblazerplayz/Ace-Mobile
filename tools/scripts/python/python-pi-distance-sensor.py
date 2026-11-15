# @title Raspberry Pi Parking Sensor
# @category Raspberry Pi
# @kind Console program
# @where On a Raspberry Pi: HC-SR04 trigger to GPIO4, echo to GPIO17 through a voltage divider (1k and 2k resistors, the Pi needs 3.3V), VCC to 5V, buzzer on GPIO27. Run: python3 parking.py
# @keywords raspberry pi distance sensor, gpiozero distancesensor, pi ultrasonic hc-sr04, raspberry pi parking sensor
# @about Measures distance with an ultrasonic sensor and beeps faster the closer something gets, like a car's parking sensor.

from time import sleep

from gpiozero import Buzzer, DistanceSensor

sensor = DistanceSensor(echo=17, trigger=4, max_distance=2)  # max_distance is in meters
buzzer = Buzzer(27)

print("Move your hand toward the sensor. Ctrl+C to stop.")
try:
    while True:
        cm = sensor.distance * 100  # .distance is in meters
        bar = "#" * int(min(cm, 100) / 2)
        print(f"\r{cm:6.1f} cm |{bar:<50}|", end="", flush=True)
        if cm < 10:
            buzzer.on()                  # very close: solid tone
            sleep(0.1)
        elif cm < 50:
            buzzer.beep(on_time=0.05, off_time=cm / 200, n=1, background=False)  # closer = faster beeps
        else:
            buzzer.off()
            sleep(0.1)
except KeyboardInterrupt:
    buzzer.off()
    print("\nBye!")
