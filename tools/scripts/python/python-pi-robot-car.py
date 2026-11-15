# @title Raspberry Pi Robot Car
# @category Raspberry Pi
# @kind Console program
# @where On a Raspberry Pi with a motor driver board (like an L298N): left motor on GPIO4 and GPIO14, right motor on GPIO17 and GPIO18, motors powered by their own batteries. Run: python3 robot.py
# @keywords raspberry pi robot car, gpiozero robot, pi motor driver, raspberry pi wasd control
# @about Drive a two-wheeled robot by typing w, a, s and d, with a speed setting and a little dance move.

from time import sleep

from gpiozero import Motor, Robot

robot = Robot(left=Motor(4, 14), right=Motor(17, 18))
speed = 0.6  # 0.0 to 1.0

print("Commands: w = forward, s = back, a = left, d = right, x = stop,")
print("          + / - = speed, dance, q = quit")
try:
    while True:
        cmd = input(f"[speed {speed:.1f}] > ").strip().lower()
        if cmd == "w":
            robot.forward(speed)
        elif cmd == "s":
            robot.backward(speed)
        elif cmd == "a":
            robot.left(speed)
        elif cmd == "d":
            robot.right(speed)
        elif cmd == "x":
            robot.stop()
        elif cmd == "+":
            speed = min(1.0, speed + 0.1)
        elif cmd == "-":
            speed = max(0.2, speed - 0.1)
        elif cmd == "dance":
            for _ in range(3):
                robot.left(speed)
                sleep(0.3)
                robot.right(speed)
                sleep(0.3)
            robot.stop()
        elif cmd == "q":
            break
        else:
            print("Unknown command.")
finally:
    robot.stop()  # always stop the motors, even if something goes wrong
    print("Robot stopped.")
