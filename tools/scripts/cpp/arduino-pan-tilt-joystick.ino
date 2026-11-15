// @title Pan and Tilt with a Joystick
// @category Arduino
// @kind Arduino sketch
// @where Arduino Uno; joystick VRx to A0, VRy to A1, SW to pin 2, 5V, GND; pan servo on pin 9, tilt servo on pin 10; power servos from a 5V supply with GND shared.
// @keywords pan tilt servo, joystick two servos, camera mount arduino, joystick servo control
// @about Moves two servos smoothly with a joystick, and the joystick button re-centers them.

#include <Servo.h>

Servo panServo;
Servo tiltServo;
int pan = 90;
int tilt = 90;

// Turns a joystick reading into a speed from -3 to 3, with a dead zone in the middle.
int stickSpeed(int reading) {
  int offset = reading - 512;
  if (abs(offset) < 80) return 0;
  return map(offset, -512, 511, -3, 3);
}

void setup() {
  panServo.attach(9);
  tiltServo.attach(10);
  pinMode(2, INPUT_PULLUP);
}

void loop() {
  pan = constrain(pan + stickSpeed(analogRead(A0)), 0, 180);
  tilt = constrain(tilt + stickSpeed(analogRead(A1)), 20, 160);

  if (digitalRead(2) == LOW) {  // button pressed: go back to the middle
    pan = 90;
    tilt = 90;
  }

  panServo.write(pan);
  tiltServo.write(tilt);
  delay(15);
}
