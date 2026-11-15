// @title Two Servos Waving Arms
// @category Arduino
// @kind Arduino sketch
// @where Arduino Uno; left arm servo on pin 9, right arm servo on pin 10; power servos from 5V (or a 4xAA pack with GND joined to Arduino GND).
// @keywords two servos, robot waving arms, servo dance, move two servos together
// @about Makes two servo arms wave hello, flap together and then do a mirror wave.

#include <Servo.h>

Servo leftArm;
Servo rightArm;

void setBoth(int left, int right, int wait) {
  leftArm.write(left);
  rightArm.write(right);
  delay(wait);
}

void setup() {
  leftArm.attach(9);
  rightArm.attach(10);
  setBoth(90, 90, 500);
}

void loop() {
  // Wave hello with the right arm.
  for (int i = 0; i < 3; i++) {
    setBoth(90, 150, 250);
    setBoth(90, 110, 250);
  }
  // Flap both arms like a bird. The servos face opposite ways, so one angle is flipped.
  for (int i = 0; i < 4; i++) {
    setBoth(40, 140, 200);
    setBoth(140, 40, 200);
  }
  // Mirror wave: arms swap places smoothly.
  for (int a = 30; a <= 150; a += 2) setBoth(a, a, 15);
  for (int a = 150; a >= 30; a -= 2) setBoth(a, a, 15);
  setBoth(90, 90, 1000);
}
